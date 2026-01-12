//
//  SafariWebExtensionHandler.swift
//  goofy Extension
//
//  Created by Daniel Buchele on 11/01/2026.
//

import SafariServices

@available(macOS 11.0, *)
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    static let appGroupIdentifier = "group.cc.buechele.Goofy"

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        let isPWA = message?["isPWA"] as? Bool ?? false

        if let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
            let now = Date().timeIntervalSince1970

            if isPWA {
                sharedDefaults.set(true, forKey: "isPWA")
                sharedDefaults.set(now, forKey: "lastPWAUpdate")
            }

            sharedDefaults.set(now, forKey: "lastUpdate")
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["received": true]]
        context.completeRequest(returningItems: [response])
    }
}
