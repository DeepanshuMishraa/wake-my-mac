import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show(state: AppState) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView(state: state))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "StayRunning Settings"
        window.contentViewController = hosting
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}

struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var draft: HoldSettings

    init(state: AppState) {
        self.state = state
        _draft = State(initialValue: state.settings)
    }

    var body: some View {
        Form {
            Section("Operating Mode") {
                Picker("Mode", selection: $draft.mode) {
                    ForEach(HoldMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
                Text(draft.mode.explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Battery") {
                Stepper("Stop below \(draft.batteryCutoffPercent)%", value: $draft.batteryCutoffPercent, in: 5...80, step: 5)
                Toggle("Only hold when plugged in", isOn: $draft.onlyWhenPluggedIn)
                Toggle("Respect Low Power Mode", isOn: $draft.respectLowPowerMode)
            }

            Section("Reliable Wake") {
                Text(reliableWakeDescription)
                    .foregroundStyle(.secondary)
                if state.reliableWakeState.needsSetupAction {
                    Button(state.reliableWakeState == .approvalRequired ? "Open Login Items…" : "Enable Reliable Wake") {
                        state.performReliableWakeSetupAction()
                    }
                }
            }

            Section("Notifications") {
                Toggle("Show notifications and play chimes", isOn: $draft.notificationsEnabled)
                Picker("Sound", selection: $draft.soundName) {
                    ForEach(["Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink", "Funk"], id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
            }

            Section("Updates") {
                HStack {
                    Text("Signed updates are delivered automatically through Sparkle.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check Now…") { UpdateService.shared.checkForUpdates(nil) }
                }
            }

            Section("Limits") {
                Text("StayRunning keeps system and network activity awake while allowing the display to turn off. macOS may still enforce sleep because of hardware, thermal, battery, or enterprise safety policy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520, height: 520)
        .onChange(of: draft) { _, settings in
            state.updateSettings(settings)
        }
        .onChange(of: state.settings) { _, settings in
            if draft != settings { draft = settings }
        }
    }

    private var reliableWakeDescription: String {
        switch state.reliableWakeState {
        case .active: "Reliable wake is active and verified."
        case .ready: "The reliable wake helper is ready."
        case .approvalRequired: "Approval is required in System Settings before reliable wake can run."
        case .failed(let message): "Reliable wake failed: \(message)"
        default: "StayRunning registers its helper automatically. macOS requires one approval before it can prevent lid-close sleep."
        }
    }
}
