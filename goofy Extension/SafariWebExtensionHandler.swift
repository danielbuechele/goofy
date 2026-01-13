//
//  SafariWebExtensionHandler.swift
//  goofy Extension
//
//  Created by Daniel Buchele on 11/01/2026.
//

import AppKit
import SafariServices

@available(macOS 11.0, *)
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    static let appGroupIdentifier = "group.cc.buechele.Goofy"

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let message = item?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        let messageType = message?["type"] as? String

        // Handle openURL request - open in default browser
        if messageType == "openURL", let urlString = message?["url"] as? String,
            let url = URL(string: urlString)
        {
            NSWorkspace.shared.open(url)
        }

        // Handle status updates (only for "status" message type)
        if messageType == "status" {
            if let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) {
                sharedDefaults.set(Date().timeIntervalSince1970, forKey: "lastUpdate")

                // Store individual check results
                if let checks = message?["checks"] as? [String: String] {
                    for (key, value) in checks {
                        sharedDefaults.set(value, forKey: "check_\(key)")
                    }
                }
            }
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["received": true]]
        context.completeRequest(returningItems: [response])
    }
}
