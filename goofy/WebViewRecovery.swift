import Cocoa
import Network
import OSLog
import WebKit

/// Bounds recovery attempts and probes only while the user can interact with the page.
@MainActor
final class WebViewRecovery {
    private let logger = Logger(subsystem: "cc.buechele.Goofy", category: "Recovery")
    private weak var webView: WKWebView?
    private let monitor = NWPathMonitor()
    private var observers: [NSObjectProtocol] = []
    private var wakeObserver: NSObjectProtocol?
    private var timer: Timer?
    private var navigationTimeout: DispatchWorkItem?
    private var retry: DispatchWorkItem?
    private var probeTimeout: DispatchWorkItem?
    private var probeID: UUID?
    private var budget = RecoveryBudget()
    private var readinessDeadline: TimeInterval = 0
    private var recoveryStopped = false
    private var suspended = false
    private var connected = true
    private var needsRecovery = false
    var onFailure: ((String?) -> Void)?
    var onContentAvailable: (() -> Void)?

    init(webView: WKWebView) {
        self.webView = webView
        let center = NotificationCenter.default
        for name in [NSApplication.didBecomeActiveNotification,
                     NSWindow.didDeminiaturizeNotification, NSWindow.didBecomeKeyNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.checkHealth() }
            })
        }
        for name in [NSApplication.didResignActiveNotification, NSApplication.didHideNotification,
                     NSWindow.didMiniaturizeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.cancelProbe() }
            })
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor [weak self] in self?.checkHealth() } }
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.networkChanged(connected: path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "WebViewConnectivity"))
        let timer = Timer(timeInterval: 20, repeats: true) { [weak self] _ in Task { @MainActor [weak self] in self?.checkHealth() } }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
        monitor.cancel()
        navigationTimeout?.cancel()
        retry?.cancel()
        probeTimeout?.cancel()
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }

    func suspend() {
        suspended = true
        navigationTimeout?.cancel()
        navigationTimeout = nil
        retry?.cancel()
        retry = nil
        cancelProbe()
    }

    func resume() {
        suspended = false
        recoveryStopped = false
        budget.reset()
    }

    func navigationStarted() {
        guard !suspended else { return }
        readinessDeadline = ProcessInfo.processInfo.systemUptime + 45
        cancelProbe()
        retry?.cancel()
        retry = nil
        navigationTimeout?.cancel()
        onFailure?(nil)
        let timeout = DispatchWorkItem { [weak self] in
            self?.recover(reason: "Messenger took too long to load.")
        }
        navigationTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: timeout)
    }

    func navigationFinished() {
        navigationTimeout?.cancel()
        navigationTimeout = nil
        checkHealth()
    }

    func navigationFailed(_ error: Error) {
        let error = error as NSError
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled { return }
        recover(reason: "Messenger could not load. Check your connection and try again.")
    }

    func retryManually() {
        resume()
        retry?.cancel()
        retry = nil
        reload()
    }

    func recover(reason: String) {
        logger.notice("Recovery requested: \(reason, privacy: .public)")
        guard !suspended else { return }
        navigationTimeout?.cancel()
        navigationTimeout = nil
        cancelProbe()
        needsRecovery = true
        guard retry == nil, !recoveryStopped else { return }
        guard connected else {
            onFailure?("You are offline. Messenger will retry when the connection returns.")
            return
        }
        guard let delay = budget.nextDelay() else {
            recoveryStopped = true
            onFailure?(reason + " Use Retry to reconnect.")
            return
        }
        onFailure?("Reconnecting to Messenger…")
        let retry = DispatchWorkItem { [weak self] in
            self?.retry = nil
            self?.reload()
        }
        self.retry = retry
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: retry)
    }

    private func reload() {
        guard let webView else { return }
        needsRecovery = false
        cancelProbe()
        webView.stopLoading()
        if let url = webView.url, FacebookURL.isMessenger(url) {
            if webView.reload() == nil { webView.load(URLRequest(url: url)) }
        } else {
            webView.load(URLRequest(url: URL(string: "https://www.facebook.com/messages/")!))
        }
    }

    private func networkChanged(connected: Bool) {
        let restored = !self.connected && connected
        self.connected = connected
        if restored {
            budget.reset()
            recoveryStopped = false
            if needsRecovery { recover(reason: "Messenger could not reconnect.") }
            else { checkHealth() }
        }
    }

    func checkHealth() {
        guard let webView, connected, !suspended, !recoveryStopped, retry == nil, probeID == nil,
              NSApp.isActive, let window = webView.window,
              window.isVisible, !window.isMiniaturized, !webView.isLoading,
              let url = webView.url, FacebookURL.isMessenger(url) else { return }
        let id = UUID()
        probeID = id
        let timeout = DispatchWorkItem { [weak self] in
            guard let self, self.probeID == id else { return }
            guard NSApp.isActive, let window = self.webView?.window,
                  window.isVisible, !window.isMiniaturized else {
                self.cancelProbe()
                return
            }
            // A busy script is not proof that replacing the document is safe.
            self.cancelProbe()
            self.onFailure?("Messenger stopped responding. Use Retry to reload the page.")
        }
        probeTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)
        webView.evaluateJavaScript(
            "window.__GOOFY?.isReady() === true;",
            in: nil, in: .defaultClient
        ) { [weak self] result in
            guard let self, self.probeID == id else { return }
            self.cancelProbe()
            if case .success(let value) = result, value as? Bool == true {
                self.budget.reset()
                self.needsRecovery = false
                self.onContentAvailable?()
                self.onFailure?(nil)
            } else if ProcessInfo.processInfo.systemUptime >= self.readinessDeadline {
                // A responsive page can have a changed layout or an open editor.
                // Do not replace it just because our sidebar selector no longer matches.
                self.onContentAvailable?()
                self.onFailure?("Messenger's interface is not ready. Use Retry if it remains unavailable.")
            }
        }
    }

    private func cancelProbe() {
        probeID = nil
        probeTimeout?.cancel()
        probeTimeout = nil
    }
}
