import Foundation

enum FacebookURL {
    static func isMessenger(_ url: URL) -> Bool {
        url.scheme == "https"
            && isTrustedHost(url.host ?? "", domain: "facebook.com")
            && (url.path == "/messages" || url.path.hasPrefix("/messages/"))
    }

    static func isTrustedHost(_ host: String, domain: String) -> Bool {
        let host = host.lowercased()
        return host == domain || host.hasSuffix("." + domain)
    }

    static func isAuthentication(_ url: URL) -> Bool {
        guard isTrustedHost(url.host ?? "", domain: "facebook.com") else { return false }
        return ["/login", "/checkpoint", "/two_step_verification", "/recover",
                "/cookie/consent", "/dialog", "/auth"].contains { url.path.lowercased().hasPrefix($0) }
    }
}

struct RecoveryBudget {
    private var attempts = 0

    mutating func nextDelay() -> TimeInterval? {
        guard attempts < 3 else { return nil }
        let delay = pow(2, Double(attempts))
        attempts += 1
        return delay
    }

    mutating func reset() { attempts = 0 }
}
