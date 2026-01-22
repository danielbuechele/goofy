//
//  AppDelegate.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AppUpdater
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    static let appUpdater = AppUpdater(
        owner: "danielbuechele", repo: "goofy", releasePrefix: "Goofy")

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.appUpdater.check()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
