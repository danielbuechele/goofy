import Cocoa
import WebKit

@MainActor
final class RecoveryProbeWebView: WKWebView {
    var requests = 0
    override func reload() -> WKNavigation? {
        requests += 1
        return nil
    }
    override func load(_ request: URLRequest) -> WKNavigation? {
        requests += 1
        return nil
    }
}

@MainActor
final class SmokeTest: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var loadingView: MessengerLoadingView!
    private var badges: [Int] = []
    private var notifications = 0
    private var readThreads: [String] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(WeakScriptMessageHandler(self), contentWorld: .defaultClient, name: "goofy")
        let scriptPath: String
        if let index = CommandLine.arguments.firstIndex(of: "--script"), index + 1 < CommandLine.arguments.count {
            scriptPath = CommandLine.arguments[index + 1]
        } else {
            scriptPath = "goofy/content.js"
        }
        let script = try! String(contentsOfFile: scriptPath, encoding: .utf8)
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd,
                                                               forMainFrameOnly: true, in: .defaultClient))
        webView = RecoveryProbeWebView(frame: NSRect(x: 0, y: 0, width: 700, height: 600), configuration: config)
        webView.navigationDelegate = self
        window = NSWindow(contentRect: webView.frame, styleMask: [.titled, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Goofy WebKit regression test"
        window.contentView = webView
        loadingView = MessengerLoadingView(frame: webView.bounds)
        loadingView.autoresizingMask = [.width, .height]
        webView.addSubview(loadingView)
        precondition(!loadingView.isHidden)
        window.makeKeyAndOrderFront(nil)
        let unrelatedNavigation = CommandLine.arguments.contains("--startup-benchmark")
            ? "" : "<nav role=\"navigation\"><a href=\"/\">Home</a></nav>"
        webView.loadHTMLString("""
        \(unrelatedNavigation)
        <template id="inbox"><nav role="navigation"><div role="tablist"><button role="tab" aria-selected="true">Inbox</button></div>
        <div role="grid"><div role="row"><a href="/messages/t/1"><span class="xlyipyv">Test</span>
        <div class="xi81zsa"><span id="snippet">old</span></div>
        <div role="button"><span id="dot" class="x1spa7qu"></span></div></a></div></div></nav></template>
        <script>
        setTimeout(() => {
            document.body.append(document.getElementById('inbox').content.cloneNode(true));
            window.inboxInsertedAt = performance.now();
        }, 150);
        </script>
        """, baseURL: URL(string: "https://www.facebook.com/messages/"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 40) { self.finish(false, "Timed out") }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }
        if body["type"] as? String == "ready" {
            loadingView.isHidden = true
            if CommandLine.arguments.contains("--startup-benchmark") {
                webView.evaluateJavaScript("performance.now() - window.inboxInsertedAt") { value, error in
                    guard let delay = value as? Double, error == nil else {
                        return self.finish(false, "Startup timing unavailable")
                    }
                    self.finish(true, String(format: "Inbox insertion to ready: %.1f ms", delay))
                }
            }
        }
        if body["type"] as? String == "badge", let count = body["count"] as? Int { badges.append(count) }
        if body["type"] as? String == "notification" { notifications += 1 }
        if let keys = body["threadKeys"] as? [String] { readThreads.append(contentsOf: keys) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !CommandLine.arguments.contains("--startup-benchmark") else { return }
        Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(900))
                guard badges.last == 1, loadingView.isHidden else {
                    return finish(false, "Inbox exists but readiness was not detected within 900 ms")
                }
                loadingView.isHidden = false
                _ = try await webView.evaluateJavaScript("window.dispatchEvent(new PageTransitionEvent('pageshow', {persisted: true}))")
                try await Task.sleep(for: .milliseconds(150))
                guard loadingView.isHidden else { return finish(false, "Loading overlay after history restoration") }
                _ = try await webView.evaluateJavaScript("document.getElementById('dot').className = ''")
                try await Task.sleep(for: .milliseconds(250))
                guard badges.last == 0, readThreads.contains("/messages/t/1") else {
                    return finish(false, "Attribute-only read transition")
                }
                _ = try await webView.evaluateJavaScript("document.getElementById('snippet').textContent = 'new'; document.getElementById('dot').className = 'x1spa7qu'")
                try await Task.sleep(for: .milliseconds(250))
                guard notifications == 1, badges.last == 1 else { return finish(false, "New message detection") }
                _ = try await webView.evaluateJavaScript("""
                    const oldSidebar = document.querySelector('[role="navigation"]:has([role="grid"])');
                    const replacement = document.createElement('nav');
                    replacement.setAttribute('role', 'navigation');
                    document.body.append(replacement);
                    while (oldSidebar.firstChild) replacement.append(oldSidebar.firstChild);
                    """)
                try await Task.sleep(for: .milliseconds(250))
                _ = try await webView.evaluateJavaScript("document.getElementById('dot').className = ''")
                try await Task.sleep(for: .milliseconds(250))
                guard badges.last == 0 else { return finish(false, "Unread changes after moving the sidebar grid") }
                guard notifications == 1 else { return finish(false, "Duplicate notification after moving sidebar") }
                for _ in 0..<6 {
                    window.miniaturize(nil)
                    try await Task.sleep(for: .milliseconds(200))
                    window.deminiaturize(nil)
                    try await Task.sleep(for: .milliseconds(200))
                    let result = try await webView.evaluateJavaScript("1 + 1")
                    guard result as? Int == 2 else { return finish(false, "WebKit after minimization") }
                }
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                try await Task.sleep(for: .milliseconds(200))
                _ = try await webView.evaluateJavaScript(
                    "const originalIsReady = window.__GOOFY.isReady; window.__GOOFY.isReady = () => false; true;",
                    in: nil, contentWorld: .defaultClient)
                let safety = WebViewRecovery(webView: webView)
                var readinessFeedback: String?
                safety.onFailure = { readinessFeedback = $0 }
                safety.checkHealth()
                try await Task.sleep(for: .milliseconds(1300))
                guard readinessFeedback?.contains("Retry") == true,
                      (webView as! RecoveryProbeWebView).requests == 0 else {
                    return finish(false, "Responsive unfamiliar page must not be reloaded automatically")
                }
                safety.suspend()
                _ = try await webView.evaluateJavaScript("window.__GOOFY.isReady = originalIsReady; true;", in: nil, contentWorld: .defaultClient)
                let stalledView = webView as! RecoveryProbeWebView
                _ = try await webView.evaluateJavaScript("""
                    setTimeout(() => {
                        const deadline = performance.now() + 12000;
                        while (performance.now() < deadline) {}
                    }, 0);
                    true;
                    """, in: nil, contentWorld: .defaultClient)
                let stalledRecovery = WebViewRecovery(webView: webView)
                var stalledFeedback: String?
                stalledRecovery.onFailure = { stalledFeedback = $0 }
                stalledRecovery.checkHealth()
                try await Task.sleep(for: .milliseconds(11400))
                guard stalledFeedback?.contains("Retry") == true, stalledView.requests == 0 else {
                    return finish(false, "Unresponsive page must offer Retry without discarding drafts automatically")
                }
                stalledRecovery.suspend()
                try await Task.sleep(for: .milliseconds(1000))
                let probe = RecoveryProbeWebView(frame: .zero, configuration: WKWebViewConfiguration())
                let recovery = WebViewRecovery(webView: probe)
                var status: String?
                recovery.onFailure = { status = $0 }
                recovery.suspend()
                recovery.recover(reason: "Authentication pending")
                try await Task.sleep(for: .milliseconds(1200))
                guard probe.requests == 0 else { return finish(false, "Recovery during authentication") }
                recovery.resume()
                for delay in [1200, 2200, 4200] {
                    recovery.navigationFailed(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))
                    try await Task.sleep(for: .milliseconds(delay))
                }
                guard probe.requests == 3 else { return finish(false, "Three bounded recovery attempts") }
                recovery.recover(reason: "Still failing")
                guard status?.contains("Use Retry") == true else { return finish(false, "Recovery exhaustion feedback") }
                recovery.retryManually()
                guard probe.requests == 4 else { return finish(false, "Manual retry resets budget") }
                recovery.recover(reason: "Another failure")
                recovery.suspend()
                try await Task.sleep(for: .milliseconds(1200))
                guard probe.requests == 4 else { return finish(false, "Sign-in cancels scheduled retry") }
                finish(true, "WebKit: DOM read/unread/new message, 6 minimize cycles, recovery limits, authentication suspension and manual retry passed")
            } catch { finish(false, error.localizedDescription) }
        }
    }

    private func finish(_ success: Bool, _ message: String) {
        print(message)
        exit(success ? 0 : 1)
    }
}

@main
struct WebKitSmokeTests {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = SmokeTest()
        app.delegate = delegate
        app.run()
        withExtendedLifetime(delegate) {}
    }
}
