//
//  AppDelegate.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AppUpdater
import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    static let appUpdater = AppUpdater(
        owner: "danielbuechele", repo: "goofy", releasePrefix: "Goofy")

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.appUpdater.check()

        // Request notification permissions early
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in dock when window closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        // Reopen window when dock icon clicked
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        Self.appUpdater.check(
            success: {
                // Success is called when check completes - if no update window appears,
                // it means we're on the latest version
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "No Update Available"
                    alert.informativeText = "You're running the latest version of Goofy."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            },
            fail: { error in
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Update Check Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        )
    }

}
