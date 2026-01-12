//
//  ContentView.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import SwiftUI

enum ConnectionStatus {
    case disconnected      // No signal received
    case warning           // Signal from regular Safari
    case connected         // Signal from PWA
}

struct ContentView: View {
    // App Group identifier - must match the one configured in Xcode
    static let appGroupIdentifier = "group.cc.buechele.Goofy"

    @State private var connectionStatus: ConnectionStatus = .disconnected
    @State private var statusCheckTimer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            // Header with icon and title (centered)
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)

                Text("Goofy Setup")
                    .font(.system(size: 18, weight: .semibold))
            }

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                StepRow(
                    number: 1,
                    title: "Add Messenger to your Dock",
                    description: ""
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
                                let url = URL(string: "https://www.messenger.com")!
                                NSWorkspace.shared.open([url], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
                            }
                        } label: {
                            Text("Open Messenger in Safari")
                        }
                        .buttonStyle(.link)

                        Text("Then select **File ›  Add to Dock...** from Safari's menu bar.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(nsColor: NSColor(red: 0.43, green: 0.43, blue: 0.45, alpha: 1.0)))
                            .fixedSize(horizontal: false, vertical: true)

                        Image("AddToDock")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                }

                StepRow(
                    number: 2,
                    title: "Enable the Goofy extension in the web app",
                    description: "Open the Settings of the newly created web app, go to Extensions, and enable Goofy for Messenger"
                ) {
                    ConnectionStatusView(status: connectionStatus)
                }

                StepRow(
                    number: 3,
                    title: "Grant permissions",
                    description: "Allow notifications when prompted to receive message alerts"
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .frame(maxWidth: 480)
        .onAppear {
            // Start polling: request status from extension, then check shared UserDefaults
            checkExtensionStatus()
            statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                checkExtensionStatus()
            }
        }
        .onDisappear {
            statusCheckTimer?.invalidate()
            statusCheckTimer = nil
        }
    }

    private func checkExtensionStatus() {
        // Just read from shared UserDefaults - extension writes status periodically
        updateConnectionStatus()
    }

    private func updateConnectionStatus() {
        // Once connected, stay connected
        if connectionStatus == .connected {
            return
        }

        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            connectionStatus = .disconnected
            return
        }

        let lastUpdate = sharedDefaults.double(forKey: "lastUpdate")
        let lastPWAUpdate = sharedDefaults.double(forKey: "lastPWAUpdate")
        let now = Date().timeIntervalSince1970

        // PWA response takes priority - if we see it recently, stay green
        if now - lastPWAUpdate < 3.0 {
            connectionStatus = .connected
        } else if now - lastUpdate < 3.0 {
            connectionStatus = .warning
        } else {
            connectionStatus = .disconnected
        }
    }
}

struct ConnectionStatusView: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .disconnected:
            return .gray
        case .warning:
            return .orange
        case .connected:
            return .green
        }
    }

    private var statusText: String {
        switch status {
        case .disconnected:
            return "Goofy extension not enabled"
        case .warning:
            return "Enable the Goofy extension in the web app, not Safari"
        case .connected:
            return "Goofy extension enabled correctly"
        }
    }
}

struct StepRow<Accessory: View>: View {
    let number: Int
    let title: String
    let description: String
    let accessory: Accessory?

    init(number: Int, title: String, description: String) where Accessory == EmptyView {
        self.number = number
        self.title = title
        self.description = description
        self.accessory = nil
    }

    init(number: Int, title: String, description: String, @ViewBuilder accessory: () -> Accessory) {
        self.number = number
        self.title = title
        self.description = description
        self.accessory = accessory()
    }

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
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: NSColor(red: 0.43, green: 0.43, blue: 0.45, alpha: 1.0)))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let accessory = accessory {
                    accessory
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 425, height: 327)
}
