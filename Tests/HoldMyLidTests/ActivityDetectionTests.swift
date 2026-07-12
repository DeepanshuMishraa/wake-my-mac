import Foundation
import Testing
@testable import WatchMyMac

struct ActivityDetectionTests {
    @Test func codexTransitionsFromWorkingToIdle() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("rollout-test.jsonl")
        try event("task_started", at: "2026-07-11T12:00:00Z").write(to: file, atomically: true, encoding: .utf8)

        let monitor = CodexRolloutMonitor(root: root)
        #expect(monitor.scan().first?.status == .working)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(event("task_complete", at: "2026-07-11T12:00:01Z").utf8))
        try handle.close()
        #expect(monitor.scan().first?.status == .idle)
    }

    @Test func codexAbortEndsWorkAndConcurrentFileRemainsWorking() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("rollout-first.jsonl")
        let second = root.appendingPathComponent("rollout-second.jsonl")
        try (event("task_started", at: "2026-07-11T12:00:00.125Z") + event("turn_aborted", at: "2026-07-11T12:00:01.250Z"))
            .write(to: first, atomically: true, encoding: .utf8)
        try event("task_started", at: "2026-07-11T12:00:02.500Z")
            .write(to: second, atomically: true, encoding: .utf8)

        let sessions = CodexRolloutMonitor(root: root).scan()
        #expect(sessions.filter { $0.status == .idle }.count == 1)
        #expect(sessions.filter { $0.status == .working }.count == 1)
    }

    @Test func opencodeServeIsInfrastructureOnly() {
        #expect(AgentKind.openCode.shouldIgnoreProcess(arguments: "opencode serve --port 64722"))
        #expect(AgentKind.openCode.shouldIgnoreProcess(arguments: "serve --port 64722"))
        #expect(!AgentKind.openCode.shouldIgnoreProcess(arguments: "opencode"))
    }

    @Test func resumedWorkCancelsPendingDisplaySleep() async throws {
        final class Counter: @unchecked Sendable {
            private let lock = NSLock()
            private var value = 0
            func increment() { lock.withLock { value += 1 } }
            func read() -> Int { lock.withLock { value } }
        }

        let counter = Counter()
        let manager = DisplayManager { counter.increment() }
        manager.turnDisplayOffAfter(seconds: 1)
        #expect(manager.hasPendingDisplayOff)

        manager.cancelPendingDisplayOff()
        #expect(!manager.hasPendingDisplayOff)
        try await Task.sleep(for: .seconds(1.2))
        #expect(counter.read() == 0)
    }

    @Test func rowDistinguishesBlockedWorkingIdleAndStopped() {
        let working = session(.working, source: "adapter")
        let blocked = session(.blocked, source: "adapter")
        let process = session(.idle, source: "process")
        #expect(AgentRow(agent: .pi, sessions: [working]).statusText == "working")
        #expect(AgentRow(agent: .pi, sessions: [blocked]).statusText == "needs input")
        #expect(AgentRow(agent: .pi, sessions: [process]).statusText == "idle")
        #expect(AgentRow(agent: .pi, sessions: []).statusText == "not running")
    }

    @Test func holdModesHaveIndependentPolicies() {
        #expect(!HoldPolicy.shouldHold(mode: .agents, isEnabled: true, engagedAgentCount: 0))
        #expect(HoldPolicy.shouldHold(mode: .agents, isEnabled: true, engagedAgentCount: 1))
        #expect(HoldPolicy.shouldHold(mode: .ssh, isEnabled: true, engagedAgentCount: 0))
        #expect(HoldPolicy.shouldHold(mode: .manual, isEnabled: true, engagedAgentCount: 0))
        #expect(HoldPolicy.shouldHold(mode: .agents, isEnabled: true, engagedAgentCount: 0, activityMatchCount: 1))
        for mode in HoldMode.allCases {
            #expect(!HoldPolicy.shouldHold(mode: mode, isEnabled: false, engagedAgentCount: 99))
        }
    }

    @MainActor @Test func historyRecordsReasonsDurationAndBatteryWithoutPrivateDetails() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("history-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SessionHistoryStore(fileURL: file)
        let start = Date(timeIntervalSince1970: 1_000)
        store.update(isHolding: true, reasons: ["Compiling"], agents: ["Codex"], battery: 80, now: start)
        store.update(isHolding: false, reasons: [], agents: [], battery: 76, now: start.addingTimeInterval(600))
        #expect(store.sessions.count == 1)
        #expect(store.sessions[0].duration == 600)
        #expect(store.sessions[0].batteryUsed == 4)
        #expect(store.sessions[0].reasons == ["Compiling"])
        #expect(store.sessions[0].agents == ["Codex"])
    }

    @MainActor @Test func reasonChangeCreatesAccurateHistorySegments() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("history-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SessionHistoryStore(fileURL: file)
        let start = Date(timeIntervalSince1970: 1_000)
        store.update(isHolding: true, reasons: ["Compiling"], agents: [], battery: 90, now: start)
        store.update(isHolding: true, reasons: ["SSH mode"], agents: [], battery: 88, now: start.addingTimeInterval(300))
        store.update(isHolding: false, reasons: [], agents: [], battery: 87, now: start.addingTimeInterval(600))
        #expect(store.sessions.count == 2)
        #expect(store.sessions[1].reasons == ["Compiling"])
        #expect(store.sessions[1].duration(at: start.addingTimeInterval(600)) == 300)
        #expect(store.sessions[0].reasons == ["SSH mode"])
        #expect(store.sessions[0].batteryUsed == 1)
    }

    @MainActor @Test func activeSessionReportsLiveBatteryChange() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("history-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = SessionHistoryStore(fileURL: file)
        let start = Date(timeIntervalSince1970: 1_000)
        store.update(isHolding: true, reasons: ["Rendering"], agents: [], battery: 70, now: start)
        store.update(isHolding: true, reasons: ["Rendering"], agents: [], battery: 67, now: start.addingTimeInterval(300))
        #expect(store.sessions[0].endedAt == nil)
        #expect(store.sessions[0].batteryUsed == 3)
    }

    @Test func dailyMetricsSplitSessionsAtMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = ISO8601DateFormatter().date(from: "2026-07-12T23:30:00Z")!
        let end = start.addingTimeInterval(60 * 60)
        let session = WakeSession(id: UUID(), startedAt: start, endedAt: end, reasons: ["Compiling"], agents: [], startingBatteryPercent: 80, endingBatteryPercent: 76)
        let metrics = DashboardAnalytics.dailyMetrics(sessions: [session], from: start, through: end, calendar: calendar)
        #expect(metrics.count == 2)
        #expect(metrics[0].awakeSeconds == 1_800)
        #expect(metrics[1].awakeSeconds == 1_800)
        #expect(metrics[0].batteryPoints == 2)
        #expect(metrics[1].batteryPoints == 2)
    }

    @Test func rangeBatteryTotalUsesCompletedHistoryNotOnlyToday() {
        let start = Date(timeIntervalSince1970: 1_000)
        let sessions = [
            WakeSession(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(900), reasons: ["Agent activity"], agents: ["Codex"], startingBatteryPercent: 35, endingBatteryPercent: 31),
            WakeSession(id: UUID(), startedAt: start.addingTimeInterval(1_000), endedAt: start.addingTimeInterval(2_200), reasons: ["Agent activity"], agents: ["Codex"], startingBatteryPercent: 31, endingBatteryPercent: 29)
        ]
        let metrics = DashboardAnalytics.dailyMetrics(sessions: sessions, from: start, through: start.addingTimeInterval(3_000))
        #expect(metrics.reduce(0) { $0 + $1.batteryPoints } == 6)
        #expect(metrics.reduce(0) { $0 + $1.awakeSeconds } == 2_100)
    }

    @Test func reasonMetricsDoNotDoubleCountConcurrentReasons() {
        let start = Date(timeIntervalSince1970: 1_000)
        let session = WakeSession(id: UUID(), startedAt: start, endedAt: start.addingTimeInterval(600), reasons: ["Compiling", "Agent activity"], agents: [], startingBatteryPercent: 80, endingBatteryPercent: 78)
        let metrics = DashboardAnalytics.reasonMetrics(sessions: [session], now: start.addingTimeInterval(600))
        #expect(metrics.reduce(0) { $0 + $1.awakeSeconds } == 600)
        #expect(metrics.allSatisfy { $0.awakeSeconds == 300 })
    }

    @Test func activityRulesUseExactProcessAndApplicationIdentity() {
        let snapshot = ActivityProcessSnapshot(
            executableNames: ["swiftc-helper", "swiftc", "curl-helper"],
            runningApplicationPaths: ["/Applications/Final Cut Pro.app"]
        )
        let monitor = ActivityRuleMonitor { snapshot }
        var rules = ActivityRule.defaults
        rules[rules.firstIndex { $0.kind == .compiling }!].isEnabled = true
        let selected = rules.firstIndex { $0.kind == .selectedApps }!
        rules[selected].isEnabled = true
        rules[selected].selectedApplicationPaths = ["/Applications/Final Cut Pro.app", "/Applications/Cut.app"]
        let matches = monitor.scan(rules: rules)
        #expect(matches.contains { $0.kind == .compiling && $0.processName == "swiftc" })
        #expect(matches.contains { $0.kind == .selectedApps && $0.processName == "Final Cut Pro" })
        #expect(!matches.contains { $0.processName == "Cut" })
    }

    @Test func stalePidlessAdapterCannotBecomeGhostAgent() {
        let now = Date(timeIntervalSince1970: 10_000)
        let stale = AgentSession(id: "ghost", agent: .antigravity, title: "Antigravity", status: .working, lastUpdated: now.addingTimeInterval(-60), pid: nil, source: "antigravity-adapter", sequence: 1, deepLink: nil)
        #expect(SessionLiveness.shouldTreatAsIdle(stale, hasMatchingProcess: false, now: now))
        #expect(!SessionLiveness.shouldTreatAsIdle(stale, hasMatchingProcess: true, now: now))

        var fresh = stale
        fresh.lastUpdated = now.addingTimeInterval(-5)
        #expect(!SessionLiveness.shouldTreatAsIdle(fresh, hasMatchingProcess: false, now: now))
    }

    @Test func settingsRoundTripPersistsModeAndMasterSwitch() throws {
        var settings = HoldSettings()
        settings.mode = .ssh
        settings.isEnabled = false
        let decoded = try JSONDecoder().decode(HoldSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    @Test func legacySettingsDecodeWithModeDefaults() throws {
        let legacy = #"{"batteryCutoffPercent":25,"onlyWhenPluggedIn":true,"respectLowPowerMode":false,"turnDisplayOffOnLidClose":true,"turnDisplayOffAfterFinishSeconds":20,"notificationsEnabled":false,"soundName":"Ping"}"#
        let settings = try JSONDecoder().decode(HoldSettings.self, from: Data(legacy.utf8))
        #expect(settings.mode == .agents)
        #expect(settings.isEnabled)
        #expect(settings.batteryCutoffPercent == 25)
    }

    @Test func codexRetriesPartialTrailingEvent() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("rollout-partial.jsonl")
        try event("task_started", at: "2026-07-11T12:00:00Z").write(to: file, atomically: true, encoding: .utf8)
        let monitor = CodexRolloutMonitor(root: root)
        #expect(monitor.scan().first?.status == .working)

        let complete = event("task_complete", at: "2026-07-11T12:00:01Z")
        let split = complete.index(complete.startIndex, offsetBy: complete.count / 2)
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(complete[..<split].utf8))
        #expect(monitor.scan().first?.status == .working)
        try handle.write(contentsOf: Data(complete[split...].utf8))
        try handle.close()
        #expect(monitor.scan().first?.status == .idle)
    }

    private func event(_ type: String, at timestamp: String) -> String {
        "{\"timestamp\":\"\(timestamp)\",\"type\":\"event_msg\",\"payload\":{\"type\":\"\(type)\"}}\n"
    }

    private func session(_ status: AgentStatus, source: String) -> AgentSession {
        AgentSession(id: UUID().uuidString, agent: .pi, title: "Pi", status: status, lastUpdated: Date(), pid: 1, source: source, sequence: 1, deepLink: nil)
    }
}
