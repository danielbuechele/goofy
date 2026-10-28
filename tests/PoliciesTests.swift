import Foundation

@main
struct PoliciesTests {
    static func main() {
        precondition(FacebookURL.isTrustedHost("www.facebook.com", domain: "facebook.com"))
        precondition(!FacebookURL.isTrustedHost("evilfacebook.com", domain: "facebook.com"))
        precondition(!FacebookURL.isTrustedHost("facebook.com.evil.test", domain: "facebook.com"))
        precondition(FacebookURL.isAuthentication(URL(string: "https://www.facebook.com/checkpoint/123")!))
        precondition(!FacebookURL.isAuthentication(URL(string: "https://www.facebook.com/messages/t/1")!))
        precondition(FacebookURL.isMessenger(URL(string: "https://www.facebook.com/messages/")!))
        precondition(FacebookURL.isMessenger(URL(string: "https://www.facebook.com/messages/e2ee/t/1")!))
        precondition(!FacebookURL.isMessenger(URL(string: "https://www.facebook.com/messages-other")!))
        precondition(!FacebookURL.isMessenger(URL(string: "https://example.fbsbx.com/file.pdf")!))
        precondition(!FacebookURL.isMessenger(URL(string: "https://example.fbcdn.net/image.jpg")!))
        precondition(!FacebookURL.isMessenger(URL(string: "http://www.facebook.com/messages/")!))
        var budget = RecoveryBudget()
        precondition(budget.nextDelay() == 1)
        precondition(budget.nextDelay() == 2)
        precondition(budget.nextDelay() == 4)
        precondition(budget.nextDelay() == nil)
        precondition(budget.nextDelay() == nil)
        budget.reset()
        precondition(budget.nextDelay() == 1)
        print("Policies: host validation, authentication routing, consecutive retry limit and reset passed")
    }
}
