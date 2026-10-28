//
//  SafariLoginController.swift
//  goofy
//
//  Handles Facebook login via a dedicated login window with a permissive WKWebView.
//  This avoids 2FA issues by using a clean WebView that allows all Facebook URLs
//  and handles popups in-app. Shares the same WKWebsiteDataStore so cookies
//  transfer automatically to the main WebView.
//

import Cocoa
import WebKit

class SafariLoginController: NSObject, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {

    private var loginWindow: NSWindow?
    private var loginWebView: WKWebView?
    private var onComplete: ((Bool) -> Void)?

    /// Opens a dedicated login window pointing to Facebook login.
    /// After successful authentication (detected by navigating to /messages),
    /// the window closes and `completion` is called so the main WebView can reload.
    func startLogin(completion: @escaping (Bool) -> Void) {
        onComplete = completion

        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Use the same Safari user agent
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString =
            "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionString)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.title = "Login to Facebook"
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.loginWindow = window
        self.loginWebView = webView

        // Load Facebook login page
        if let url = URL(string: "https://www.facebook.com/login") {
            webView.load(URLRequest(url: url))
        }
    }

    // MARK: - WKNavigationDelegate

    /// Allow ALL facebook.com and messenger.com URLs during login (no filtering)
    func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url, let host = url.host else {
            decisionHandler(.allow)
            return
        }

        // Allow all Facebook/Messenger URLs during login
        if FacebookURL.isTrustedHost(host, domain: "facebook.com") || FacebookURL.isTrustedHost(host, domain: "messenger.com") ||
           FacebookURL.isTrustedHost(host, domain: "fbcdn.net") || FacebookURL.isTrustedHost(host, domain: "fbsbx.com") ||
           FacebookURL.isTrustedHost(host, domain: "accountkit.com") {
            decisionHandler(.allow)
            return
        }

        // Open non-Facebook URLs externally
        if navigationAction.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        let path = url.path.lowercased()
        let host = url.host ?? ""

        print("[SafariLogin] Page loaded: \(url.absoluteString)")

        // Skip auth pages - login is still in progress
        let authPaths = ["/login", "/checkpoint", "/two_step_verification", "/recover",
                         "/cookie/consent", "/dialog", "/v2/dialog", "/auth"]
        if FacebookURL.isTrustedHost(host, domain: "facebook.com") && authPaths.contains(where: { path.hasPrefix($0) }) {
            return
        }

        // After login, Facebook redirects to / or /messages or messenger.com
        // Check cookies to confirm the user is actually authenticated
        if FacebookURL.isTrustedHost(host, domain: "facebook.com") || FacebookURL.isTrustedHost(host, domain: "messenger.com") {
            checkAuthCookies { [weak self] isAuthenticated in
                guard isAuthenticated else { return }
                print("[SafariLogin] Login successful (authenticated cookie found), closing login window")
                self?.completeLogin(success: true)
            }
        }
    }

    private func checkAuthCookies(completion: @escaping (Bool) -> Void) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            // Facebook sets c_user cookie when authenticated
            let hasAuthCookie = cookies.contains { cookie in
                FacebookURL.isTrustedHost(cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")), domain: "facebook.com") && cookie.name == "c_user"
            }
            DispatchQueue.main.async {
                completion(hasAuthCookie)
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        completeLogin(success: false)
    }

    private func completeLogin(success: Bool) {
        guard let completion = onComplete else { return }
        onComplete = nil
        loginWindow?.close()
        loginWindow = nil
        loginWebView = nil
        completion(success)
    }

    // MARK: - WKUIDelegate

    /// Handle popups during login (2FA verification dialogs, etc.)
    func webView(
        _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // For auth popups, load in the same webview
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    func webView(
        _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    func webView(
        _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        completionHandler(alert.runModal() == .alertFirstButtonReturn)
    }
}
