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

// Load version number
function loadVersion() {
  const manifest = chrome.runtime.getManifest();
  document.getElementById("extension-version").textContent = manifest.version;
}

// Open external URLs via buttons with data-url attribute
function setupExternalLinks() {
  document.addEventListener("click", (e) => {
    const button = e.target.closest("[data-url]");
    if (!button) return;

    const url = button.getAttribute("data-url");
    if (url) {
      // Send to background script to open in default browser via native messaging
      chrome.runtime.sendMessage({ action: "openInBrowser", url });
    }
  });
}

// Initialize on DOM load
document.addEventListener("DOMContentLoaded", async () => {
  const manager = new HealthCheckManager();

  // Load version
  loadVersion();

  // Setup external link handling
  setupExternalLinks();

  // Update check display immediately
  await manager.updateCheckDisplay();

  // Re-update display every 3 seconds
  setInterval(() => {
    manager.updateCheckDisplay();
  }, 3000);
});
