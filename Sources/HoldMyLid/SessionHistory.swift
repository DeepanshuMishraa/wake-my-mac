import Foundation

struct WakeSession: Identifiable, Codable, Equatable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var reasons: [String]
    var agents: [String]
    var startingBatteryPercent: Int
    var endingBatteryPercent: Int?

    var duration: TimeInterval { duration(at: Date()) }
    func duration(at now: Date) -> TimeInterval { max(0, (endedAt ?? now).timeIntervalSince(startedAt)) }
    var batteryUsed: Int { max(0, startingBatteryPercent - (endingBatteryPercent ?? startingBatteryPercent)) }
}

@MainActor
final class SessionHistoryStore: ObservableObject {
    @Published private(set) var sessions: [WakeSession] = []
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.fileURL = fileURL ?? base.appendingPathComponent("Hold My Lid/history.json")
        load()
    }

    func update(isHolding: Bool, reasons: [String], agents: [String], battery: Int, now: Date = Date()) {
        var changed = false
        if isHolding {
            if let index = sessions.firstIndex(where: { $0.endedAt == nil }) {
                let normalizedReasons = Array(Set(reasons)).sorted()
                let normalizedAgents = Array(Set(agents)).sorted()
                if sessions[index].reasons != normalizedReasons || sessions[index].agents != normalizedAgents {
                    sessions[index].endedAt = now
                    sessions[index].endingBatteryPercent = battery
                    sessions.insert(WakeSession(id: UUID(), startedAt: now, reasons: normalizedReasons, agents: normalizedAgents, startingBatteryPercent: battery, endingBatteryPercent: battery), at: 0)
                    changed = true
                } else if sessions[index].endingBatteryPercent != battery {
                    sessions[index].endingBatteryPercent = battery
                    changed = true
                }
            } else {
                sessions.insert(WakeSession(id: UUID(), startedAt: now, reasons: reasons, agents: agents, startingBatteryPercent: battery, endingBatteryPercent: battery), at: 0)
                changed = true
            }
        } else if let index = sessions.firstIndex(where: { $0.endedAt == nil }) {
            sessions[index].endedAt = now
            sessions[index].endingBatteryPercent = battery
            changed = true
        }
        if sessions.count > 1_000 { sessions.removeLast(sessions.count - 1_000); changed = true }
        if changed { save() }
    }

    func clear() {
        sessions.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode([WakeSession].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
