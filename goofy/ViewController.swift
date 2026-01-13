//
//  ViewController.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import Cocoa
import Combine
import SwiftUI

class ViewController: NSViewController {

    private var hostingView: NSHostingView<ContentView>!
    private var displayLink: CVDisplayLink?
    private var lastHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        hostingView = NSHostingView(rootView: ContentView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // Set up a timer to poll for size changes
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.checkForSizeChange()
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Initial size without animation
        updateWindowSize(animated: false)
        view.window?.center()
    }

    private func checkForSizeChange() {
        let fittingSize = hostingView.fittingSize
        if abs(fittingSize.height - lastHeight) > 0.5 {
            updateWindowSize(animated: true)
        }
    }

    private func updateWindowSize(animated: Bool) {
        guard let window = view.window else { return }

        let fittingSize = hostingView.fittingSize
        lastHeight = fittingSize.height
        let newSize = NSSize(width: 425, height: fittingSize.height)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setContentSize(newSize)
            }
        } else {
            window.setContentSize(newSize)
        }
    }

}
