import AppKit
import SwiftUI
import SwiftUICharts

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case history = "History"
    case rules = "Activity Rules"
    case settings = "Settings"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: "gauge.with.dots.needle.33percent"
        case .history: "clock.arrow.circlepath"
        case .rules: "bolt.badge.clock"
        case .settings: "gearshape"
        }
    }
}

@MainActor
final class DashboardNavigation: ObservableObject {
    @Published var selection: DashboardSection = .overview
}

struct DashboardView: View {
    @ObservedObject var state: AppState
    @ObservedObject private var history: SessionHistoryStore
    @ObservedObject private var navigation: DashboardNavigation

    init(state: AppState, navigation: DashboardNavigation = DashboardNavigation()) {
        self.state = state
        self.history = state.history
        self.navigation = navigation
    }

    var body: some View {
        HStack(spacing: 0) {
            DashboardSidebar(selection: $navigation.selection)
            switch navigation.selection {
            case .overview: OverviewDashboard(state: state, sessions: history.sessions)
            case .history: HistoryDashboard(history: history)
            case .rules: ActivityRulesDashboard(state: state)
            case .settings: SettingsDashboard(state: state)
            }
        }
        .background(DashboardPalette.canvas)
        .frame(minWidth: 980, minHeight: 620)
    }
}

private enum DashboardPalette {
    static let canvas = Color(red: 255/255, green: 241/255, blue: 223/255)
    static let sidebar = Color(red: 244/255, green: 225/255, blue: 205/255)
    static let card = Color(red: 252/255, green: 252/255, blue: 250/255)
    static let ink = Color(red: 41/255, green: 37/255, blue: 36/255)
    static let secondary = Color(red: 112/255, green: 95/255, blue: 84/255)
    static let lime = Color(red: 217/255, green: 255/255, blue: 84/255)
    static let blue = Color(red: 138/255, green: 158/255, blue: 228/255)
    static let border = Color(red: 41/255, green: 37/255, blue: 36/255).opacity(0.17)
}

private struct DashboardSidebar: View {
    @Binding var selection: DashboardSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DashboardPalette.ink)
                    .frame(width: 42, height: 42)
                    .overlay {
                        Capsule().fill(DashboardPalette.lime).frame(width: 20, height: 6)
                    }
                Text("Wake My Mac").font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
            }
            .padding(.horizontal, 23)
            .padding(.top, 28)
            .padding(.bottom, 34)

            VStack(spacing: 4) {
                ForEach(DashboardSection.allCases) { section in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { selection = section }
                    } label: {
                        HStack(spacing: 11) {
                            Image(systemName: section.symbol).font(.system(size: 14, weight: .medium))
                            Text(section.rawValue).font(.system(size: 15, weight: selection == section ? .semibold : .regular, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(selection == section ? DashboardPalette.ink : DashboardPalette.secondary)
                        .padding(.horizontal, 17)
                        .frame(height: 48)
                        .background(selection == section ? Color.black.opacity(0.085) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("v\(AppVersion.display)")
                Text("macOS utility").opacity(0.72)
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(DashboardPalette.secondary)
            .padding(.horizontal, 23)
            .padding(.bottom, 28)
        }
        .frame(width: 300)
        .background(DashboardPalette.sidebar)
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
            let daily = dailyMetrics(now: now)
            let rangeBattery = daily.reduce(0) { $0 + $1.batteryPoints }
            let rangeSessions = recentSessions(now: now)
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Live status").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(1.2).textCase(.uppercase).foregroundStyle(DashboardPalette.secondary)
                        Text("Overview").font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1.2).foregroundStyle(DashboardPalette.ink)
                        Text(statusText).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        Button { state.setEnabled(!state.isEnabled) } label: { StatusPill(isHolding: isHolding) }.buttonStyle(.plain)
                        NativeRangeSelector(selection: $selectedRange)
                    }
                }
                .padding(.bottom, 12)

                HStack(spacing: 12) {
                    NativeMetricCard(title: "Awake · Today", value: duration(daily.reduce(0) { $0 + $1.awakeSeconds }), symbol: "clock")
                    NativeMetricCard(title: "Sessions · Today", value: "\(rangeSessions.count)", symbol: "waveform.path.ecg")
                    NativeMetricCard(title: "Battery used", value: rangeBattery > 0 ? "\(rangeBattery.formatted(.number.precision(.fractionLength(0...1))))%" : "—", symbol: "battery.75percent")
                }

                NativeCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Awake time").font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
                        Text("Minutes kept awake per day").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                        SwiftUIChartsAwakeChart(metrics: daily, isHolding: isHolding).frame(height: 215).padding(.top, 16)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    NativeCard {
                        activityPanel
                            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                    }
                    NativeCard {
                        agentsPanel
                            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                    }
                }
            }
            .padding(36)
        }
        .scrollContentBackground(.hidden)
        .background(DashboardPalette.canvas)
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

    private var activityPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Currently keeping awake").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
            HStack(spacing: 16) {
                if currentReasons.isEmpty {
                    Text("No active wake reasons").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                } else {
                    ForEach(currentReasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                    }
                }
            }
        }
    }

    private var agentsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Agents").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
            HStack(spacing: 12) {
                let activeRows = state.rows.filter { $0.engagedCount > 0 }
                if activeRows.isEmpty {
                    Text("No active agents").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                } else {
                    ForEach(activeRows) { row in
                        HStack(spacing: 5) { Circle().fill(row.agent == .codex ? DashboardPalette.lime : DashboardPalette.blue).frame(width: 9, height: 9); Text(row.agent.rawValue).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary) }
                    }
                }
            }
        }
    }
}

private struct NativeCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View { content().foregroundStyle(DashboardPalette.ink).padding(20).background(DashboardPalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DashboardPalette.border, lineWidth: 1) } }
}

private struct NativeRangeSelector: View {
    @Binding var selection: DashboardRange
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DashboardRange.allCases) { range in
                Button { withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) { selection = range } } label: {
                    Text(range.title).font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(selection == range ? Color.white : DashboardPalette.secondary)
                        .frame(width: 72, height: 28)
                        .background(selection == range ? DashboardPalette.ink : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(DashboardPalette.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(DashboardPalette.border, lineWidth: 1) }
    }
}

private struct NativeMetricCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View { NativeCard { VStack(alignment: .leading, spacing: 20) { HStack(alignment: .center) { Text(title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(DashboardPalette.secondary); Spacer(); Image(systemName: symbol).font(.system(size: 15, weight: .medium)).foregroundStyle(DashboardPalette.secondary) }; Text(value).font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink).tracking(-1.2) } }.frame(maxWidth: .infinity, minHeight: 110, alignment: .leading) }
}

private struct SwiftUIChartsAwakeChart: View {
    let metrics: [DailyWakeMetric]
    let isHolding: Bool

    var body: some View {
        StableDailyBarChart(metrics: metrics, isHolding: isHolding)
    }
}

private struct StableDailyBarChart: View {
    let metrics: [DailyWakeMetric]
    let isHolding: Bool

    var body: some View {
        GeometryReader { proxy in
            let values = metrics.map { $0.awakeSeconds / 60 }
            let maximum = max(60, ceil((values.max() ?? 0) / 15) * 15)
            let plotHeight = max(1, proxy.size.height - 34)
            let middleIndex = max(0, (metrics.count - 1) / 2)
            let barWidth = max(4, min(34, proxy.size.width / CGFloat(max(metrics.count * 2, 1))))

            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(Int(maximum))")
                        Spacer()
                        Text("\(Int(maximum / 2))")
                        Spacer()
                        Text("0")
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(DashboardPalette.secondary)
                    .frame(width: 26, height: plotHeight)

                    ZStack(alignment: .bottomLeading) {
                        VStack(spacing: 0) {
                            Rectangle().fill(DashboardPalette.border).frame(height: 1)
                            Spacer()
                            Rectangle().fill(DashboardPalette.border.opacity(0.5)).frame(height: 1)
                            Spacer()
                            Rectangle().fill(DashboardPalette.border).frame(height: 1)
                        }

                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                                let value = metric.awakeSeconds / 60
                                let height = max(value > 0 ? 2 : 0, plotHeight * CGFloat(value / maximum))
                                VStack(spacing: 0) {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Calendar.current.isDateInToday(metric.day) && isHolding ? DashboardPalette.ink : DashboardPalette.lime)
                                        .frame(width: barWidth, height: height)
                                }
                                .frame(maxWidth: .infinity, maxHeight: plotHeight, alignment: .bottom)
                                .accessibilityLabel(metric.day.formatted(date: .abbreviated, time: .omitted))
                                .accessibilityValue(value > 0 ? "\(Int(value)) minutes awake" : "No awake time")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 0) {
                    ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                        Text(index == 0 || index == middleIndex || index == metrics.count - 1
                             ? metric.day.formatted(.dateTime.month(.abbreviated).day())
                             : "")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(DashboardPalette.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.leading, 36)
                .padding(.top, 7)
            }
        }
    }
}

private enum AppVersion {
    static var display: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    }
}

private struct SettingsDashboard: View {
    @ObservedObject var state: AppState
    @State private var draft: HoldSettings
    @State private var didSave = false

    init(state: AppState) {
        self.state = state
        _draft = State(initialValue: state.settings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Settings").font(.system(size: 42, weight: .bold, design: .rounded)).tracking(-1.8).foregroundStyle(DashboardPalette.ink)
                    Text("Tune how Wake My Mac behaves on your Mac.").font(.system(size: 16, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                }
                .padding(.bottom, 12)

                NativeCard {
                    VStack(alignment: .leading, spacing: 18) {
                        SettingsHeading(title: "Operating mode", subtitle: "Choose when Wake My Mac should keep your Mac reachable.")
                        HStack(spacing: 8) {
                            ForEach(HoldMode.allCases) { mode in
                                Button { draft.mode = mode } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(mode.title).font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Text(mode.explanation).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(draft.mode == mode ? DashboardPalette.ink.opacity(0.72) : DashboardPalette.secondary).lineLimit(2)
                                    }
                                    .foregroundStyle(draft.mode == mode ? DashboardPalette.ink : DashboardPalette.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .frame(minHeight: 88, alignment: .topLeading)
                                    .background(draft.mode == mode ? DashboardPalette.lime.opacity(0.48) : DashboardPalette.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(draft.mode == mode ? DashboardPalette.lime : DashboardPalette.border, lineWidth: 1) }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    NativeCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SettingsHeading(title: "Battery", subtitle: "Keep energy use predictable.")
                            SettingsToggle(title: "Only hold when plugged in", isOn: $draft.onlyWhenPluggedIn)
                            SettingsToggle(title: "Respect Low Power Mode", isOn: $draft.respectLowPowerMode)
                            Stepper("Stop below (draft.batteryCutoffPercent)%", value: $draft.batteryCutoffPercent, in: 5...80, step: 5).font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }
                    NativeCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SettingsHeading(title: "Display", subtitle: "Choose what happens when the lid closes.")
                            SettingsToggle(title: "Turn display off on lid close", isOn: $draft.turnDisplayOffOnLidClose)
                            Stepper("Display off after (draft.turnDisplayOffAfterFinishSeconds)s", value: $draft.turnDisplayOffAfterFinishSeconds, in: 0...300, step: 10).font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    NativeCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SettingsHeading(title: "Notifications", subtitle: "Stay informed without extra noise.")
                            SettingsToggle(title: "Show notifications and play chimes", isOn: $draft.notificationsEnabled)
                            Picker("Sound", selection: $draft.soundName) { ForEach(["Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink", "Funk"], id: \.self) { Text($0) } }
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                    }
                        NativeCard {
                            VStack(alignment: .leading, spacing: 18) {
                                SettingsHeading(title: "Updates", subtitle: "Wake My Mac stays current through Sparkle.")
                                Button("Check for Updates…") { UpdateService.shared.checkForUpdates(nil) }
                                    .buttonStyle(.borderedProminent).tint(DashboardPalette.ink)
                                HStack {
                                    Text("Version")
                                    Spacer()
                                    Text("v\(AppVersion.display)")
                                        .fontWeight(.semibold)
                                }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(DashboardPalette.secondary)
                                Text("macOS 14 Sonoma or later").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                            }
                        }
                }

                HStack {
                    Text("Changes apply to the menu-bar service immediately.").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                    Spacer()
                    Button(didSave ? "Saved" : "Save Changes") {
                        state.updateSettings(draft)
                        withAnimation(.easeOut(duration: 0.2)) { didSave = true }
                    }
                    .buttonStyle(.borderedProminent).tint(DashboardPalette.ink)
                }
            }
            .padding(46)
        }
        .scrollContentBackground(.hidden)
        .background(DashboardPalette.canvas)
    }
}

private struct SettingsHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
            Text(subtitle).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
        }
    }
}

private struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .tint(DashboardPalette.lime)
    }
}

private struct HistoryDashboard: View {
    @ObservedObject var history: SessionHistoryStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Session History").font(.system(size: 42, weight: .bold, design: .rounded)).tracking(-1.8).foregroundStyle(DashboardPalette.ink)
                        Text("Stored only on this Mac. No command contents or destinations are recorded.").font(.system(size: 16, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                    }
                    Spacer()
                    Button("Clear History", role: .destructive) { history.clear() }.disabled(history.sessions.isEmpty)
                }

                if history.sessions.isEmpty {
                    NativeCard {
                        VStack(spacing: 10) {
                            Image(systemName: "clock").font(.system(size: 26, weight: .medium)).foregroundStyle(DashboardPalette.secondary)
                            Text("No sessions yet").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
                            Text("Your wake history will appear here.").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                } else {
                    NativeCard {
                        LazyVStack(spacing: 0) {
                            ForEach(history.sessions) { session in
                                HStack(spacing: 14) {
                                    Image(systemName: session.endedAt == nil ? "bolt.circle.fill" : "clock")
                                        .font(.system(size: 20, weight: .medium)).foregroundStyle(session.endedAt == nil ? DashboardPalette.lime : DashboardPalette.secondary)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(session.reasons.isEmpty ? "Wake session" : session.reasons.joined(separator: " · ")).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
                                        HStack(spacing: 8) {
                                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                            Text("•")
                                            Text(duration(session.duration))
                                            if !session.agents.isEmpty { Text("• \(session.agents.joined(separator: ", "))") }
                                        }.font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                                    }
                                    Spacer()
                                    Text(session.endedAt == nil ? "Live" : "−\(session.batteryUsed)% battery")
                                        .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(session.endedAt == nil ? DashboardPalette.lime : DashboardPalette.secondary)
                                }
                                .padding(.vertical, 13)
                                if session.id != history.sessions.last?.id { Divider().overlay(DashboardPalette.border) }
                            }
                        }
                    }
                }
            }
            .padding(46)
        }
        .scrollContentBackground(.hidden)
        .background(DashboardPalette.canvas)
    }
}

private struct ActivityRulesDashboard: View {
    @ObservedObject var state: AppState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Rules").font(.system(size: 42, weight: .bold, design: .rounded)).tracking(-1.8).foregroundStyle(DashboardPalette.ink)
                    Text("Keep your Mac awake while important work is in progress.").font(.system(size: 16, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                }
                ForEach(state.settings.activityRules) { rule in
                    RuleCard(rule: rule, isActive: state.activityMatches.contains { $0.kind == rule.kind }) { updated in
                        var settings = state.settings
                        if let index = settings.activityRules.firstIndex(where: { $0.kind == updated.kind }) { settings.activityRules[index] = updated }
                        state.updateSettings(settings)
                    }
                }
            }.padding(46)
        }
        .scrollContentBackground(.hidden)
        .background(DashboardPalette.canvas)
    }
}

private struct RuleCard: View {
    let rule: ActivityRule
    let isActive: Bool
    let update: (ActivityRule) -> Void
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(rule.kind.title, systemImage: rule.kind.symbol).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink)
                    if isActive { Text("ACTIVE").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(DashboardPalette.ink).padding(.horizontal, 7).padding(.vertical, 3).background(DashboardPalette.lime.opacity(0.55), in: Capsule()) }
                    Spacer()
                    RuleSwitch(isOn: rule.isEnabled) {
                        var copy = rule
                        copy.isEnabled.toggle()
                        update(copy)
                    }
                }
                if rule.kind == .selectedApps {
                    HStack {
                        Text(rule.selectedApplicationPaths.isEmpty ? "No applications selected" : rule.selectedApplicationPaths.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }.joined(separator: ", "))
                            .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary).lineLimit(2)
                        Spacer()
                        Button("Choose Apps…", action: chooseApps)
                    }
                } else {
                    Text("Automatically detects common \(rule.kind.title.lowercased()) tools without recording command contents.").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(DashboardPalette.secondary)
                }
            }
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

private struct RuleSwitch: View {
    let isOn: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(isOn ? "On" : "Off").font(.system(size: 12, weight: .semibold, design: .rounded))
                Capsule().fill(isOn ? DashboardPalette.lime : DashboardPalette.secondary.opacity(0.28)).frame(width: 38, height: 22)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle().fill(DashboardPalette.card).frame(width: 16, height: 16).padding(3)
                    }
            }
            .foregroundStyle(isOn ? DashboardPalette.ink : DashboardPalette.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Disable rule" : "Enable rule")
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
    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(isHolding ? DashboardPalette.lime : DashboardPalette.secondary)
                .frame(width: 8, height: 8)
                .shadow(color: isHolding ? DashboardPalette.lime.opacity(0.8) : .clear, radius: 3)
            Text(isHolding ? "Holding awake" : "Sleep allowed")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(DashboardPalette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isHolding ? DashboardPalette.lime.opacity(0.12) : DashboardPalette.card, in: Capsule())
        .overlay {
            Capsule().stroke(isHolding ? DashboardPalette.lime : DashboardPalette.border, lineWidth: 1.5)
        }
    }
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
