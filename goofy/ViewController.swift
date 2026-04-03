//
//  ViewController.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AVFoundation
import Cocoa
import Network
import UserNotifications
import WebKit

class ViewController: NSViewController {

    private var webView: GoofyWebView!
    private let messageHandlerName = "goofy"

    // Periodic reload properties
    private let reloadInterval: TimeInterval = 3 * 60 * 60  // 3 hours
    private var reloadPending = false
    private var reloadTimer: Timer?
    private var networkMonitor: NWPathMonitor?
    private var wasNetworkConnected = true
    private var windowConfigured = false
    private var isAuthenticated = false
    private var safariLoginController: SafariLoginController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNotifications()
        loadMessenger()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if !windowConfigured {
            configureWindow()
            setupPeriodicReload()
            windowConfigured = true
        }
    }

    deinit {
        reloadTimer?.invalidate()
        networkMonitor?.cancel()
        NotificationCenter.default.removeObserver(self)
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: messageHandlerName, contentWorld: .defaultClient)
    }

    // MARK: - WebView Setup

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let userContentController = WKUserContentController()

        // Use .defaultClient world to isolate our code from the page's JS
        userContentController.add(self, contentWorld: .defaultClient, name: messageHandlerName)

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

        webView.allowsBackForwardNavigationGestures = true

        // Set custom user agent to appear as Safari
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString =
            "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionString)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

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
        window.backgroundColor = NSColor(
            red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0)
    }

    private func loadMessenger() {
        guard let url = URL(string: "https://www.facebook.com/messages/") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - Periodic Reload

    private func setupPeriodicReload() {
        // Observer for when app goes to background - handles pending reloads
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Observer for system wake from sleep
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: NSWorkspace.shared
        )

        // Timer that fires every 4 hours
        reloadTimer = Timer.scheduledTimer(
            withTimeInterval: reloadInterval,
            repeats: true
        ) { [weak self] _ in
            self?.timerFired()
        }

        // Network connectivity monitor
        setupNetworkMonitor()
    }

    private func setupNetworkMonitor() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkChange(path)
            }
        }
        networkMonitor?.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    private func timerFired() {
        if NSApplication.shared.isActive {
            // App is in foreground - defer reload
            reloadPending = true
            print("Reload deferred - app is in foreground")
        } else {
            // App is in background - reload now
            performReload()
        }
    }

    @objc private func systemDidWake(_ notification: Notification) {
        print("System woke from sleep - reloading")
        performReload()
    }

    private func handleNetworkChange(_ path: NWPath) {
        let isConnected = path.status == .satisfied

        // Reload when connection is restored after being disconnected
        if !wasNetworkConnected && isConnected {
            print("Network connection restored - reloading")
            performReload()
        }

        wasNetworkConnected = isConnected
    }

    private func performReload() {
        reloadPending = false
        webView.reload()
        print("Reload performed")
    }

    @objc private func applicationDidResignActive(_ notification: Notification) {
        if reloadPending {
            performReload()
        }
    }

    // MARK: - Window Actions (forwarded to window)

    @IBAction func performMiniaturize(_ sender: Any?) {
        view.window?.performMiniaturize(sender)
    }

    @IBAction func performZoom(_ sender: Any?) {
        view.window?.performZoom(sender)
    }

    // MARK: - Reload Action (CMD+R)

    @IBAction func reloadPage(_ sender: Any?) {
        loadMessenger()
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
        view.window?.orderOut(nil)
        let controller = SafariLoginController()
        safariLoginController = controller
        controller.startLogin { [weak self] in
            self?.safariLoginController = nil
            self?.loadMessenger()
            self?.view.window?.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Log Out Action

    @IBAction func logOut(_ sender: Any?) {
        isAuthenticated = false
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
        let escapedKey = threadKey.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "window.__GOOFY.navigateToThread(\"\(escapedKey)\");"
        webView.evaluateJavaScript(script, in: nil, in: .defaultClient) { result in
            if case .failure(let error) = result {
                print("Failed to navigate to thread: \(error)")
            }
        }

        // Bring window to front
        NSApp.activate(ignoringOtherApps: true)
        view.window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - WKScriptMessageHandler

extension ViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        guard message.name == messageHandlerName,
            let body = message.body as? [String: Any],
            let type = body["type"] as? String
        else {
            return
        }

        switch type {
        case "badge":
            if let count = body["count"] as? Int {
                updateBadge(count: count)
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

        // Allow facebook.com/messages and Facebook internal domains in the main webview
        let host = url.host ?? ""
        if host.contains("facebook.com") && url.path.hasPrefix("/messages") ||
           host.contains("fbsbx.com") || host.contains("fbcdn.net") {
            decisionHandler(.allow)
            return
        }

        // Before login, silently cancel all other navigations (login redirects)
        if !isAuthenticated {
            decisionHandler(.cancel)
            return
        }

        // After login, open non-messages URLs externally
        if let scheme = url.scheme, ["http", "https"].contains(scheme) {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        print("Page finished loading: \(url.absoluteString)")

        guard url.host?.contains("facebook.com") == true,
              safariLoginController == nil else { return }

        // Check if the user is authenticated; if not, open Safari login
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            let authenticated = cookies.contains { $0.domain.contains("facebook.com") && $0.name == "c_user" }
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
        print("Navigation failed: \(error.localizedDescription)")
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        print("Provisional navigation failed: \(error.localizedDescription)")
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
        guard origin.host.contains("messenger.com") || origin.host.contains("facebook.com") else {
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
