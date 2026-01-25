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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in dock when window closed
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Reopen window when dock icon clicked
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        Self.appUpdater.check()
    }

}
