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

    private var webView: WKWebView!
    private let messageHandlerName = "goofy"
    private var isInboxObserverActive = false
    private var webViewTopConstraint: NSLayoutConstraint!

    // Periodic reload properties
    private let reloadInterval: TimeInterval = 3 * 60 * 60  // 3 hours
    private var reloadPending = false
    private var reloadTimer: Timer?
    private var networkMonitor: NWPathMonitor?
    private var wasNetworkConnected = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNotifications()
        loadMessenger()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        configureWindow()
        setupPeriodicReload()
    }

    deinit {
        reloadTimer?.invalidate()
        networkMonitor?.cancel()
        NotificationCenter.default.removeObserver(self)
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: messageHandlerName)
    }

    // MARK: - WebView Setup

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()

        // Configure preferences
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        // Enable developer extras for debugging
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // Configure data store for persistent cookies
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        // Set up user content controller for script injection
        let userContentController = WKUserContentController()

        // Add message handler for JS -> Swift communication
        userContentController.add(self, name: messageHandlerName)

        // Inject content.js at document end
        if let scriptURL = Bundle.main.url(forResource: "content", withExtension: "js"),
            let scriptContent = try? String(contentsOf: scriptURL, encoding: .utf8)
        {
            let userScript = WKUserScript(
                source: scriptContent,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true,
                in: .page  // Inject into page world (MAIN), not content world
            )
            userContentController.addUserScript(userScript)
        }

        configuration.userContentController = userContentController

        // Create WebView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Allow back/forward navigation gestures
        webView.allowsBackForwardNavigationGestures = true

        // Make webview transparent while loading
        webView.setValue(false, forKey: "drawsBackground")

        // Set custom user agent to appear as Safari
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString =
            "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"
        webView.customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionString)) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        view.addSubview(webView)
        view.clipsToBounds = false

        webViewTopConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)
        NSLayoutConstraint.activate([
            webViewTopConstraint,
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureWindow() {
        guard let window = view.window else { return }

        // Set minimum window size
        window.minSize = NSSize(width: 400, height: 600)

        // Set initial size
        window.setContentSize(NSSize(width: 1200, height: 800))
        window.center()

        // Make window resizable
        window.styleMask.insert(.resizable)

        // Pull webview up behind titlebar
        let titlebarHeight = window.frame.height - window.contentLayoutRect.height
        webViewTopConstraint.constant = -titlebarHeight

        // Set background color for window and titlebar
        window.backgroundColor = NSColor(
            red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0)
    }

    private func loadMessenger() {
        guard let url = URL(string: "https://www.messenger.com/") else { return }
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

    // MARK: - Reload Action (CMD+R)

    @IBAction func reloadPage(_ sender: Any?) {
        loadMessenger()
    }

    // MARK: - New Message Action (CMD+N)

    @IBAction func newMessage(_ sender: Any?) {
        let script = "window.__GOOFY.newMessage();"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Failed to trigger new message: \(error)")
            }
        }
    }

    // MARK: - Log Out Action

    @IBAction func logOut(_ sender: Any?) {
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

    // MARK: - Open External URL

    private func openExternalURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Navigate to Thread

    func navigateToThread(threadKey: String) {
        let escapedKey = threadKey.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "window.__GOOFY.navigateToThread(\"\(escapedKey)\");"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
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

        case "openURL":
            if let url = body["url"] as? String {
                openExternalURL(url)
            }

        case "log":
            if let logMessage = body["message"] as? String {
                print("[Goofy JS] \(logMessage)")
            }

        case "inboxObserverState":
            if let active = body["active"] as? Bool {
                isInboxObserverActive = active
                print("Inbox observer state: \(active)")
            }

        default:
            print("Unknown message type: \(type)")
        }
    }
}

// MARK: - Menu Validation

extension ViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(logOut(_:)) {
            return isInboxObserverActive
        }
        return true
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

        // Allow messenger.com and facebook.com URLs (for login)
        if let host = url.host, host.contains("messenger.com") || host.contains("facebook.com") {
            decisionHandler(.allow)
            return
        }

        // For external URLs opened via link click, open in default browser
        if navigationAction.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // Allow other navigations (redirects, etc.)
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page finished loading: \(webView.url?.absoluteString ?? "unknown")")
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
        // Open in default browser instead of creating new window
        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }

    // Handle camera/microphone permission requests
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        // Only allow for messenger.com
        guard origin.host.contains("messenger.com") else {
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
