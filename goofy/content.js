window.__GOOFY = {
  ALT_TEXT_TO_EMOJI: {
    "(Y)": "👍",
    "❤": "❤️",
  },

  IGNORED_SNIPPET_PREFIXES: ["You sent an attachment.", "You: "],

  threadSnapshots: null,
  pageReady: false,
  lastBadgeCount: null,
  refreshPending: false,

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
    const { onSetup = null, onRemove = null } = options;
    let element = null;
    let contentObserver = null;

    const attach = () => {
      if (element && document.contains(element) && element.matches(selector)) return;
      if (element) {
        contentObserver.disconnect();
        if (onRemove) onRemove();
      }
      element = document.querySelector(selector);
      if (!element) return;

      contentObserver = new MutationObserver(() => callback(element));
      contentObserver.observe(element, {
        subtree: true, childList: true, characterData: true, attributes: true,
        attributeFilter: ["class", "aria-selected", "aria-label"],
      });
      if (onSetup) onSetup(element);
    };

    // Detect the first render and sidebar replacements immediately. Once attached,
    // mutations elsewhere only need a connectivity check, not another DOM scan.
    const lifecycleObserver = new MutationObserver(attach);
    lifecycleObserver.observe(document.body, { childList: true, subtree: true });
    attach();
  },

  // --- Badge count ---

  updateBadgeCount: function (count = null) {
    if (count === null) {
      const firstTab = document.querySelector('[role="tablist"] [role="tab"]');
      if (firstTab && firstTab.getAttribute("aria-selected") !== "true") return;
      count = document.querySelectorAll(
        '[role="navigation"] [role="row"] [role="button"] .x1spa7qu',
      ).length;
    }
    if (this.lastBadgeCount === count) return;
    this.lastBadgeCount = count;
    this.postToNative({ type: "badge", count });
    this.log(`Badge count: ${count}`);
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
        isMuted: !!a.querySelector('svg.x14rh7hd'),
        position: index,
      }))
      .filter((t) => Boolean(t.threadKey));

    let firstRun = false;
    if (threads.length > 0 && this.threadSnapshots == null) {
      this.threadSnapshots = new Map();
      firstRun = true;
    }

    const readThreadKeys = [];
    let unreadCount = 0;
    threads.forEach((thread) => {
      if (thread.isUnread) unreadCount += 1;
      const prev = this.threadSnapshots.get(thread.threadKey);
      this.threadSnapshots.set(thread.threadKey, thread);

      if (!thread.isUnread) {
        if (!prev || prev.isUnread) readThreadKeys.push(thread.threadKey);
        return;
      }
      if (thread.isMuted) return;

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
    if (readThreadKeys.length) {
      this.postToNative({ type: "read", threadKeys: readThreadKeys });
    }
    return unreadCount;
  },

  // --- Actions called from Swift ---

  navigateToThread: function (threadKey) {
    const url = new URL(threadKey, window.location.href);
    if (url.origin !== window.location.origin || !url.pathname.startsWith("/messages/")) return;
    const link = Array.from(document.querySelectorAll('a[href]'))
      .find(a => a.getAttribute("href") === threadKey);
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

  isReady: function () {
    return !!document.querySelector('[role="navigation"] [role="grid"]');
  },

  refresh: function () {
    if (!this.isReady()) return;
    if (!this.pageReady) {
      this.pageReady = true;
      this.postToNative({ type: "ready" });
    }
    const firstTab = document.querySelector('[role="tablist"] [role="tab"]');
    if (firstTab && firstTab.getAttribute("aria-selected") !== "true") return;
    const unreadCount = this.checkForNewMessages();
    this.updateBadgeCount(unreadCount);
  },

  scheduleRefresh: function () {
    if (this.refreshPending) return;
    this.refreshPending = true;
    setTimeout(() => {
      this.refreshPending = false;
      this.refresh();
    }, 100);
  },

  init: function () {
    this.log("Initializing Goofy");
    this.observe('[role="navigation"]:has([role="grid"])', () => this.scheduleRefresh(), {
      onSetup: () => this.refresh(),
      onRemove: () => { this.threadSnapshots = null; },
    });
    window.addEventListener("focus", () => this.scheduleRefresh());
    window.addEventListener("pageshow", (event) => {
      if (event.persisted) {
        this.pageReady = false;
        this.refresh();
      }
    });
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "visible") this.scheduleRefresh();
    });
  },
};

window.__GOOFY.init();
