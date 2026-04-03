window.__GOOFY = {
  ALT_TEXT_TO_EMOJI: {
    "(Y)": "👍",
    "❤": "❤️",
  },

  IGNORED_SNIPPET_PREFIXES: ["You sent an attachment.", "You: "],

  threadSnapshots: null,

  postToNative: function (message) {
    if (
      window.webkit &&
      window.webkit.messageHandlers &&
      window.webkit.messageHandlers.goofy
    ) {
      window.webkit.messageHandlers.goofy.postMessage(message);
    }
  },

  getTextWithImageAlts: function (element) {
    if (!element) return "";

    let result = "";
    for (const node of element.childNodes) {
      if (node.nodeType === Node.TEXT_NODE) {
        result += node.textContent;
      } else if (node.nodeType === Node.ELEMENT_NODE) {
        // Skip screen-reader-only elements (e.g. "Ungelesene Nachricht:")
        if (node.classList.contains("x1i1rx1s")) continue;
        if (node.tagName === "IMG") {
          const alt = node.alt || "";
          result += this.ALT_TEXT_TO_EMOJI[alt] || alt;
        } else {
          result += this.getTextWithImageAlts(node);
        }
      }
    }
    return result;
  },

  log: function (message) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${message}`;
    console.log(`[Goofy] ${logEntry}`);
    this.postToNative({ type: "log", message: logEntry });
  },

  // --- Reusable observer that re-attaches when the element is removed ---

  observe: function (selector, callback, options = {}) {
    const {
      subtree = true,
      childList = true,
      characterData = false,
      retryInterval = 3000,
      onSetup = null,
      onRemove = null,
    } = options;

    let contentObserver = null;
    let removalObserver = null;

    const setup = () => {
      const element = document.querySelector(selector);
      if (!element) {
        this.log(`observe(${selector}): not found, retrying`);
        setTimeout(setup, retryInterval);
        return;
      }

      this.log(`observe(${selector}): attached`);
      if (onSetup) onSetup(element);

      contentObserver?.disconnect();
      contentObserver = new MutationObserver(() => callback(element));
      contentObserver.observe(element, { subtree, childList, characterData });

      removalObserver?.disconnect();
      removalObserver = new MutationObserver(() => {
        if (!document.contains(element)) {
          this.log(`observe(${selector}): removed, re-attaching`);
          contentObserver?.disconnect();
          removalObserver?.disconnect();
          if (onRemove) onRemove();
          setup();
        }
      });
      removalObserver.observe(document.body, {
        childList: true,
        subtree: true,
      });
    };

    setup();
  },

  // --- Badge count ---

  updateBadgeCount: function () {
    const firstTab = document.querySelector('[role="tablist"] [role="tab"]');
    if (firstTab?.getAttribute("aria-selected") !== "true") return;

    const unreadDots = document.querySelectorAll(
      '[role="navigation"] [role="row"] [role="button"] .x1spa7qu',
    );
    this.postToNative({ type: "badge", count: unreadDots.length });
    this.log(`Badge count: ${unreadDots.length}`);
  },

  // --- New message detection ---

  checkForNewMessages: function () {
    const threads = Array.from(
      document.querySelectorAll('[role="navigation"] [role="row"] a'),
    )
      .map((a, index) => ({
        threadKey: a.getAttribute("href"),
        threadName: a.querySelector("span.xlyipyv")?.textContent,
        snippet: this.getTextWithImageAlts(
          a.querySelector("div.xi81zsa span"),
        ),
        isUnread: !!a.querySelector('[role="button"] .x1spa7qu'),
        position: index,
      }))
      .filter((t) => Boolean(t.threadKey));

    let firstRun = false;
    if (threads.length > 0 && this.threadSnapshots == null) {
      this.threadSnapshots = new Map();
      firstRun = true;
    }

    threads.forEach((thread) => {
      const prev = this.threadSnapshots.get(thread.threadKey);
      this.threadSnapshots.set(thread.threadKey, thread);

      if (!thread.isUnread) return;

      let shouldNotify = false;

      if (prev) {
        if (!prev.isUnread) {
          shouldNotify = true;
        } else if (thread.snippet !== prev.snippet) {
          shouldNotify = true;
        }
      } else {
        if (thread.position === 0 && !firstRun) {
          shouldNotify = true;
        }
      }

      if (shouldNotify) {
        const hasIgnoredPrefix = this.IGNORED_SNIPPET_PREFIXES.some(
          (prefix) => thread.snippet.startsWith(prefix),
        );
        if (hasIgnoredPrefix) return;

        this.postToNative({
          type: "notification",
          title: thread.threadName,
          body: thread.snippet,
          threadKey: thread.threadKey,
        });
      }
    });
  },

  // --- Actions called from Swift ---

  navigateToThread: function (threadKey) {
    const link = document.querySelector(`a[href="${threadKey}"]`);
    if (link) {
      link.click();
    } else {
      window.location.href = threadKey;
    }
  },

  newMessage: function () {
    const link = document.querySelector('a[href="/messages/new/"]');
    if (link) {
      link.click();
    } else {
      window.location.href = "/messages/new/";
    }
  },

  focusSearch: function () {
    const input = document.querySelector(
      '[role="navigation"] input[type="search"]',
    );
    if (input) {
      input.click();
      input.focus();
    }
  },

  // --- Init ---

  init: function () {
    this.log("Initializing Goofy");

    this.observe('[role="navigation"] [role="grid"]', () => {
      this.checkForNewMessages();
      this.updateBadgeCount();
    }, {
      onSetup: () => this.updateBadgeCount(),
      onRemove: () => { this.threadSnapshots = null; },
    });
  },
};

window.__GOOFY.init();
