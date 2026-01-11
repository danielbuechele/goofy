//
//  ViewController.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import Cocoa
import SwiftUI

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingView = NSHostingView(rootView: ContentView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Size window to fit content
        if let window = view.window {
            let hostingView = view.subviews.first as? NSHostingView<ContentView>
if let fittingSize = hostingView?.fittingSize {
                let newSize = NSSize(width: 425, height: fittingSize.height)
                window.setContentSize(newSize)
                window.center()
            }
        }
    }

}
