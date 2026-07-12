import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            sectionDivider
            modeSection
            sectionDivider
            batterySection
            sectionDivider
            agentList
            sectionDivider
            pauseSection
            sectionDivider
            footer
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 320)
        .background(Color(red: 0.105, green: 0.105, blue: 0.115))
        .preferredColorScheme(.dark)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Mode", selection: Binding(
                get: { state.settings.mode },
                set: { mode in
                    var settings = state.settings
                    settings.mode = mode
                    state.updateSettings(settings)
                }
            )) {
                ForEach(HoldMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(state.settings.mode.explanation)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Wake My Mac")
                    .font(.system(size: 17, weight: .bold))

                Text(statusLine)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: Binding(
                get: { state.isEnabled },
                set: { state.setEnabled($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.regular)
        }
    }

    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Battery")
                .font(.system(size: 15, weight: .bold))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.18))
                    Capsule()
                        .fill(batteryBarColor)
                        .frame(width: proxy.size.width * CGFloat(max(0, min(100, state.battery.percent))) / 100)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(state.battery.percent)% left")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("stops below \(state.settings.batteryCutoffPercent)%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var agentList: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Agents")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                Text(workingSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if state.rows.isEmpty {
                Text("No supported agents detected")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(state.rows) { row in
                    AgentLine(row: row)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                state.openDashboard()
            } label: {
                menuLine("Open App", shortcut: "⌘O")
            }
            .buttonStyle(.plain)

            Button {
                state.openSettings()
            } label: {
                menuLine("Settings…", shortcut: "⌘,")
            }
            .buttonStyle(.plain)

            Button {
                UpdateService.shared.checkForUpdates(nil)
            } label: {
                menuLine("Check for Updates…", shortcut: "")
            }
            .buttonStyle(.plain)

            Button {
                NSApp.terminate(nil)
            } label: {
                menuLine("Quit Wake My Mac", shortcut: "⌘Q")
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 14))
    }

    private var pauseSection: some View {
        HStack(spacing: 8) {
            Text("Pause")
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Button("30 min") { state.pause(for: 30 * 60) }
                .buttonStyle(PauseButtonStyle())
            Button("1 hour") { state.pause(for: 60 * 60) }
                .buttonStyle(PauseButtonStyle())
        }
    }

    private var sectionDivider: some View {
        Divider().overlay(Color.white.opacity(0.08)).padding(.vertical, 10)
    }

    private func menuLine(_ title: String, shortcut: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut).font(.system(size: 11)).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private var statusLine: String {
        if state.phase == .holding && state.settings.mode == .ssh { return "Awake — ready for SSH" }
        if state.phase == .holding && state.settings.mode == .manual { return "Awake — manual hold" }
        if state.rows.contains(where: { $0.blockedCount > 0 }) {
            return "Awake — agent needs input"
        }
        if state.rows.contains(where: { $0.activeCount > 0 }) {
            return "Awake — agent working"
        }
        return switch state.phase {
        case .holding:
            "Awake — lid protection active"
        case .idleCountdown(let seconds):
            "Awake — sleeps in \(seconds)s"
        case .disabled:
            "Sleep mode — protection off"
        case .paused(let until):
            "Sleep mode — paused until \(until.formatted(date: .omitted, time: .shortened))"
        case .guarded(let message):
            message
        }
    }

    private var statusColor: Color {
        if state.rows.contains(where: { $0.blockedCount > 0 }) { return .orange }
        if state.rows.contains(where: { $0.activeCount > 0 }) { return .green }
        return switch state.phase {
        case .holding, .idleCountdown: Color.secondary.opacity(0.55)
        case .paused: Color.orange
        case .disabled: Color.secondary
        case .guarded: Color.secondary.opacity(0.55)
        }
    }

    private var workingSummary: String {
        let blocked = state.rows.reduce(0) { $0 + $1.blockedCount }
        if blocked > 0 { return "\(blocked) need input" }
        let working = state.rows.reduce(0) { $0 + $1.activeCount }
        return working == 0 ? "None working" : "\(working) working"
    }

    private var batteryBarColor: Color {
        if state.battery.percent <= state.settings.batteryCutoffPercent { return .red }
        if state.battery.percent < 30 { return .orange }
        return .green
    }
}

private struct PauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.18 : 0.11))
            )
    }
}

private struct AgentLine: View {
    let row: AgentRow
    @State private var showTaskPopover = false
    @State private var hoverGeneration = 0

    var body: some View {
        Group {
            if linkedSessions.count > 1 {
                Menu {
                    ForEach(linkedSessions) { session in
                        Button(session.title) { open(session) }
                    }
                } label: {
                    rowContent
                }
                .menuStyle(.borderlessButton)
            } else if let session = linkedSessions.first {
                Button { open(session) } label: { rowContent }
                    .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .onHover(perform: handleHover)
        .popover(isPresented: $showTaskPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
            taskPopover
        }
    }

    private var rowContent: some View {
        HStack(spacing: 9) {
            AgentBrandIcon(agent: row.agent)

            Text(row.agent.rawValue)
                .font(.system(size: 13, weight: row.engagedCount > 0 ? .semibold : .regular))
                .lineLimit(1)
                .foregroundStyle(row.isRunning ? .primary : .secondary)

            Spacer()

            Text(row.statusText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Circle()
                .fill(row.blockedCount > 0 ? Color.orange : (row.activeCount > 0 ? Color.green : Color.secondary.opacity(0.35)))
                .frame(width: 7, height: 7)
        }
        .frame(height: 29)
        .contentShape(Rectangle())
    }

    private var activeSessions: [AgentSession] {
        row.sessions.filter { $0.status == .working || $0.status == .blocked }
    }

    private var linkedSessions: [AgentSession] {
        activeSessions.filter { $0.deepLink != nil }
    }

    private var taskPopover: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Codex tasks")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)

            ForEach(linkedSessions) { session in
                Button {
                    showTaskPopover = false
                    open(session)
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(session.status == .blocked ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        Text(session.title)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 6)
        .frame(width: 280)
        .onHover { inside in
            if inside {
                hoverGeneration += 1
                showTaskPopover = true
            } else {
                schedulePopoverClose()
            }
        }
    }

    private func handleHover(_ inside: Bool) {
        guard !linkedSessions.isEmpty else { return }
        hoverGeneration += 1
        if inside {
            showTaskPopover = true
        } else {
            schedulePopoverClose()
        }
    }

    private func schedulePopoverClose() {
        hoverGeneration += 1
        let generation = hoverGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard hoverGeneration == generation else { return }
            showTaskPopover = false
        }
    }

    private func open(_ session: AgentSession) {
        guard let value = session.deepLink, let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct AgentBrandIcon: View {
    let agent: AgentKind
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let image = brandImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.12))
                    Text(agent.brandMark)
                        .font(.system(size: agent == .pi ? 17 : 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var brandImage: NSImage? {
        if let name = agent.bundledIconName(darkMode: colorScheme == .dark),
           let url = Bundle.module.url(
               forResource: name,
               withExtension: agent == .antigravity ? "png" : "svg",
               subdirectory: "AgentIcons"
           ),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let asset = agent.iconAssetPath, let image = NSImage(contentsOfFile: asset) {
            return image
        }

        if let app = agent.appPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return NSWorkspace.shared.icon(forFile: app)
        }

        return nil
    }
}
