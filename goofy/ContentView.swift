//
//  ContentView.swift
//  goofy
//
//  Created by Daniel Büchele on 02/01/2026.
//

import AppUpdater
import Combine
import SwiftUI

enum MessengerAppState {
    case notFound
    case wrongURL
    case installed
}

enum CheckStatus: String {
    case pending
    case pass
    case warning
    case fail
}

struct HealthCheck: Identifiable {
    let id: String
    let name: String
    let userDefaultsKey: String
    var status: CheckStatus = .pending

    // Extension-reported checks (read from UserDefaults)
    static let all: [HealthCheck] = [
        HealthCheck(id: "domain", name: "Messenger loaded", userDefaultsKey: "check_domain"),
        HealthCheck(id: "script", name: "Script injection", userDefaultsKey: "check_script"),
        HealthCheck(
            id: "observerInbox", name: "Inbox observer", userDefaultsKey: "check_observerInbox"),
        HealthCheck(
            id: "observerThreadlist", name: "Thread list observer",
            userDefaultsKey: "check_observerThreadlist"),
    ]
}

extension Image {
    func screenshotStyle() -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 333)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }
}

// Set to true to show a mock update banner for UI testing
private let debugShowMockUpdate = false

struct UpdateBanner: View {
    @EnvironmentObject var appUpdater: AppUpdater
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Group {
            if showError {
                // Error banner
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Failed")
                            .font(.system(size: 12, weight: .medium))
                        Text(errorMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button("Retry") {
                        showError = false
                        errorMessage = ""
                        appUpdater.check()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else if debugShowMockUpdate {
                // Mock update banner for testing UI
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Available")
                            .font(.system(size: 12, weight: .medium))
                        Text("Version 4.1.0 is ready to install")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Install & Restart") {
                        // No-op for mock
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                realUpdateBanner
            }
        }
        .onReceive(appUpdater.$lastError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    @ViewBuilder
    private var realUpdateBanner: some View {
        switch appUpdater.state {
        case .none:
            EmptyView()

        case .downloading(let release, _, let fraction):
            HStack(spacing: 12) {
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(width: 100)
                Text("Downloading v\(release.tagName)...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

        case .newVersionDetected(let release, _):
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Preparing v\(release.tagName)...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

        case .downloaded(let release, _, _):
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available")
                        .font(.system(size: 12, weight: .medium))
                    Text("Version \(release.tagName) is ready to install")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Install & Restart") {
                    appUpdater.install()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct ContentView: View {
    // App Group identifier - must match the one configured in Xcode
    static let appGroupIdentifier = "group.cc.buechele.Goofy"

    @EnvironmentObject var appUpdater: AppUpdater
    @State private var extensionConnected: Bool = false
    @State private var statusCheckTimer: Timer?
    @State private var messengerAppState: MessengerAppState = .notFound

    // Health check statuses
    @State private var healthChecks: [HealthCheck] = HealthCheck.all

    private var allChecksPassing: Bool {
        healthChecks.allSatisfy { $0.status == .pass }
    }

    private var failingChecks: [HealthCheck] {
        healthChecks.filter { $0.status != .pass }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Update banner - shows when update is available
            UpdateBanner()

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
                    description: "",
                    status: StatusIndicator(state: messengerAppState)
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            if let safariURL = NSWorkspace.shared.urlForApplication(
                                withBundleIdentifier: "com.apple.Safari")
                            {
                                let url = URL(string: "https://www.messenger.com")!
                                NSWorkspace.shared.open(
                                    [url], withApplicationAt: safariURL,
                                    configuration: NSWorkspace.OpenConfiguration())
                            }
                        } label: {
                            Text("Open Messenger in Safari")
                        }
                        .buttonStyle(.link)

                        Text("Then select **File ›  Add to Dock...** from Safari's menu bar.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Image("AddToDock")
                            .screenshotStyle()

                        Text(
                            verbatim:
                                "Ensure the URL is just https://www.messenger.com/ with no additional path."
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                StepRow(
                    number: 2,
                    title: "Enable the Goofy extension in the web app",
                    description:
                        "Open the Settings of the newly created web app, go to Extensions, and enable Goofy for Messenger",
                    status: extensionConnected
                        ? StatusIndicator(
                            "Goofy extension enabled", color: .green, isComplete: true)
                        : StatusIndicator("Goofy extension not enabled", color: .gray)
                ) {
                    Image("EnableExtension")
                        .screenshotStyle()
                }

                StepRow(
                    number: 3,
                    title: "Allow Notifications",
                    description:
                        "Allow notifications when prompted to receive message alerts"
                ) {
                    Image("Notifications")
                        .screenshotStyle()
                }

                StepRow(
                    number: 4,
                    title: "Extension Status",
                    description: "",
                    status: !extensionConnected
                        ? StatusIndicator("Waiting for extension", color: .gray)
                        : allChecksPassing
                            ? StatusIndicator(
                                "Extension working as expected", color: .green, isComplete: true)
                            : nil
                ) {
                    if extensionConnected && !allChecksPassing {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(failingChecks) { check in
                                StatusIndicator(checkStatus: check.status, text: check.name)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .frame(width: 425)
        .fixedSize(horizontal: false, vertical: true)
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

        // Check for Messenger web app (keep checking until found)
        if messengerAppState != .installed {
            messengerAppState = checkMessengerWebAppInstalled()
        }
    }

    private func updateConnectionStatus() {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            return
        }

        let lastUpdate = sharedDefaults.double(forKey: "lastUpdate")
        let now = Date().timeIntervalSince1970

        let isConnected = now - lastUpdate < 3.0

        // Update connection status (once connected, stay connected)
        if !extensionConnected {
            extensionConnected = isConnected
        }

        // Read health check statuses from extension
        if isConnected {
            for i in healthChecks.indices {
                let key = healthChecks[i].userDefaultsKey
                healthChecks[i].status =
                    CheckStatus(rawValue: sharedDefaults.string(forKey: key) ?? "") ?? .pending
            }
        }
    }

    private func checkMessengerWebAppInstalled() -> MessengerAppState {
        let fileManager = FileManager.default
        // Use getpwuid to get the real home directory, bypassing sandbox redirection
        guard let pw = getpwuid(getuid()),
            let home = pw.pointee.pw_dir
        else {
            return .notFound
        }
        let realHomeDir = String(cString: home)
        let applicationsURL = URL(fileURLWithPath: realHomeDir)
            .appendingPathComponent("Applications")

        guard
            let apps = try? fileManager.contentsOfDirectory(
                at: applicationsURL,
                includingPropertiesForKeys: nil
            )
        else {
            return .notFound
        }

        for appURL in apps where appURL.pathExtension == "app" {
            let plistURL = appURL.appendingPathComponent("Contents/Info.plist")

            guard let plist = NSDictionary(contentsOf: plistURL),
                let bundleID = plist["CFBundleIdentifier"] as? String
            else {
                continue
            }

            if bundleID.hasPrefix("com.apple.Safari.WebApp") {
                if let manifest = plist["Manifest"] as? [String: Any],
                    let startURL = manifest["start_url"] as? String,
                    startURL.contains("messenger.com")
                {
                    // Check if URL is exactly https://www.messenger.com or https://www.messenger.com/
                    let normalizedURL = startURL.trimmingCharacters(
                        in: CharacterSet(charactersIn: "/"))
                    if normalizedURL == "https://www.messenger.com" {
                        return .installed
                    } else {
                        return .wrongURL
                    }
                }
            }
        }

        return .notFound
    }
}

struct CollapsingView<Content: View>: View {
    let isCollapsed: Bool
    let content: Content

    @State private var contentHeight: CGFloat = 0

    init(isCollapsed: Bool, @ViewBuilder content: () -> Content) {
        self.isCollapsed = isCollapsed
        self.content = content()
    }

    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { contentHeight = geo.size.height }
                        .onChange(of: geo.size.height) {
                            if !isCollapsed {
                                contentHeight = geo.size.height
                            }
                        }
                }
            )
            .modifier(AnimatableCollapse(height: isCollapsed ? 0 : contentHeight))
            .animation(.easeInOut(duration: 0.3), value: isCollapsed)
    }
}

struct AnimatableCollapse: AnimatableModifier {
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: max(0, height))
                    Spacer(minLength: 0)
                }
            )
            .frame(height: max(0, height), alignment: .top)
            .opacity(height < 1 ? 0 : 1)
    }
}

struct StatusIndicator: View {
    let isComplete: Bool
    let color: Color
    let text: String

    init(_ text: String, color: Color, isComplete: Bool = false) {
        self.text = text
        self.color = color
        self.isComplete = isComplete
    }

    init(state: MessengerAppState) {
        switch state {
        case .installed:
            self.init("Messenger web app installed", color: .green, isComplete: true)
        case .wrongURL:
            self.init("Messenger web app has incorrect URL", color: .orange)
        case .notFound:
            self.init("Messenger web app not found", color: .gray)
        }
    }

    init(checkStatus: CheckStatus, text: String) {
        switch checkStatus {
        case .pass:
            self.init(text, color: .green, isComplete: true)
        case .warning:
            self.init(text, color: .orange)
        case .fail:
            self.init(text, color: .red)
        case .pending:
            self.init(text, color: .gray)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct StepRow<Accessory: View>: View {
    let number: Int
    let title: String
    let description: String
    let status: StatusIndicator?
    let accessory: Accessory?

    private var isComplete: Bool {
        status?.isComplete ?? false
    }

    init(
        number: Int, title: String, description: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.number = number
        self.title = title
        self.description = description
        self.status = nil
        self.accessory = accessory()
    }

    init(
        number: Int, title: String, description: String, status: StatusIndicator?,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.number = number
        self.title = title
        self.description = description
        self.status = status
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
                    .padding(.top, 3)

                if let status = status {
                    status
                }

                CollapsingView(isCollapsed: isComplete) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !description.isEmpty {
                            Text(description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let accessory = accessory {
                            accessory
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            AppUpdater(owner: "danielbuechele", repo: "goofy", releasePrefix: "Goofy")
        )
        .frame(width: 425, height: 327)
}
