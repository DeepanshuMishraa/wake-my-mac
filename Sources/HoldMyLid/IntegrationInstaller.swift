import AppKit
import Foundation
import SwiftUI

struct IntegrationStatus: Identifiable {
    let agent: AgentKind
    let executablePath: String?
    let destination: String
    let capability: String
    let configured: Bool

    var id: AgentKind { agent }
    var isInstalled: Bool { executablePath != nil || agent.appPaths.contains(where: FileManager.default.fileExists(atPath:)) }
}

@MainActor
enum IntegrationInstaller {
    private static var windowController: IntegrationWindowController?
    private static let configuredKey = "integrationSetupHasBeenShown"

    static func statuses() -> [IntegrationStatus] {
        AgentKind.allCases.map { agent in
            IntegrationStatus(
                agent: agent,
                executablePath: agent.resolvedExecutablePath,
                destination: destination(for: agent).path,
                capability: capability(for: agent),
                configured: isConfigured(agent)
            )
        }
    }

    static var hasUnconfiguredInstalledIntegrations: Bool {
        statuses().contains { $0.isInstalled && !$0.configured && $0.agent != .croc }
    }

    static func presentConfigurationIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: configuredKey), hasUnconfiguredInstalledIntegrations else { return }
        UserDefaults.standard.set(true, forKey: configuredKey)
        presentConfiguration(isFirstRun: true)
    }

    static func presentConfiguration(isFirstRun: Bool = false) {
        if windowController == nil {
            windowController = IntegrationWindowController()
        }
        windowController?.show(isFirstRun: isFirstRun)
    }

    static func configure(_ agent: AgentKind) {
        switch agent {
        case .pi:
            installResource(name: "hold-my-lid-pi", extension: "ts", destination: destination(for: agent))
        case .openCode:
            installResource(name: "hold-my-lid-opencode", extension: "js", destination: destination(for: agent))
        case .antigravity:
            let root = destination(for: agent)
            installResource(name: "antigravity-plugin", extension: "json", destination: root.appendingPathComponent("plugin.json"))
            installResource(name: "antigravity-hooks", extension: "json", destination: root.appendingPathComponent("hooks.json"))
            installResource(name: "hold-my-lid-antigravity", extension: "py", destination: root.appendingPathComponent("hold-my-lid-antigravity.py"))
        case .claude:
            configureClaudeHooks()
        case .cursor:
            configureCursorRule()
        case .codex, .croc:
            break
        }
        NotificationCenter.default.post(name: .integrationConfigurationDidChange, object: nil)
    }

    private static func destination(for agent: AgentKind) -> URL {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        switch agent {
        case .pi: return home.appendingPathComponent(".pi/agent/extensions/hold-my-lid.ts")
        case .openCode: return home.appendingPathComponent(".config/opencode/plugins/hold-my-lid.js")
        case .antigravity: return home.appendingPathComponent(".gemini/config/plugins/hold-my-lid-antigravity", isDirectory: true)
        case .claude: return home.appendingPathComponent(".claude/settings.json")
        case .cursor: return home.appendingPathComponent(".cursor/rules/wake-my-mac.mdc")
        case .codex: return home.appendingPathComponent("Library/Application Support/StayRunning/Codex integration")
        case .croc: return home.appendingPathComponent(".config/wake-my-mac/croc (detection only)")
        }
    }

    private static func capability(for agent: AgentKind) -> String {
        switch agent {
        case .claude: "User hooks · SessionStart / Stop / SessionEnd"
        case .cursor: "User rule · process detection fallback"
        case .croc: "Utility CLI · detection only"
        case .codex: "Built-in rollout monitoring"
        case .pi, .openCode, .antigravity: "Native extension / hook adapter"
        }
    }

    private static func isConfigured(_ agent: AgentKind) -> Bool {
        let destination = destination(for: agent)
        switch agent {
        case .claude:
            guard let data = try? Data(contentsOf: destination), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let hooks = object["hooks"] as? [String: Any] else { return false }
            return hooks["SessionStart"] != nil && hooks["Stop"] != nil
        case .croc, .codex:
            return true
        default:
            return FileManager.default.fileExists(atPath: destination.path)
        }
    }

    private static func configureClaudeHooks() {
        let file = destination(for: .claude)
        var object: [String: Any] = [:]
        if let data = try? Data(contentsOf: file), let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { object = existing }
        let script = installResource(name: "hold-my-lid-claude", extension: "sh", destination: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".claude/hooks/hold-my-lid-claude.sh"))
        guard script else { return }
        let command = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".claude/hooks/hold-my-lid-claude.sh").path
        var hooks = object["hooks"] as? [String: Any] ?? [:]
        for event in ["SessionStart", "Stop", "SessionEnd"] {
            var groups = hooks[event] as? [[String: Any]] ?? []
            let alreadyAdded = groups.contains { group in
                (group["hooks"] as? [[String: Any]])?.contains { ($0["command"] as? String) == command } == true
            }
            if !alreadyAdded { groups.append(["hooks": [["type": "command", "command": command]]]) }
            hooks[event] = groups
        }
        object["hooks"] = hooks
        writeJSON(object, to: file)
    }

    private static func configureCursorRule() {
        let file = destination(for: .cursor)
        let contents = """
        # StayRunning integration
        # This rule is informational only; StayRunning detects cursor-agent through PATH and process state.
        Keep long-running work visible while Cursor Agent is active. Do not terminate the agent process just because a turn is waiting for input.
        """
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try contents.data(using: .utf8)?.write(to: file, options: .atomic)
        } catch { }
    }

    @discardableResult
    private static func installResource(name: String, extension ext: String, destination: URL) -> Bool {
        guard let source = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Integrations"), let data = try? Data(contentsOf: source) else { return false }
        if (try? Data(contentsOf: destination)) == data { return true }
        do {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: destination, options: .atomic)
            if ext == "sh" { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path) }
            return true
        } catch { return false }
    }

    private static func writeJSON(_ object: [String: Any], to url: URL) {
        guard JSONSerialization.isValidJSONObject(object), let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch { }
    }
}

extension Notification.Name {
    static let integrationConfigurationDidChange = Notification.Name("integrationConfigurationDidChange")
}

@MainActor
private final class IntegrationWindowController: NSWindowController {
    private let hostingController: NSHostingController<IntegrationSetupView>

    init() {
        hostingController = NSHostingController(rootView: IntegrationSetupView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Agent integrations"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 620, height: 520))
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func show(isFirstRun: Bool) {
        hostingController.rootView = IntegrationSetupView(isFirstRun: isFirstRun)
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct IntegrationSetupView: View {
    var isFirstRun = false
    @State private var statuses = IntegrationInstaller.statuses()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(isFirstRun ? "Set up agent integrations" : "Agent integrations")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("StayRunning only watches tools you already have installed. Nothing is downloaded or installed here.")
                    .foregroundStyle(.secondary)
            }
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(statuses) { status in
                        IntegrationCard(status: status) {
                            IntegrationInstaller.configure(status.agent)
                            statuses = IntegrationInstaller.statuses()
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button("Refresh") { statuses = IntegrationInstaller.statuses() }
                    .buttonStyle(.bordered)
                Button("Done") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 620, minHeight: 520)
    }
}

private struct IntegrationCard: View {
    let status: IntegrationStatus
    let configure: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AgentBrandIcon(agent: status.agent)
                .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(status.agent.rawValue).font(.headline)
                Text(status.isInstalled ? (status.executablePath ?? "Installed app") : "Not installed")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(status.capability).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if status.isInstalled && status.agent != .croc && status.agent != .codex {
                Button(status.configured ? "Configured" : "Configure", action: configure)
                    .buttonStyle(.borderedProminent)
                    .disabled(status.configured)
            } else {
                Text(status.isInstalled ? "Detected" : "Unavailable")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
    }
}
