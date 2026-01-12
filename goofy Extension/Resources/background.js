// State
let pwaTabId = null;
let checkResults = {};

// Send status to the native Goofy Setup app via native messaging
// This writes to shared UserDefaults via SafariWebExtensionHandler
async function sendStatusToApp(isPWA) {
  try {
    await browser.runtime.sendNativeMessage("cc.buechele.Goofy", {
      type: "status",
      isPWA: isPWA,
    });
  } catch {
    // Native messaging not available
  }
}

// Periodically send status to the app (every 2 seconds when messenger is open)
async function sendPeriodicStatus() {
  let isPWA = false;

  try {
    const tabs = await chrome.tabs.query({});
    for (const tab of tabs) {
      if (isMessengerUrl(tab.url)) {
        const tabIsPWA = await isPWAMode(tab.id);
        if (tabIsPWA) {
          isPWA = true;
          break;
        }
      }
    }
  } catch {
    // Error checking tabs
  }

  // Always send status if we have a messenger tab open
  sendStatusToApp(isPWA);
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

  checkResults = await runChecksForTab(pwaTabId);

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
  checkResults = {};
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

// Message handler for popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "getCheckResults") {
    // Return cached results (for PWA mode) or empty
    sendResponse({ results: checkResults });
  } else if (request.action === "runHealthChecks") {
    // Run fresh checks for the requested tab
    runChecksForTab(request.tabId).then((results) => {
      sendResponse({ results });
    });
    return true; // async response
  }
  return true;
});

// Auto-inject remote script when messenger.com loads in PWA mode
chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status === "complete" && isMessengerUrl(tab.url)) {
    try {
      // Check if running in PWA mode
      const isPWA = await isPWAMode(tabId);

      // Send status to native app (works for both PWA and regular Safari)
      sendStatusToApp(isPWA);

      if (!isPWA) {
        console.log("Not in PWA mode, skipping injection");
        return;
      }

      // Check if script is already injected to avoid duplicates
      const isInjected = await chrome.scripting.executeScript({
        target: { tabId },
        world: "MAIN",
        func: () => !!window.__GOOFY,
      });

      if (!isInjected[0].result) {
        // Inject the remote script
        const isDev = chrome.runtime.getManifest().version === "0.0";
        const remoteScriptUrl = isDev
          ? "http://localhost:8080/content.js"
          : "https://raw.githubusercontent.com/danielbuechele/goofy/refs/heads/main/content.js";
        const cacheBustUrl = `${remoteScriptUrl}?t=${Date.now()}`;

        const response = await fetch(cacheBustUrl, {
          cache: "no-cache",
          headers: {
            "Cache-Control": "no-cache",
            Pragma: "no-cache",
          },
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const scriptText = await response.text();

        await chrome.scripting.executeScript({
          target: { tabId },
          world: "MAIN",
          func: (code) => {
            try {
              const blob = new Blob([code], { type: "application/javascript" });
              const url = URL.createObjectURL(blob);
              const script = document.createElement("script");
              script.src = url;
              script.onload = () => URL.revokeObjectURL(url);
              script.onerror = (e) => {
                URL.revokeObjectURL(url);
                console.error("Remote script execution error:", e);
              };
              document.head.appendChild(script);
            } catch (e) {
              console.error("Blob script injection error:", e);
            }
          },
          args: [scriptText],
        });
      }

      // Wait for script to initialize, then start periodic checks
      setTimeout(async () => {
        if (!pwaTabId) {
          await startPeriodicChecks(tabId);
        }
      }, 1000);
    } catch (error) {
      console.error("Failed to fetch or inject remote script:", error);
    }
  }
});
