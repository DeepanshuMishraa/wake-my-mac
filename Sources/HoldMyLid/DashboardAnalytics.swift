import Foundation

struct DailyWakeMetric: Identifiable, Equatable {
    var id: Date { day }
    var day: Date
    var awakeSeconds: TimeInterval
    var batteryPoints: Double
    var segmentCount: Int
}

struct CategoryWakeMetric: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var awakeSeconds: TimeInterval
    var batteryPoints: Double
}

enum DashboardAnalytics {
    static func dailyMetrics(
        sessions: [WakeSession],
        from start: Date,
        through end: Date,
        calendar: Calendar = .current
    ) -> [DailyWakeMetric] {
        let firstDay = calendar.startOfDay(for: start)
        let lastDay = calendar.startOfDay(for: end)
        var values: [Date: DailyWakeMetric] = [:]
        var day = firstDay
        while day <= lastDay {
            values[day] = DailyWakeMetric(day: day, awakeSeconds: 0, batteryPoints: 0, segmentCount: 0)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        for session in sessions {
            let sessionEnd = min(session.endedAt ?? end, end)
            let sessionStart = max(session.startedAt, start)
            guard sessionEnd > sessionStart else { continue }
            let totalDuration = max(1, (session.endedAt ?? end).timeIntervalSince(session.startedAt))
            var cursor = sessionStart
            while cursor < sessionEnd {
                let bucketDay = calendar.startOfDay(for: cursor)
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: bucketDay) else { break }
                let sliceEnd = min(nextDay, sessionEnd)
                let seconds = sliceEnd.timeIntervalSince(cursor)
                if values[bucketDay] != nil {
                    values[bucketDay]!.awakeSeconds += seconds
                    values[bucketDay]!.batteryPoints += Double(session.batteryUsed) * (seconds / totalDuration)
                    values[bucketDay]!.segmentCount += 1
                }
                cursor = sliceEnd
            }
        }
        return values.values.sorted { $0.day < $1.day }
    }

    static func reasonMetrics(sessions: [WakeSession], now: Date = Date()) -> [CategoryWakeMetric] {
        aggregate(sessions: sessions, now: now) { $0.reasons.isEmpty ? ["Other"] : $0.reasons }
    }

    static func agentMetrics(sessions: [WakeSession], now: Date = Date()) -> [CategoryWakeMetric] {
        aggregate(sessions: sessions, now: now) { $0.agents }
    }

    private static func aggregate(
        sessions: [WakeSession],
        now: Date,
        names: (WakeSession) -> [String]
    ) -> [CategoryWakeMetric] {
        var totals: [String: CategoryWakeMetric] = [:]
        for session in sessions {
            let labels = names(session)
            guard !labels.isEmpty else { continue }
            // A segment may have multiple simultaneous causes. Split its duration
            // evenly so category totals never exceed the real awake duration.
            let share = 1 / Double(labels.count)
            for label in labels {
                var metric = totals[label] ?? CategoryWakeMetric(name: label, awakeSeconds: 0, batteryPoints: 0)
                metric.awakeSeconds += session.duration(at: now) * share
                metric.batteryPoints += Double(session.batteryUsed) * share
                totals[label] = metric
            }
        }
        return totals.values.sorted { $0.awakeSeconds > $1.awakeSeconds }
    }
}
