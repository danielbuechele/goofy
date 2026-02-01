//
//  AppDelegate.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AppUpdater
import Cocoa
import Combine
import UserNotifications
internal import Version

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    static let appUpdater = AppUpdater(
        owner: "danielbuechele", repo: "goofy", releasePrefix: "Goofy")

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set window delegate to intercept close events
        if let window = NSApplication.shared.windows.first {
            window.delegate = self
        }

        // Observe update state changes to show install prompt
        Self.appUpdater.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                print("[AutoUpdater] State changed: \(state)")
                if case .downloaded(let release, _, let bundle) = state {
                    self?.showUpdateAlert(version: release.tagName.description, bundle: bundle)
                }
            }
            .store(in: &cancellables)

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

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide window instead of closing when close button or CMD+W is pressed
        sender.orderOut(nil)
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

    private func showUpdateAlert(version: String, bundle: Bundle) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText =
            "A new version (\(version)) of Goofy is ready to install. The app will restart after updating."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install & Restart")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Self.appUpdater.install(bundle)
        }
    }

    @IBAction func openGitHub(_ sender: Any?) {
        if let url = URL(string: "https://github.com/danielbuechele/goofy") {
            NSWorkspace.shared.open(url)
        }
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
                // AUError.cancelled means the app is already up-to-date (not an actual error)
                if case AUError.cancelled = error {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "No Update Available"
                        alert.informativeText = "You're running the latest version of Goofy."
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                    return
                }
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
