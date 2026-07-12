import AppKit
import Charts
import SwiftUI

private enum DashboardSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case history = "History"
    case rules = "Activity Rules"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: "gauge.with.dots.needle.33percent"
        case .history: "clock.arrow.circlepath"
        case .rules: "bolt.badge.clock"
        }
    }
}

struct DashboardView: View {
    @ObservedObject var state: AppState
    @ObservedObject private var history: SessionHistoryStore
    @State private var selection: DashboardSection? = .overview

    init(state: AppState) {
        self.state = state
        self.history = state.history
    }

    var body: some View {
        NavigationSplitView {
            List(DashboardSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.symbol).tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        } detail: {
            switch selection ?? .overview {
            case .overview: OverviewDashboard(state: state, sessions: history.sessions)
            case .history: HistoryDashboard(history: history)
            case .rules: ActivityRulesDashboard(state: state)
            }
        }
        .frame(minWidth: 780, minHeight: 540)
    }
}

private enum DashboardRange: Int, CaseIterable, Identifiable {
    case today = 1
    case week = 7
    case month = 30

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .today: "Today"
        case .week: "7 Days"
        case .month: "30 Days"
        }
    }
    var context: String { self == .today ? "today" : "last \(rawValue) days" }
    var axisStride: Int { self == .today ? 1 : (self == .week ? 1 : 5) }
}

private struct OverviewDashboard: View {
    @ObservedObject var state: AppState
    let sessions: [WakeSession]
    @State private var selectedRange: DashboardRange = .week

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            content(now: timeline.date)
        }
    }

    private func content(now: Date) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overview").font(.largeTitle.bold())
                        Text(statusText).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        StatusPill(isHolding: isHolding)
                        Picker("Range", selection: $selectedRange) {
                            ForEach(DashboardRange.allCases) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                    }
                }

                let daily = dailyMetrics(now: now)
                let rangeBattery = daily.reduce(0) { $0 + $1.batteryPoints }
                let rangeSessions = recentSessions(now: now)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
                    MetricCard(title: "Awake · \(selectedRange.title)", value: duration(daily.reduce(0) { $0 + $1.awakeSeconds }), symbol: "clock")
                    MetricCard(title: "Sessions · \(selectedRange.title)", value: "\(rangeSessions.count)", symbol: "waveform.path.ecg")
                    MetricCard(title: "Battery used · \(selectedRange.title)", value: rangeBattery > 0 ? "\(rangeBattery.formatted(.number.precision(.fractionLength(0...1))))%" : "—", symbol: "battery.75percent")
                    MetricCard(title: "Active reasons", value: "\(activeReasonCount)", symbol: "bolt.fill")
                }

                VStack(spacing: 14) {
                    AnalyticsCard(title: "Awake time", subtitle: "Minutes kept awake per day", symbol: "chart.bar.xaxis") {
                        Chart(daily) { metric in
                            BarMark(x: .value("Day", metric.day, unit: .day), y: .value("Minutes", metric.awakeSeconds / 60))
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(5)
                                .annotation(position: .top, spacing: 4) {
                                    if metric.awakeSeconds >= 60 {
                                        Text(shortDuration(metric.awakeSeconds))
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        }
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: selectedRange.axisStride)) { AxisGridLine().foregroundStyle(.clear); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in AxisGridLine().foregroundStyle(.quaternary); AxisValueLabel { if let minutes = value.as(Double.self) { Text(axisDuration(minutes: minutes)) } } } }
                    }

                    AnalyticsCard(title: "Battery used", subtitle: "Measured battery percentage drop while awake", symbol: "battery.50percent") {
                        Chart(daily) { metric in
                            BarMark(x: .value("Day", metric.day, unit: .day), y: .value("Battery percent", metric.batteryPoints))
                                .foregroundStyle(Color.mint.gradient)
                                .cornerRadius(5)
                                .annotation(position: .top, spacing: 4) {
                                    if metric.batteryPoints > 0 {
                                        Text("\(metric.batteryPoints.formatted(.number.precision(.fractionLength(0...1))))%")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        }
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: selectedRange.axisStride)) { AxisGridLine().foregroundStyle(.clear); AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { axisValue in AxisGridLine().foregroundStyle(.quaternary); AxisValueLabel { if let value = axisValue.as(Double.self) { Text("\(value.formatted(.number.precision(.fractionLength(0...1))))%") } } } }
                    }

                    AnalyticsCard(title: "Why it stayed awake", subtitle: "Share of attributed time", symbol: "circle.hexagongrid") {
                        let reasons = DashboardAnalytics.reasonMetrics(sessions: recentSessions(now: now), now: now)
                        if reasons.isEmpty {
                            EmptyChart(message: "No wake reasons yet")
                        } else {
                            HStack(spacing: 18) {
                                Chart(reasons.prefix(6)) { metric in
                                    SectorMark(angle: .value("Time", metric.awakeSeconds), innerRadius: .ratio(0.67), angularInset: 2)
                                        .foregroundStyle(by: .value("Reason", metric.name))
                                        .cornerRadius(4)
                                }
                                .chartLegend(.hidden)
                                .frame(width: 150)
                                ChartLegend(metrics: Array(reasons.prefix(5)))
                            }
                        }
                    }

                    AnalyticsCard(title: "Agent contribution", subtitle: "Attributed awake time · \(selectedRange.context)", symbol: "cpu") {
                        let agents = DashboardAnalytics.agentMetrics(sessions: recentSessions(now: now), now: now)
                        if agents.isEmpty {
                            EmptyChart(message: "No agent activity yet")
                        } else {
                            Chart(agents.prefix(6)) { metric in
                                BarMark(x: .value("Hours", metric.awakeSeconds / 3_600), y: .value("Agent", metric.name))
                                    .foregroundStyle(Color.indigo.gradient).cornerRadius(4)
                            }
                            .chartXAxis { AxisMarks(position: .bottom, values: .automatic(desiredCount: 4)) { AxisGridLine().foregroundStyle(.quaternary); AxisValueLabel() } }
                            .chartYAxis { AxisMarks(position: .leading) }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    GroupBox("Currently keeping awake") {
                        VStack(alignment: .leading, spacing: 10) {
                            if currentReasons.isEmpty { Text("Nothing right now").foregroundStyle(.secondary) }
                            ForEach(currentReasons, id: \.self) { reason in Label(reason, systemImage: "checkmark.circle.fill").foregroundStyle(.primary) }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                    }
                    GroupBox("Agents") {
                        VStack(alignment: .leading, spacing: 10) {
                            let active = state.rows.filter { $0.engagedCount > 0 }
                            if active.isEmpty { Text("No agents working").foregroundStyle(.secondary) }
                            ForEach(active) { row in Label(row.agent.rawValue, systemImage: row.blockedCount > 0 ? "exclamationmark.circle.fill" : "circle.fill") }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                    }
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func recentSessions(now: Date) -> [WakeSession] {
        let start = rangeStart(now: now)
        return sessions.filter { ($0.endedAt ?? now) > start && $0.startedAt <= now }
    }
    private func dailyMetrics(now: Date) -> [DailyWakeMetric] {
        DashboardAnalytics.dailyMetrics(sessions: sessions, from: rangeStart(now: now), through: now)
    }
    private func rangeStart(now: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -(selectedRange.rawValue - 1), to: today) ?? today
    }
    private var currentReasons: [String] { sessions.first(where: { $0.endedAt == nil })?.reasons ?? [] }
    private var activeReasonCount: Int { currentReasons.count }
    private var isHolding: Bool {
        if case .holding = state.phase { return true }
        if case .idleCountdown = state.phase { return true }
        return false
    }
    private var statusText: String { isHolding ? "Your Mac is protected and reachable." : "Your Mac can sleep normally." }
}

private struct HistoryDashboard: View {
    @ObservedObject var history: SessionHistoryStore
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session History").font(.largeTitle.bold())
                    Text("Stored only on this Mac. No command contents or destinations are recorded.").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Clear History", role: .destructive) { history.clear() }.disabled(history.sessions.isEmpty)
            }.padding(28)
            List(history.sessions) { session in
                HStack(spacing: 14) {
                    Image(systemName: session.endedAt == nil ? "bolt.circle.fill" : "clock")
                        .font(.title2).foregroundStyle(session.endedAt == nil ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.reasons.isEmpty ? "Wake session" : session.reasons.joined(separator: " · ")).fontWeight(.medium)
                        HStack(spacing: 8) {
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            Text("•")
                            Text(duration(session.duration))
                            if !session.agents.isEmpty { Text("• \(session.agents.joined(separator: ", "))") }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(session.endedAt == nil ? "Live" : "−\(session.batteryUsed)% battery")
                        .font(.callout.monospacedDigit()).foregroundStyle(session.endedAt == nil ? .green : .secondary)
                }.padding(.vertical, 6)
            }.overlay { if history.sessions.isEmpty { ContentUnavailableView("No sessions yet", systemImage: "clock", description: Text("Your wake history will appear here.")) } }
        }
    }
}

private struct ActivityRulesDashboard: View {
    @ObservedObject var state: AppState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Rules").font(.largeTitle.bold())
                    Text("Keep your Mac awake while important work is in progress.").foregroundStyle(.secondary)
                }
                ForEach(state.settings.activityRules) { rule in
                    RuleCard(rule: rule, isActive: state.activityMatches.contains { $0.kind == rule.kind }) { updated in
                        var settings = state.settings
                        if let index = settings.activityRules.firstIndex(where: { $0.kind == updated.kind }) { settings.activityRules[index] = updated }
                        state.updateSettings(settings)
                    }
                }
            }.padding(28)
        }
    }
}

private struct RuleCard: View {
    let rule: ActivityRule
    let isActive: Bool
    let update: (ActivityRule) -> Void
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(rule.kind.title, systemImage: rule.kind.symbol).font(.headline)
                    if isActive { Text("ACTIVE").font(.caption2.bold()).foregroundStyle(.green).padding(.horizontal, 7).padding(.vertical, 3).background(.green.opacity(0.12), in: Capsule()) }
                    Spacer()
                    Toggle("", isOn: Binding(get: { rule.isEnabled }, set: { var copy = rule; copy.isEnabled = $0; update(copy) })).labelsHidden()
                }
                if rule.kind == .selectedApps {
                    HStack {
                        Text(rule.selectedApplicationPaths.isEmpty ? "No applications selected" : rule.selectedApplicationPaths.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }.joined(separator: ", "))
                            .foregroundStyle(.secondary).lineLimit(2)
                        Spacer()
                        Button("Choose Apps…", action: chooseApps)
                    }
                } else {
                    Text("Automatically detects common \(rule.kind.title.lowercased()) tools without recording command contents.").foregroundStyle(.secondary)
                }
            }.padding(8)
        }
    }
    private func chooseApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK else { return }
        var copy = rule
        copy.selectedApplicationPaths = panel.urls.map(\.path)
        copy.isEnabled = true
        update(copy)
    }
}

private struct MetricCard: View {
    let title: String, value: String, symbol: String
    var body: some View {
        GroupBox { HStack { VStack(alignment: .leading, spacing: 7) { Text(title).foregroundStyle(.secondary); Text(value).font(.title2.bold()).monospacedDigit() }; Spacer(); Image(systemName: symbol).font(.title2).foregroundStyle(.blue) }.padding(8) }
    }
}

private struct AnalyticsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            content
                .frame(maxWidth: .infinity, minHeight: 225, maxHeight: 225)
                .padding(.top, 8)
        } label: {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: symbol).foregroundStyle(.secondary).frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private struct ChartLegend: View {
    let metrics: [CategoryWakeMetric]
    private let colors: [Color] = [.blue, .purple, .mint, .orange, .pink]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                HStack(spacing: 8) {
                    Circle().fill(colors[index % colors.count]).frame(width: 7, height: 7)
                    Text(metric.name).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(duration(metric.awakeSeconds)).monospacedDigit().foregroundStyle(.secondary)
                }.font(.caption)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyChart: View {
    let message: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line").font(.title2).foregroundStyle(.tertiary)
            Text(message).font(.callout).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatusPill: View {
    let isHolding: Bool
    var body: some View { Label(isHolding ? "Awake" : "Ready to sleep", systemImage: isHolding ? "bolt.fill" : "moon.fill").font(.callout.weight(.semibold)).foregroundStyle(isHolding ? .green : .secondary).padding(.horizontal, 12).padding(.vertical, 7).background(.quaternary, in: Capsule()) }
}

private func duration(_ interval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: max(0, interval)) ?? "0m"
}

private func shortDuration(_ interval: TimeInterval) -> String {
    let minutes = Int((interval / 60).rounded())
    if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
    return "\(minutes)m"
}

private func axisDuration(minutes: Double) -> String {
    if minutes >= 60 { return "\((minutes / 60).formatted(.number.precision(.fractionLength(0...1))))h" }
    return "\(Int(minutes.rounded()))m"
}
