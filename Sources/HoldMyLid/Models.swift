import Foundation

enum AgentKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case codex = "Codex"
    case openCode = "OpenCode"
    case pi = "Pi"
    case antigravity = "Antigravity"
    case claude = "Claude Code"
    case cursor = "Cursor Agent"
    case croc = "Croc"

    var id: String { rawValue }

    /// Only real agent integrations belong in the menu-bar status surface.
    /// Croc is supported by the setup screen as a detected utility, but it has
    /// no agent lifecycle or hook API and must never appear as an active agent.
    var isMenuVisible: Bool { self != .croc }

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
        case .claude, .cursor, .croc:
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
        case .claude:
            return ["/opt/homebrew/bin/claude", "/usr/local/bin/claude", "\(home)/.local/bin/claude", "\(home)/.bun/bin/claude"]
        case .cursor:
            return ["/opt/homebrew/bin/cursor-agent", "/usr/local/bin/cursor-agent", "\(home)/.local/bin/cursor-agent", "\(home)/.local/bin/cursor"]
        case .croc:
            return ["/opt/homebrew/bin/croc", "/usr/local/bin/croc", "\(home)/.local/bin/croc"]
        }
    }

    var isInstalled: Bool {
        let files = FileManager.default
        return appPaths.contains(where: files.fileExists(atPath:))
            || resolvedExecutablePath != nil
    }

    /// Resolves both conventional install locations and the user's actual shell PATH.
    /// This avoids assuming that Homebrew or npm lives in one fixed directory.
    var resolvedExecutablePath: String? {
        let files = FileManager.default
        let pathEntries = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let candidates = executablePaths + pathEntries.flatMap { directory in
            executableNames.map { URL(fileURLWithPath: directory).appendingPathComponent($0).path }
        }
        return candidates.first { files.isExecutableFile(atPath: $0) }
    }

    private var executableNames: [String] {
        switch self {
        case .codex: ["codex"]
        case .openCode: ["opencode"]
        case .pi: ["pi"]
        case .antigravity: ["antigravity"]
        case .claude: ["claude"]
        case .cursor: ["cursor-agent", "cursor"]
        case .croc: ["croc"]
        }
    }

    var iconAssetPath: String? {
        switch self {
        case .codex:
            let codexIcon = "/Applications/ChatGPT.app/Contents/Resources/icon-codex-dark-color.png"
            return FileManager.default.fileExists(atPath: codexIcon) ? codexIcon : nil
        case .openCode, .antigravity, .pi, .claude, .cursor, .croc:
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
        case .claude:
            darkMode ? "claude-dark" : "claude-light"
        case .cursor:
            darkMode ? "cursor-dark" : "cursor-light"
        case .croc:
            "croc"
        }
    }

    var brandMark: String {
        switch self {
        case .codex: "◉"
        case .openCode: "OC"
        case .pi: "π"
        case .antigravity: "A"
        case .claude: "C"
        case .cursor: "⌁"
        case .croc: "↗"
        }
    }

    var processHints: [String] {
        switch self {
        case .codex: ["codex", "codex-cli", "ChatGPT.app", "Codex.app"]
        case .openCode: ["opencode", "open-code", "OpenCode.app", "OpenCode Beta.app"]
        case .pi: ["pi-coding-agent", "@earendil-works/pi", "/bin/pi"]
        case .antigravity: ["antigravity", "Antigravity.app"]
        case .claude: ["claude", "claude-code", "Claude Code"]
        case .cursor: ["cursor-agent", "cursor"]
        case .croc: ["croc"]
        }
    }

    var exactProcessNames: [String] {
        switch self {
        case .codex: ["codex", "ChatGPT", "Codex"]
        case .openCode: ["opencode", "OpenCode"]
        case .pi: ["pi"]
        case .antigravity: ["antigravity", "Antigravity"]
        case .claude: ["claude"]
        case .cursor: ["cursor-agent", "cursor"]
        case .croc: ["croc"]
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
        case .codex, .pi, .antigravity, .claude, .cursor, .croc:
            return false
        }
    }
}

enum AgentStatus: String, Codable, Sendable {
    case working
    case blocked
    case idle
    case absent
}

struct AgentSession: Identifiable, Codable, Equatable, Sendable {
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

struct AgentRow: Identifiable, Equatable, Sendable {
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
        case .agents: "Keeps the Mac awake while a watched agent is working."
        case .ssh: "Keeps the Mac awake and reachable until you change modes or turn it off."
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

    static func shouldStopForLowPowerMode(mode: HoldMode, respectLowPowerMode: Bool, isLowPowerMode: Bool) -> Bool {
        respectLowPowerMode && isLowPowerMode && mode != .ssh
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
