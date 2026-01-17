// State
let pwaTabId = null;

// Send status to the native Goofy Setup app via native messaging
// This writes to shared UserDefaults via SafariWebExtensionHandler
async function sendStatusToApp() {
  if (!pwaTabId) return;
  try {
    const results = await runChecksForTab(pwaTabId);
    await browser.runtime.sendNativeMessage("cc.buechele.Goofy", {
      type: "status",
      checks: {
        domain: results.domain,
        script: results.script,
        observerInbox: results["observer-inbox"],
        observerThreadlist: results["observer-threadlist"],
      },
    });
  } catch {
    // Native messaging not available
  }
}

// Periodically send status to the app (every 2 seconds when messenger is open)
async function sendPeriodicStatus() {
  // Only send status if we have a tracked PWA tab
  if (pwaTabId) {
    try {
      await chrome.tabs.get(pwaTabId);
      sendStatusToApp();
    } catch {
      // Tab no longer exists, stop sending status
      pwaTabId = null;
    }
  }
}

// Start periodic status updates
setInterval(sendPeriodicStatus, 2000);

// Helper function to check if URL is a messenger.com page
const isMessengerUrl = (url) => {
  if (!url) return false;
  try {
    const urlObj = new URL(url);
    return (
      urlObj.hostname === "messenger.com" ||
      urlObj.hostname.endsWith(".messenger.com")
    );
  } catch {
    return false;
  }
};

// Check if running in PWA/Web App mode
async function isPWAMode(tabId) {
  try {
    const result = await chrome.scripting.executeScript({
      target: { tabId },
      world: "MAIN",
      func: () => navigator.standalone === true,
    });
    return result[0].result;
  } catch {
    return false;
  }
}

// Health checks
const CHECKS = {
  domain: async (tabId, tab) => {
    return isMessengerUrl(tab.url) ? "pass" : "fail";
  },
  script: async (tabId) => {
    try {
      const result = await chrome.scripting.executeScript({
        target: { tabId },
        world: "MAIN",
        func: () => typeof window.__GOOFY !== "undefined",
      });
      return result[0].result ? "pass" : "fail";
    } catch {
      return "fail";
    }
  },
  pwa: async (tabId) => {
    return (await isPWAMode(tabId)) ? "pass" : "fail";
  },
  notifications: async (tabId) => {
    try {
      const result = await chrome.scripting.executeScript({
        target: { tabId },
        world: "MAIN",
        func: () => {
          if (!("Notification" in window)) {
            return "unsupported";
          }
          return Notification.permission;
        },
      });
      const permission = result[0].result;
      if (permission === "granted") return "pass";
      if (permission === "default" || permission === "prompt") return "warning";
      return "fail";
    } catch {
      return "fail";
    }
  },
  "observer-inbox": async (tabId) => {
    try {
      const result = await chrome.scripting.executeScript({
        target: { tabId },
        world: "MAIN",
        func: () => {
          if (
            typeof window.__GOOFY === "undefined" ||
            !window.__GOOFY.getObserverStatus
          ) {
            return null;
          }
          return window.__GOOFY.getObserverStatus().inbox || null;
        },
      });
      const status = result[0].result;
      if (!status) return "fail";
      if (status.active) return "pass";
      if (status.retrying) return "warning";
      return "fail";
    } catch {
      return "fail";
    }
  },
  "observer-threadlist": async (tabId) => {
    try {
      const result = await chrome.scripting.executeScript({
        target: { tabId },
        world: "MAIN",
        func: () => {
          if (
            typeof window.__GOOFY === "undefined" ||
            !window.__GOOFY.getObserverStatus
          ) {
            return null;
          }
          return window.__GOOFY.getObserverStatus().threadList || null;
        },
      });
      const status = result[0].result;
      if (!status) return "fail";
      if (status.active) return "pass";
      if (status.retrying) return "warning";
      return "fail";
    } catch {
      return "fail";
    }
  },
};

// Run all checks for a tab and return results
async function runChecksForTab(tabId) {
  const results = {};
  try {
    const tab = await chrome.tabs.get(tabId);
    // Only run checks on messenger.com tabs
    if (!isMessengerUrl(tab.url)) {
      for (const checkId of Object.keys(CHECKS)) {
        results[checkId] = "fail";
      }
      return results;
    }
    for (const [checkId, check] of Object.entries(CHECKS)) {
      results[checkId] = await check(tabId, tab);
    }
  } catch (error) {
    console.error("Health check error:", error);
    for (const checkId of Object.keys(CHECKS)) {
      results[checkId] = "fail";
    }
  }
  return results;
}

// Run checks and update badge (for PWA mode)
async function runChecksAndUpdateBadge() {
  if (!pwaTabId) return;

  try {
    await chrome.tabs.get(pwaTabId);
  } catch {
    stopPeriodicChecks();
    return;
  }

  const checkResults = await runChecksForTab(pwaTabId);

  const failCount = Object.values(checkResults).filter(
    (r) => r === "fail",
  ).length;

  if (failCount > 0) {
    await chrome.action.setBadgeText({
      text: failCount.toString(),
      tabId: pwaTabId,
    });
    await chrome.action.setBadgeBackgroundColor({
      color: "#ff3b30",
      tabId: pwaTabId,
    });
  } else {
    await chrome.action.setBadgeText({ text: "", tabId: pwaTabId });
  }
}

// Start periodic checks using alarms (survives service worker suspension)
async function startPeriodicChecks(tabId) {
  pwaTabId = tabId;
  await runChecksAndUpdateBadge();
  // Safari requires minimum 1 minute for alarms
  await chrome.alarms.create("healthCheck", { periodInMinutes: 1 });
}

// Stop periodic checks
async function stopPeriodicChecks() {
  await chrome.alarms.clear("healthCheck");
  await chrome.action.setBadgeText({ text: "" });
  pwaTabId = null;
  console.log("PWA mode: periodic health checks stopped");
}

// Alarm handler
chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === "healthCheck") {
    await runChecksAndUpdateBadge();
  }
});

// Handle tab close - stop checks if PWA tab closes
chrome.tabs.onRemoved.addListener((tabId) => {
  if (tabId === pwaTabId) {
    stopPeriodicChecks();
  }
});

// Handle messenger.com page loads
chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete" && isMessengerUrl(tab.url)) {
    // Check if running in PWA mode
    const isPWA = await isPWAMode(tabId);

    // Only send status and track for PWA mode
    // We don't want regular Safari tabs to trigger the "wrong browser" warning
    if (!isPWA) {
      return;
    }

    // Send status to native app
    sendStatusToApp();

    // Start periodic health checks for PWA mode
    // Content script is automatically injected via manifest
    if (!pwaTabId) {
      await startPeriodicChecks(tabId);
    }
  }
});

// Check for PWA tabs on extension startup (handles case where extension is enabled after page load)
async function checkExistingTabs() {
  const tabs = await chrome.tabs.query({});
  for (const tab of tabs) {
    if (isMessengerUrl(tab.url)) {
      const isPWA = await isPWAMode(tab.id);
      if (isPWA) {
        sendStatusToApp();
        if (!pwaTabId) {
          await startPeriodicChecks(tab.id);
        }
        break;
      }
    }
  }
}

// Handle toolbar icon click - open the main Goofy app
chrome.action.onClicked.addListener(() => {
  console.log("Toolbar icon clicked");
  browser.runtime.sendNativeMessage("cc.buechele.Goofy", {
    type: "openApp",
  });
});

// Run on extension startup
checkExistingTabs();
