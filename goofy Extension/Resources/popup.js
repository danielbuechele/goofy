document.addEventListener("DOMContentLoaded", function () {
  let badgeCount = 0;
  let badgeActive = false;

  const badgeBtn = document.getElementById("badgeBtn");
  const logsContainer = document.getElementById("logsContainer");

  // Helper function to check if URL is a messenger.com page
  const isMessengerUrl = (url) => {
    if (!url) return false;
    try {
      const urlObj = new URL(url);
      return urlObj.hostname === 'messenger.com' || urlObj.hostname.endsWith('.messenger.com');
    } catch {
      return false;
    }
  };

  // Function to load and display logs
  const loadLogs = async () => {
    try {
      const [activeTab] = await chrome.tabs.query({ active: true, currentWindow: true });
      
      if (!activeTab || !isMessengerUrl(activeTab.url)) {
        logsContainer.innerHTML = '<p class="no-logs">Please navigate to messenger.com</p>';
        return;
      }

      const result = await chrome.scripting.executeScript({
        target: { tabId: activeTab.id },
        world: "MAIN",
        func: () => {
          if (window.__GOOFY && window.__GOOFY.logs) {
            return window.__GOOFY.logs;
          }
          return null;
        },
      });

      const logs = result[0].result;
      
      if (!logs || logs.length === 0) {
        logsContainer.innerHTML = '<p class="no-logs">No logs available</p>';
        return;
      }

      // Show last 10 logs, newest first
      const recentLogs = logs.slice(-10).reverse();
      const logsHtml = recentLogs.map(log => 
        `<div class="log-entry">${escapeHtml(log)}</div>`
      ).join('');
      
      logsContainer.innerHTML = logsHtml;
      
    } catch (error) {
      console.error("Error loading logs:", error);
      logsContainer.innerHTML = '<p class="no-logs">Error loading logs</p>';
    }
  };

  // Helper function to escape HTML
  const escapeHtml = (text) => {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  };

  // Function to check if running in standalone mode
  const checkStandaloneMode = async () => {
    try {
      const [activeTab] = await chrome.tabs.query({ active: true, currentWindow: true });
      
      if (!activeTab || !isMessengerUrl(activeTab.url)) {
        showNonStandaloneMessage("Please navigate to messenger.com first");
        return;
      }

      const result = await chrome.scripting.executeScript({
        target: { tabId: activeTab.id },
        world: "MAIN",
        func: () => {
          return navigator.standalone;
        },
      });

      const isStandalone = result[0].result;
      
      if (!isStandalone) {
        showNonStandaloneMessage();
        return;
      }

      // If we're here, we're in standalone mode - show normal UI
      showStandaloneUI();
      loadLogs();
      
    } catch (error) {
      console.error("Error checking standalone mode:", error);
      showNonStandaloneMessage("Error checking app mode");
    }
  };

  const showNonStandaloneMessage = (customMessage) => {
    const message = customMessage || "This extension is designed to work with the Messenger web app installed as a Dock app.";
    document.querySelector('.container').innerHTML = `
      <h2>Goofy Extension</h2>
      <div class="standalone-message">
        <p>${message}</p>
        ${!customMessage ? `
          <div class="instructions">
            <p><strong>To install the Messenger app:</strong></p>
            <ol>
              <li>Open messenger.com in Safari</li>
              <li>Go to <strong>File → Add to Dock...</strong></li>
              <li>Click "Add" to create the Dock app</li>
              <li>Open Messenger from your Dock</li>
            </ol>
          </div>
        ` : ''}
      </div>
    `;
  };

  const showStandaloneUI = () => {
    // UI is already set up in HTML, just make sure it's visible
    badgeBtn.style.display = 'block';
    document.querySelector('.logs-section').style.display = 'block';
  };

  // Check standalone mode when popup opens
  checkStandaloneMode();

  // Badge functionality via remote script's window.__GOOFY.updateBadgeCount
  badgeBtn.addEventListener("click", async function () {
    try {
      // Get the active tab (should be the PWA)
      const [activeTab] = await chrome.tabs.query({ active: true, currentWindow: true });
      
      if (!activeTab || !isMessengerUrl(activeTab.url)) {
        alert("Please navigate to messenger.com");
        return;
      }

      if (badgeActive) {
        // Clear badge
        await chrome.scripting.executeScript({
          target: { tabId: activeTab.id },
          world: "MAIN",
          func: () => {
            if (window.__GOOFY && window.__GOOFY.updateBadgeCount) {
              window.__GOOFY.updateBadgeCount(null);
            }
          },
        });
        badgeActive = false;
        badgeBtn.textContent = "Set Badge";
      } else {
        // Set badge
        badgeCount++;
        await chrome.scripting.executeScript({
          target: { tabId: activeTab.id },
          world: "MAIN",
          func: (count) => {
            if (window.__GOOFY && window.__GOOFY.updateBadgeCount) {
              window.__GOOFY.updateBadgeCount(count);
            }
          },
          args: [badgeCount],
        });
        badgeActive = true;
        badgeBtn.textContent = `Clear Badge (${badgeCount})`;
      }
    } catch (error) {
      console.error("Error calling remote script:", error);
      alert("Error: Make sure you are on messenger.com");
    }
  });

  // Initialize button state
  badgeBtn.textContent = "Set Badge";
});
