//
//  ContentView.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header with icon and title (centered)
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)

                Text("Goofy for Messenger")
                    .font(.system(size: 18, weight: .semibold))
            }

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                StepRow(
                    number: 1,
                    title: "Add Messenger to your Dock",
                    description: "Open messenger.com in Safari, then choose File > Add to Dock…"
                )

                StepRow(
                    number: 2,
                    title: "Enable the extension",
                    description: "Open Settings > Extensions and enable Goofy"
                )

                StepRow(
                    number: 3,
                    title: "Grant permissions",
                    description: "Allow notifications when prompted to receive message alerts"
                )
            }

            // Footer with button and link
            HStack(spacing: 16) {
                Button("Open Messenger in Safari") {
                    if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
                        let url = URL(string: "https://www.messenger.com")!
                        NSWorkspace.shared.open([url], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("View full setup guide") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/danielbuechele/goofy#installation")!)
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
        .padding(.bottom, 44)
        .frame(maxWidth: 480)
    }
}

struct StepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Number circle
            Text("\(number)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(nsColor: NSColor(red: 0.43, green: 0.43, blue: 0.45, alpha: 1.0)))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color(nsColor: NSColor(red: 0, green: 0.4, blue: 0.84, alpha: 1.0)) : Color(nsColor: NSColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0)))
            .cornerRadius(6)
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundColor(Color(nsColor: NSColor(red: 0, green: 0.48, blue: 1.0, alpha: 1.0)))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

#Preview {
    ContentView()
        .frame(width: 425, height: 327)
}
