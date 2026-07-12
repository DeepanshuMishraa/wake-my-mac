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
        window.title = "Wake My Mac Settings"
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

            Section("Display") {
                Toggle("Turn display off on lid close when possible", isOn: $draft.turnDisplayOffOnLidClose)
                Stepper(
                    "Display off \(draft.turnDisplayOffAfterFinishSeconds)s after finish",
                    value: $draft.turnDisplayOffAfterFinishSeconds,
                    in: 0...300,
                    step: 10
                )
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
                    Text("Updates are delivered from GitHub Releases using Sparkle.")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check Now…") { UpdateService.shared.checkForUpdates(nil) }
                }
            }

            Section("Limits") {
                Text("Wake My Mac keeps system and network activity awake while allowing the display to turn off. macOS may still enforce sleep because of hardware, thermal, battery, or enterprise safety policy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Apply") {
                    state.updateSettings(draft)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520, height: 520)
    }
}
