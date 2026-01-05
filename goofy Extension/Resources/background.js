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

// Auto-inject remote script when messenger.com loads
chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && isMessengerUrl(tab.url)) {
    try {
      // Check if script is already injected to avoid duplicates
      const isInjected = await chrome.scripting.executeScript({
        target: { tabId: tabId },
        world: "MAIN",
        func: () => {
          return !!window.__GOOFY;
        }
      });
      
      if (isInjected[0].result) {
        return;
      }
      
      const remoteScriptUrl = 'https://buechele.cc/content.js';
      
      // Add cache-busting parameter
      const cacheBustUrl = `${remoteScriptUrl}?t=${Date.now()}`;
      
      const response = await fetch(cacheBustUrl, {
        cache: 'no-cache',
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache'
        }
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const scriptText = await response.text();
      
      await chrome.scripting.executeScript({
        target: { tabId: tabId },
        world: "MAIN",
        func: (code) => {
          try {
            const blob = new Blob([code], {
              type: "application/javascript",
            });
            const url = URL.createObjectURL(blob);

            const script = document.createElement("script");
            script.src = url;
            script.onload = () => {
              URL.revokeObjectURL(url);
            };
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
    } catch (error) {
      console.error("Failed to fetch or inject remote script:", error);
    }
  }
});
