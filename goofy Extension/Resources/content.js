window.__GOOFY = {
  observers: new Map(),
  logs: [],
  threadSnapshots: null,
  initTime: null,
  lastActivityTime: null,
  RELOAD_INTERVAL: 4 * 60 * 60 * 1000, // 4 hours in ms
  IDLE_THRESHOLD: 5 * 60 * 1000, // 5 minutes in ms

  observe: function (
    name,
    selector,
    callback,
    runInitially = true,
    retryInterval = 3000,
  ) {
    this.log(`Setting up observer: ${name}`);

    const config = {
      name,
      selector,
      callback,
      runInitially,
      retryInterval,
    };

    const trySetup = () => {
      this.log(`Attempting to setup observer: ${name}`);

      this.cleanupObserver(name, true);

      let element = null;
      if (typeof selector === "function") {
        element = selector();
      } else if (typeof selector === "string") {
        element = document.querySelector(selector);
      } else if (selector instanceof Element) {
        element = selector;
      }

      if (element) {
        this.log(`Observer ${name}: Element found, setting up`);

        if (runInitially && callback) {
          callback.call(this);
        }

        const observer = new MutationObserver(() => {
          this.log(`Observer ${name}: Mutation detected`);
          if (callback) {
            callback.call(this);
          }
        });

        observer.observe(element, {
          attributes: true,
          childList: true,
          subtree: true,
          characterData: true,
        });

        const removalObserver = new MutationObserver((mutations) => {
          if (!document.contains(element)) {
            this.log(
              `Observer ${name}: Element was removed from DOM, will re-setup`,
            );

            this.cleanupObserver(name, true);

            this.observe(
              config.name,
              config.selector,
              config.callback,
              config.runInitially,
              config.retryInterval,
            );
          }
        });

        removalObserver.observe(document.body, {
          childList: true,
          subtree: true,
        });

        this.observers.set(name, {
          observer,
          removalObserver,
          element,
          config,
          retryTimer: null,
        });

        this.log(`Observer ${name}: Successfully set up`);
        return true;
      } else {
        this.log(
          `Observer ${name}: Element not found, will retry in ${retryInterval}ms`,
        );

        const retryTimer = setTimeout(() => trySetup(), retryInterval);

        this.observers.set(name, {
          observer: null,
          removalObserver: null,
          element: null,
          config,
          retryTimer,
        });

        return false;
      }
    };

    trySetup();
  },

  cleanupObserver: function (name, keepConfig = false) {
    const observerData = this.observers.get(name);
    if (observerData) {
      if (observerData.observer) {
        observerData.observer.disconnect();
        this.log(`Observer ${name}: Cleaned up`);
      }

      if (observerData.removalObserver) {
        observerData.removalObserver.disconnect();
        this.log(`Observer ${name}: Removal watcher cleaned up`);
      }

      if (observerData.retryTimer) {
        clearTimeout(observerData.retryTimer);
        this.log(`Observer ${name}: Retry timer cleared`);
      }

      if (!keepConfig) {
        this.observers.delete(name);
      } else {
        this.observers.set(name, {
          observer: null,
          removalObserver: null,
          element: null,
          config: observerData.config,
          retryTimer: null,
        });
      }
    }
  },

  getObserverStatus: function () {
    const status = {};
    for (const [name, data] of this.observers.entries()) {
      status[name] = {
        active: data.observer !== null,
        retrying: data.retryTimer !== null,
        hasRemovalWatcher: data.removalObserver !== null,
      };
    }
    return status;
  },

  updateBadgeCount: function () {
    const inboxCell = document.querySelector("#left-sidebar-button-chats");
    let count = 0;
    if (inboxCell) {
      const ariaLabel = inboxCell.getAttribute("aria-label");
      if (ariaLabel) {
        const numbersOnly = ariaLabel.replace(/\D/g, "");
        count = numbersOnly ? parseInt(numbersOnly, 10) : 0;
      }
    } else {
      this.log("Inbox cell not found while updating badge");
    }

    navigator.setAppBadge(count);
    this.log(`Badge count updated to ${count}`);

    // Also check if inbox active state changed (aria-current attribute)
    this.handleInboxChange();
  },

  checkForNewMessages: function () {
    threads = Array.from(
      document.querySelectorAll('[role="navigation"] [role="row"] a'),
    )
      .map((a, index) => ({
        threadKey: a.getAttribute("href"),
        threadName: a.querySelectorAll("span.xyejjpt")[0]?.textContent,
        snippet: a.querySelectorAll("span.xyejjpt")[1]?.textContent,
        isUnread: !!a.querySelector("span.x1spa7qu.x1iwo8zk"),
        isMuted: !!a.querySelector("svg.x14rh7hd"),
        position: index,
      }))
      .filter((t) => Boolean(t.threadKey));

    if (threads.length > 0 && this.threadSnapshots == null) {
      this.threadSnapshots = new Map();
    }

    threads.forEach((thread) => {
      const prev = this.threadSnapshots.get(thread.threadKey);
      this.threadSnapshots.set(thread.threadKey, thread);

      if (thread.isMuted || !thread.isUnread) {
        return;
      }

      let shouldNotify = false;

      if (prev) {
        // (a) Was read, now unread
        if (!prev.isUnread) {
          shouldNotify = true;
          this.log(`Thread ${thread.threadName} changed from read to unread`);
        }
        // (b) Snippet changed on unread thread
        else if (thread.snippet !== prev.snippet) {
          shouldNotify = true;
          this.log(`Snippet changed for unread thread ${thread.threadName}`);
        }
      } else {
        // (c) New unread thread inserted at top
        if (thread.position === 0) {
          shouldNotify = true;
          this.log(`New unread thread inserted at top: ${thread.threadName}`);
        }
      }

      if (shouldNotify) {
        this.showNotification(
          thread.threadName,
          thread.snippet,
          thread.threadKey,
        );
      }
    });
  },

  showNotification: function (title, body, threadKey) {
    this.log(`showNotification: ${title} - ${body}`);

    if (!("Notification" in window)) {
      this.log("Notifications not supported");
      return;
    }

    this.log(`Notification permission: ${Notification.permission}`);

    if (Notification.permission === "granted") {
      try {
        const notification = new Notification(title, {
          body: body,
          icon: "/favicon.ico",
        });

        notification.onclick = () => {
          window.focus();

          const threadLink = document.querySelector(`a[href="${threadKey}"]`);
          if (threadLink) {
            threadLink.click();
          } else {
            this.log(
              `Thread link not found for ${threadKey}, using hard navigation`,
            );
            window.location.href = threadKey;
          }

          notification.close();
        };

        this.log(`Notification created successfully`);
      } catch (error) {
        this.log(`Notification error: ${error.message}`);
      }
    } else if (Notification.permission !== "denied") {
      this.log(`Requesting notification permission`);
      Notification.requestPermission().then((permission) => {
        this.log(`Permission request result: ${permission}`);
        if (permission === "granted") {
          this.showNotification(title, body, threadKey);
        }
      });
    } else {
      this.log(`Notifications denied by user`);
    }
  },

  log: function (message) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${message}`;
    this.logs.push(logEntry);
    console.log(`[Goofy] ${logEntry}`);
  },

  setupThreadListObserver: function () {
    this.observe(
      "threadList",
      '[role="navigation"] [role="grid"]',
      this.checkForNewMessages,
      false,
    );
  },

  cleanupThreadListObserver: function () {
    this.cleanupObserver("threadList", false);
    this.threadSnapshots = null;
  },

  isInboxActive: function () {
    const inboxCell = document.querySelector("#left-sidebar-button-chats");
    return inboxCell?.getAttribute("aria-current") === "page";
  },

  handleInboxChange: function () {
    const inInbox = this.isInboxActive();
    const observerData = this.observers.get("threadList");
    const observerActive = observerData?.observer != null;

    this.log(
      `handleInboxChange: inInbox=${inInbox}, observerActive=${observerActive}`,
    );

    if (inInbox && !observerActive) {
      this.log("Inbox became active, setting up threadList observer");
      this.setupThreadListObserver();
    } else if (!inInbox && observerActive) {
      this.log("Inbox became inactive, cleaning up threadList observer");
      this.cleanupThreadListObserver();
    }
  },

  setupActivityTracking: function () {
    const resetActivity = () => {
      this.lastActivityTime = Date.now();
    };

    ["mousemove", "keydown", "click", "scroll", "touchstart"].forEach(
      (event) => {
        document.addEventListener(event, resetActivity, { passive: true });
      },
    );

    resetActivity();
  },

  isUserTyping: function () {
    const active = document.activeElement;
    if (!active) return false;
    const tag = active.tagName.toLowerCase();
    return tag === "input" || tag === "textarea" || active.isContentEditable;
  },

  checkForReload: function () {
    const now = Date.now();
    const timeSinceInit = now - this.initTime;
    const timeSinceActivity = now - this.lastActivityTime;

    const shouldReload =
      timeSinceInit >= this.RELOAD_INTERVAL &&
      timeSinceActivity >= this.IDLE_THRESHOLD &&
      !this.isUserTyping();

    if (shouldReload) {
      this.log("Performing scheduled reload after 12 hours");
      location.reload();
    }
  },

  init: function () {
    // Only initialize in PWA mode
    if (navigator.standalone !== true) {
      return;
    }

    this.log("Initializing Goofy");

    const setup = () => {
      this.observe(
        "inbox",
        "#left-sidebar-button-chats",
        this.updateBadgeCount,
        true,
      );
    };

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", setup);
    } else {
      setup();
    }
  },
};

window.__GOOFY.init();
