import Foundation

enum AgentKind: String, CaseIterable, Identifiable, Codable {
    case codex = "Codex"
    case openCode = "OpenCode"
    case pi = "Pi"
    case antigravity = "Antigravity"

    var id: String { rawValue }

    var appPaths: [String] {
        switch self {
        case .codex:
            ["/Applications/ChatGPT.app", "/Applications/Codex.app"]
        case .openCode:
            ["/Applications/OpenCode.app", "/Applications/OpenCode Beta.app"]
        case .antigravity:
            ["/Applications/Antigravity.app"]
        case .pi:
            []
        }
    }

    var executablePaths: [String] {
        let home = NSHomeDirectory()
        switch self {
        case .codex:
            return ["/Applications/ChatGPT.app/Contents/Resources/codex", "/opt/homebrew/bin/codex", "/usr/local/bin/codex", "\(home)/.local/bin/codex"]
        case .openCode:
            return ["/opt/homebrew/bin/opencode", "/usr/local/bin/opencode", "\(home)/.local/bin/opencode", "\(home)/.bun/bin/opencode"]
        case .pi:
            return ["/opt/homebrew/bin/pi", "/usr/local/bin/pi", "\(home)/.local/bin/pi", "\(home)/.bun/bin/pi"]
        case .antigravity:
            return ["/opt/homebrew/bin/antigravity", "/usr/local/bin/antigravity", "\(home)/.local/bin/antigravity"]
        }
    }

    var isInstalled: Bool {
        let files = FileManager.default
        return appPaths.contains(where: files.fileExists(atPath:))
            || executablePaths.contains(where: files.isExecutableFile(atPath:))
    }

    var iconAssetPath: String? {
        switch self {
        case .codex:
            let codexIcon = "/Applications/ChatGPT.app/Contents/Resources/icon-codex-dark-color.png"
            return FileManager.default.fileExists(atPath: codexIcon) ? codexIcon : nil
        case .openCode, .antigravity, .pi:
            return nil
        }
    }

    func bundledIconName(darkMode: Bool) -> String? {
        switch self {
        case .pi:
            darkMode ? "pi-dark" : "pi-light"
        case .openCode:
            darkMode ? "opencode-dark" : "opencode-light"
        case .antigravity:
            "antigravity"
        case .codex:
            nil
        }
    }

    var brandMark: String {
        switch self {
        case .codex: "◉"
        case .openCode: "OC"
        case .pi: "π"
        case .antigravity: "A"
        }
    }

    var processHints: [String] {
        switch self {
        case .codex: ["codex", "codex-cli", "ChatGPT.app", "Codex.app"]
        case .openCode: ["opencode", "open-code", "OpenCode.app", "OpenCode Beta.app"]
        case .pi: ["pi-coding-agent", "@earendil-works/pi", "/bin/pi"]
        case .antigravity: ["antigravity", "Antigravity.app"]
        }
    }

    var exactProcessNames: [String] {
        switch self {
        case .codex: ["codex", "ChatGPT", "Codex"]
        case .openCode: ["opencode", "OpenCode"]
        case .pi: ["pi"]
        case .antigravity: ["antigravity", "Antigravity"]
        }
    }

    func shouldIgnoreProcess(arguments: String) -> Bool {
        switch self {
        case .openCode:
            let normalized = arguments.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.lowercased().hasPrefix("serve ")
                || normalized.caseInsensitiveCompare("serve") == .orderedSame
                || normalized.range(
                of: #"(?:^|/)opencode\s+serve(?:\s|$)"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
        case .codex, .pi, .antigravity:
            return false
        }
    }
}

enum AgentStatus: String, Codable {
    case working
    case blocked
    case idle
    case absent
}

struct AgentSession: Identifiable, Codable, Equatable {
    var id: String
    var agent: AgentKind
    var title: String
    var status: AgentStatus
    var lastUpdated: Date
    var pid: Int?
    var source: String
    var sequence: Int64?
    var deepLink: String?
}

struct AgentRow: Identifiable, Equatable {
    var id: AgentKind { agent }
    var agent: AgentKind
    var sessions: [AgentSession]

    var activeCount: Int {
        sessions.filter { $0.status == .working }.count
    }

    var blockedCount: Int {
        sessions.filter { $0.status == .blocked }.count
    }

    var engagedCount: Int { activeCount + blockedCount }

    var isInstalledOrSeen: Bool {
        agent.isInstalled
    }

    var isRunning: Bool {
        engagedCount > 0 || sessions.contains { $0.source == "process" }
    }

    var statusText: String {
        if blockedCount > 0 {
            return blockedCount == 1 ? "needs input" : "\(blockedCount) need input"
        }
        if activeCount > 0 {
            return activeCount == 1 ? "working" : "\(activeCount) working"
        }
        return isRunning ? "idle" : "not running"
    }
}

struct BatterySnapshot: Equatable {
    var percent: Int
    var isCharging: Bool
    var isPluggedIn: Bool
    var isLowPowerMode: Bool

    static let unknown = BatterySnapshot(percent: 100, isCharging: false, isPluggedIn: true, isLowPowerMode: false)
}

struct HoldSettings: Codable, Equatable {
    var batteryCutoffPercent: Int = 15
    var onlyWhenPluggedIn: Bool = false
    var respectLowPowerMode: Bool = true
    var turnDisplayOffOnLidClose: Bool = true
    var turnDisplayOffAfterFinishSeconds: Int = 30
    var notificationsEnabled: Bool = true
    var soundName: String = "Glass"
    var mode: HoldMode = .agents
    var isEnabled: Bool = true
    var activityRules: [ActivityRule] = ActivityRule.defaults

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        batteryCutoffPercent = try values.decodeIfPresent(Int.self, forKey: .batteryCutoffPercent) ?? 15
        onlyWhenPluggedIn = try values.decodeIfPresent(Bool.self, forKey: .onlyWhenPluggedIn) ?? false
        respectLowPowerMode = try values.decodeIfPresent(Bool.self, forKey: .respectLowPowerMode) ?? true
        turnDisplayOffOnLidClose = try values.decodeIfPresent(Bool.self, forKey: .turnDisplayOffOnLidClose) ?? true
        turnDisplayOffAfterFinishSeconds = try values.decodeIfPresent(Int.self, forKey: .turnDisplayOffAfterFinishSeconds) ?? 30
        notificationsEnabled = try values.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        soundName = try values.decodeIfPresent(String.self, forKey: .soundName) ?? "Glass"
        mode = try values.decodeIfPresent(HoldMode.self, forKey: .mode) ?? .agents
        isEnabled = try values.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        activityRules = try values.decodeIfPresent([ActivityRule].self, forKey: .activityRules) ?? ActivityRule.defaults
    }
}

enum HoldMode: String, CaseIterable, Identifiable, Codable {
    case agents
    case ssh
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .agents: "Agents"
        case .ssh: "SSH"
        case .manual: "Manual"
        }
    }

    var explanation: String {
        switch self {
        case .agents: "Keeps the Mac reachable while a watched agent is working."
        case .ssh: "Keeps the Mac and network awake continuously for remote access while allowing the display to sleep and lock."
        case .manual: "Keeps the Mac awake until you turn Wake My Mac off."
        }
    }
}

struct HoldPolicy {
    static func shouldHold(mode: HoldMode, isEnabled: Bool, engagedAgentCount: Int, activityMatchCount: Int = 0) -> Bool {
        guard isEnabled else { return false }
        return switch mode {
        case .agents: engagedAgentCount > 0 || activityMatchCount > 0
        case .ssh, .manual: true
        }
    }
}

enum HoldPhase: Equatable {
    case disabled
    case paused(until: Date)
    case guarded(String)
    case idleCountdown(secondsLeft: Int)
    case holding

    var headline: String {
        switch self {
        case .disabled: "Off"
        case .paused: "Paused"
        case .guarded: "Blocked"
        case .idleCountdown: "Finishing"
        case .holding: "Awake"
        }
    }
}
