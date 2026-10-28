//
//  ViewController.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AVFoundation
import Cocoa
import UserNotifications
import WebKit

class ViewController: NSViewController {

    private var webView: GoofyWebView!
    private let messageHandlerName = "goofy"

    // Zoom properties
    private static let zoomKey = "WebViewZoomLevel"
    private var zoomLevel: CGFloat {
        get {
            let stored = UserDefaults.standard.double(forKey: Self.zoomKey)
            return stored == 0 ? 1.0 : CGFloat(stored)
        }
        set {
            let clamped = min(max(newValue, 0.5), 3.0)
            UserDefaults.standard.set(Double(clamped), forKey: Self.zoomKey)
            webView.pageZoom = clamped
        }
    }

    private var recovery: WebViewRecovery?
    private var loadingView: MessengerLoadingView!
    private var errorBanner: NSStackView!
    private var errorLabel: NSTextField!
    private var windowConfigured = false
    private var isAuthenticated = false
    private var safariLoginController: SafariLoginController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNotifications()
        setupLoadingView()
        setupErrorBanner()
        updateBadge(count: 0)
        recovery = WebViewRecovery(webView: webView)
        recovery?.onFailure = { [weak self] message in self?.showLoadError(message) }
        recovery?.onContentAvailable = { [weak self] in self?.loadingView.isHidden = true }
        loadMessenger()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if !windowConfigured {
            configureWindow()
            windowConfigured = true
        }
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(
            forName: messageHandlerName, contentWorld: .defaultClient)
    }

    // MARK: - WebView Setup

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let userContentController = WKUserContentController()

        // Use .defaultClient world to isolate our code from the page's JS
        userContentController.add(WeakScriptMessageHandler(self), contentWorld: .defaultClient, name: messageHandlerName)

        // Inject style.css at document start (before page renders)
        if let cssURL = Bundle.main.url(forResource: "style", withExtension: "css"),
            let cssContent = try? String(contentsOf: cssURL, encoding: .utf8)
        {
            let escapedCSS = cssContent
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
            let cssScript = WKUserScript(
                source: """
                    (function() {
                        const style = document.createElement('style');
                        style.textContent = `\(escapedCSS)`;
                        (document.head || document.documentElement).appendChild(style);
                    })();
                    """,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true,
                in: .page
            )
            userContentController.addUserScript(cssScript)
        }

        // Inject content.js at document end
        if let scriptURL = Bundle.main.url(forResource: "content", withExtension: "js"),
            let scriptContent = try? String(contentsOf: scriptURL, encoding: .utf8)
        {
            let userScript = WKUserScript(
                source: scriptContent,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true,
                in: .defaultClient
            )
            userContentController.addUserScript(userScript)
        }

        configuration.userContentController = userContentController

        // Create WebView
        webView = GoofyWebView(frame: view.bounds, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self

        webView.underPageBackgroundColor = .windowBackgroundColor
        webView.allowsBackForwardNavigationGestures = true

        // Set custom user agent to appear as Safari
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString =
            "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionString)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        webView.pageZoom = zoomLevel

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureWindow() {
        guard let window = view.window else { return }

        // Set minimum window size
        window.minSize = NSSize(width: 400, height: 600)

        // On first launch, no saved frame exists — set default size
        if UserDefaults.standard.string(forKey: "NSWindow Frame MainWindow") == nil {
            window.setContentSize(NSSize(width: 1200, height: 800))
            window.center()
        }

        // Make window resizable
        window.styleMask.insert(.resizable)

        // Full-size content view with transparent titlebar for inset traffic lights
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // Add toolbar for inset traffic light style and window corner radius
        let toolbar = NSToolbar(identifier: "MainToolbar")
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        // Set background color for window and titlebar
        window.backgroundColor = .windowBackgroundColor
    }

    private func loadMessenger() {
        guard let url = URL(string: "https://www.facebook.com/messages/") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - Loading feedback

    private func setupLoadingView() {
        loadingView = MessengerLoadingView(frame: .zero)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupErrorBanner() {
        errorLabel = NSTextField(wrappingLabelWithString: "")
        let retryButton = NSButton(title: "Retry", target: self, action: #selector(retryLoading))
        errorBanner = NSStackView(views: [errorLabel, retryButton])
        errorBanner.orientation = .horizontal
        errorBanner.spacing = 12
        errorBanner.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        errorBanner.wantsLayer = true
        errorBanner.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        errorBanner.translatesAutoresizingMaskIntoConstraints = false
        errorBanner.isHidden = true
        view.addSubview(errorBanner)
        NSLayoutConstraint.activate([
            errorBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            errorBanner.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
    }

    private func showLoadError(_ message: String?) {
        errorLabel.stringValue = message ?? ""
        errorBanner.isHidden = message == nil
    }

    @objc private func retryLoading() {
        recovery?.retryManually()
    }

    // MARK: - Window Actions (forwarded to window)

    @IBAction func performMiniaturize(_ sender: Any?) {
        view.window?.performMiniaturize(sender)
    }

    @IBAction func performZoom(_ sender: Any?) {
        view.window?.performZoom(sender)
    }

    // MARK: - Zoom Actions

    @IBAction func zoomIn(_ sender: Any?) {
        zoomLevel += 0.1
    }

    @IBAction func zoomOut(_ sender: Any?) {
        zoomLevel -= 0.1
    }

    @IBAction func resetZoom(_ sender: Any?) {
        zoomLevel = 1.0
    }

    // MARK: - Reload Action (CMD+R)

    @IBAction func reloadPage(_ sender: Any?) {
        recovery?.retryManually()
    }

    // MARK: - New Message Action (CMD+N)

    @IBAction func newMessage(_ sender: Any?) {
        let script = "window.__GOOFY.newMessage();"
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
            if case .failure(let error) = result {
                print("Failed to trigger new message: \(error)")
            }
        }
    }

    // MARK: - Search Action (CMD+F)

    @IBAction func focusSearch(_ sender: Any?) {
        let script = "window.__GOOFY.focusSearch();"
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
            if case .failure(let error) = result {
                print("Failed to focus search: \(error)")
            }
        }
    }

    // MARK: - Login with Safari Action

    @IBAction func loginWithSafari(_ sender: Any?) {
        guard safariLoginController == nil else { return }
        recovery?.suspend()
        view.window?.orderOut(nil)
        let controller = SafariLoginController()
        safariLoginController = controller
        controller.startLogin { [weak self] success in
            guard let self else { return }
            self.safariLoginController = nil
            if success {
                self.isAuthenticated = true
                self.recovery?.resume()
                self.loadMessenger()
            } else {
                self.showLoadError("Sign-in was cancelled. Use Retry to sign in again.")
            }
            self.view.window?.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Log Out Action

    @IBAction func logOut(_ sender: Any?) {
        isAuthenticated = false
        updateBadge(count: 0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            let messengerRecords = records.filter { record in
                record.displayName.contains("messenger.com")
                    || record.displayName.contains("facebook.com")
            }
            dataStore.removeData(ofTypes: dataTypes, for: messengerRecords) {
                DispatchQueue.main.async {
                    self.loadMessenger()
                }
            }
        }
    }

    // MARK: - Notifications Setup

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Request permission
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }

    // MARK: - Badge Updates

    private func updateBadge(count: Int) {
        DispatchQueue.main.async {
            if count > 0 {
                NSApp.dockTile.badgeLabel = "\(count)"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
        }
    }

    // MARK: - Show Notification

    private func showNotification(title: String, body: String, threadKey: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["threadKey": threadKey]

        // Use threadKey as identifier to group/replace notifications from same thread
        let identifier = threadKey.replacingOccurrences(of: "/", with: "_")
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }

    // MARK: - Navigate to Thread

    func navigateToThread(threadKey: String) {
        guard let data = try? JSONEncoder().encode(threadKey),
              let encodedKey = String(data: data, encoding: .utf8) else { return }
        let script = "window.__GOOFY.navigateToThread(\(encodedKey));"
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
            if case .failure(let error) = result {
                print("Failed to navigate to thread: \(error)")
            }
        }

        // Bring window to front
        NSApp.activate(ignoringOtherApps: true)
        if view.window?.isMiniaturized == true { view.window?.deminiaturize(nil) }
        view.window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - WKScriptMessageHandler

extension ViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        guard message.name == messageHandlerName, message.frameInfo.isMainFrame,
            FacebookURL.isTrustedHost(message.frameInfo.securityOrigin.host, domain: "facebook.com"),
            let body = message.body as? [String: Any],
            let type = body["type"] as? String
        else {
            return
        }

        switch type {
        case "ready":
            loadingView.isHidden = true

        case "badge":
            if let count = body["count"] as? Int {
                updateBadge(count: count)
            }

        case "read":
            if let keys = body["threadKeys"] as? [String] {
                let identifiers = keys.map { $0.replacingOccurrences(of: "/", with: "_") }
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            }

        case "notification":
            if let title = body["title"] as? String,
                let notificationBody = body["body"] as? String,
                let threadKey = body["threadKey"] as? String
            {
                showNotification(title: title, body: notificationBody, threadKey: threadKey)
            }

        case "log":
            if let logMessage = body["message"] as? String {
                print("[Goofy JS] \(logMessage)")
            }

        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Handle blob URLs as downloads
        if url.scheme == "blob" {
            decisionHandler(.download)
            return
        }

        let host = url.host ?? ""
        let isFacebook = FacebookURL.isTrustedHost(host, domain: "facebook.com")
        if isFacebook && (url.path.hasPrefix("/messages") || navigationAction.targetFrame?.isMainFrame == false) {
            decisionHandler(.allow)
            return
        }
        if isFacebook && (FacebookURL.isAuthentication(url) || !isAuthenticated) {
            decisionHandler(.cancel)
            DispatchQueue.main.async { [weak self] in self?.loginWithSafari(nil) }
            return
        }
        if ["fbsbx.com", "fbcdn.net"].contains(where: { FacebookURL.isTrustedHost(host, domain: $0) }) {
            decisionHandler(.allow)
            return
        }
        if navigationAction.navigationType == .linkActivated,
           let scheme = url.scheme, ["http", "https"].contains(scheme) {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        recovery?.navigationStarted()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        loadingView.isHidden = webView.url.map { !FacebookURL.isMessenger($0) } ?? true
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        recovery?.recover(reason: "Messenger's web process stopped.")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recovery?.navigationFinished()
        guard let url = webView.url else { return }
        print("Page finished loading: \(url.absoluteString)")

        guard FacebookURL.isTrustedHost(url.host ?? "", domain: "facebook.com"),
              safariLoginController == nil else { return }

        // Check if the user is authenticated; if not, open Safari login
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            let authenticated = cookies.contains { FacebookURL.isTrustedHost($0.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")), domain: "facebook.com") && $0.name == "c_user" }
            DispatchQueue.main.async {
                if authenticated {
                    self?.isAuthenticated = true
                } else {
                    print("[Goofy] Not authenticated, opening Safari login window")
                    self?.loginWithSafari(nil)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        recovery?.navigationFailed(error)
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        recovery?.navigationFailed(error)
    }
}

// MARK: - WKUIDelegate

extension ViewController: WKUIDelegate {
    // Handle JavaScript alerts
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

    // Handle JavaScript confirms
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

    // Handle file upload picker
    func webView(
        _ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        if panel.runModal() == .OK {
            completionHandler(panel.urls)
        } else {
            completionHandler(nil)
        }
    }

    // Handle new window requests (target="_blank" links)
    func webView(
        _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            if url.scheme == "blob" {
                // Load in current webview so decidePolicyFor can handle it as .download
                webView.load(navigationAction.request)
            } else {
                NSWorkspace.shared.open(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // Handle camera/microphone permission requests
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        // Only allow for messenger.com and facebook.com
        guard FacebookURL.isTrustedHost(origin.host, domain: "messenger.com") || FacebookURL.isTrustedHost(origin.host, domain: "facebook.com") else {
            decisionHandler(.deny)
            return
        }

        // Determine which media types are being requested
        let mediaTypes: [AVMediaType] = {
            switch type {
            case .camera:
                return [.video]
            case .microphone:
                return [.audio]
            case .cameraAndMicrophone:
                return [.video, .audio]
            @unknown default:
                return []
            }
        }()

        // Check and request permissions for all required media types
        checkAndRequestPermissions(for: mediaTypes) { allGranted in
            DispatchQueue.main.async {
                if allGranted {
                    decisionHandler(.grant)
                } else {
                    decisionHandler(.deny)
                    self.showPermissionDeniedAlert(for: type)
                }
            }
        }
    }

    private func checkAndRequestPermissions(
        for mediaTypes: [AVMediaType],
        completion: @escaping (Bool) -> Void
    ) {
        let group = DispatchGroup()
        var allGranted = true

        for mediaType in mediaTypes {
            group.enter()

            let status = AVCaptureDevice.authorizationStatus(for: mediaType)

            switch status {
            case .authorized:
                group.leave()

            case .notDetermined:
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    if !granted {
                        allGranted = false
                    }
                    group.leave()
                }

            case .denied, .restricted:
                allGranted = false
                group.leave()

            @unknown default:
                allGranted = false
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(allGranted)
        }
    }

    private func showPermissionDeniedAlert(for type: WKMediaCaptureType) {
        let alert = NSAlert()

        let deviceName: String
        switch type {
        case .camera:
            deviceName = "camera"
        case .microphone:
            deviceName = "microphone"
        case .cameraAndMicrophone:
            deviceName = "camera and microphone"
        @unknown default:
            deviceName = "media device"
        }

        alert.messageText = "\(deviceName.capitalized) Access Required"
        alert.informativeText =
            "Goofy needs \(deviceName) access for calls. Please enable it in System Settings > Privacy & Security > \(type == .microphone ? "Microphone" : "Camera")."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let urlString: String
            switch type {
            case .camera:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
            case .microphone:
                urlString =
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
            case .cameraAndMicrophone:
                urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
            @unknown default:
                urlString = "x-apple.systempreferences:com.apple.preference.security"
            }

            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - WKDownloadDelegate

extension ViewController: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        if panel.runModal() == .OK {
            completionHandler(panel.url)
        } else {
            completionHandler(nil)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension ViewController: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    // Handle notification click
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let threadKey = userInfo["threadKey"] as? String {
            navigateToThread(threadKey: threadKey)
        }
        completionHandler()
    }
}

// MARK: - Custom WebView

/// WKWebView subclass that passes through mouse events in the titlebar drag area
/// so the window can be dragged. The drag area is taller on the left side (55px for
/// the first 200px) when the window is wide enough (664px+), to cover the inset
/// traffic light buttons. Otherwise it's a uniform 18px strip.
class GoofyWebView: WKWebView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let dragHeight: CGFloat
        if bounds.width >= 664 && point.x <= 200 {
            dragHeight = 55
        } else {
            dragHeight = 18
        }
        if point.y > bounds.height - dragHeight {
            return nil
        }
        return super.hitTest(point)
    }
}
