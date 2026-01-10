// Health check status types
const CheckStatus = {
  PENDING: "pending",
  PASS: "pass",
  WARNING: "warning",
  FAIL: "fail",
};

class HealthCheckManager {
  constructor() {
    this.activeTab = null;
  }

  // Discover checks from HTML
  discoverChecks() {
    const checkElements = document.querySelectorAll(".check-item[id]");
    const discovered = [];

    for (const element of checkElements) {
      discovered.push({
        id: element.id,
        element: element,
      });
    }

    return discovered;
  }

  // Get check results from background script
  async updateCheckDisplay() {
    const checks = this.discoverChecks();

    try {
      // Get active tab first
      const [tab] = await chrome.tabs.query({
        active: true,
        currentWindow: true,
      });
      this.activeTab = tab;

      // If no active tab, mark all as failed
      if (!this.activeTab) {
        for (const check of checks) {
          this.updateCheckStatus(check.element, CheckStatus.FAIL);
        }
        return;
      }

      // Run fresh checks via background script
      const response = await chrome.runtime.sendMessage({
        action: "runHealthChecks",
        tabId: this.activeTab.id,
      });

      const results = response.results || {};

      // Update UI with results
      for (const check of checks) {
        const status = results[check.id];
        if (status) {
          this.updateCheckStatus(check.element, status);
        } else {
          this.updateCheckStatus(check.element, CheckStatus.PENDING);
        }
      }
    } catch (error) {
      console.error("Error updating check display:", error);
      // Mark all as failed on error
      for (const check of checks) {
        this.updateCheckStatus(check.element, CheckStatus.FAIL);
      }
    }
  }

  // Helper: Update check status in UI
  updateCheckStatus(checkElement, status) {
    if (checkElement) {
      const statusIndicator = checkElement.querySelector(".check-status");
      if (statusIndicator) {
        statusIndicator.setAttribute("data-status", status);
      }
    }
  }
}

// Load version numbers
async function loadVersions() {
  // Get extension version from manifest
  const manifest = chrome.runtime.getManifest();
  const extensionVersion = manifest.version;
  document.getElementById("extension-version").textContent = extensionVersion;

  // Get content script version from __GOOFY
  try {
    const [tab] = await chrome.tabs.query({
      active: true,
      currentWindow: true,
    });

    if (tab) {
      const result = await chrome.scripting.executeScript({
        target: { tabId: tab.id },
        world: "MAIN",
        func: () => {
          if (typeof window.__GOOFY !== "undefined" && window.__GOOFY.version) {
            return window.__GOOFY.version;
          }
          return null;
        },
      });

      const contentVersion = result[0].result;
      if (contentVersion) {
        document.getElementById("content-version").textContent = contentVersion;
      }
    }
  } catch (error) {
    console.error("Error loading content version:", error);
  }
}

// Initialize on DOM load
document.addEventListener("DOMContentLoaded", async () => {
  const manager = new HealthCheckManager();

  // Load versions
  loadVersions();

  // Update check display immediately
  await manager.updateCheckDisplay();

  // Re-update display every 3 seconds
  setInterval(() => {
    manager.updateCheckDisplay();
  }, 3000);
});
