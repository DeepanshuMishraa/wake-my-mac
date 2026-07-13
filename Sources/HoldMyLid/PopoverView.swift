import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            agentsSection
            divider
            pauseSection
            divider
            footer
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .frame(width: 320, height: 300, alignment: .topLeading)
        .background(PopoverPalette.background)
    }

    private var header: some View {
        HStack(spacing: 14) {
            BatteryBadge(percent: state.battery.percent, symbol: batterySymbol, colour: batteryBarColor)

            VStack(alignment: .leading, spacing: 3) {
                Text("Wake My Mac")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(statusLine)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(PopoverPalette.muted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
            Toggle("", isOn: Binding(get: { state.isEnabled }, set: { state.setEnabled($0) }))
                .labelsHidden()
                .toggleStyle(.switch)
            .controlSize(.small)
                .tint(PopoverPalette.accent)
        }
        .padding(.bottom, 8)
    }

    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Agents").font(.system(size: 15, weight: .medium, design: .rounded))
            }
            HStack(spacing: 8) {
                ForEach(state.rows.filter { $0.agent.isMenuVisible && $0.agent.isInstalled }) { row in
                    AgentChip(agent: row.agent, row: row)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pauseSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock").font(.system(size: 15, weight: .medium)).foregroundStyle(PopoverPalette.accent).frame(width: 20)
            Text("Pause").font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            Button("30m") { state.pause(for: 30 * 60) }.buttonStyle(PauseButtonStyle())
            Button("1h") { state.pause(for: 60 * 60) }.buttonStyle(PauseButtonStyle())
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Button { state.openSettings() } label: { footerLine("gearshape", "Settings…") }.buttonStyle(.plain)
            Button { IntegrationInstaller.presentConfiguration() } label: { footerLine("puzzlepiece.extension", "Configure Agent Integrations…") }.buttonStyle(.plain)
            Button { UpdateService.shared.checkForUpdates(nil) } label: { footerLine("arrow.clockwise", "Check for Updates…") }.buttonStyle(.plain)
            Button { NSApp.terminate(nil) } label: { footerLine("power", "Quit Wake My Mac", isDestructive: true) }.buttonStyle(.plain)
        }
    }

    private func footerLine(_ symbol: String, _ title: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 16, weight: .medium)).foregroundStyle(isDestructive ? PopoverPalette.red : PopoverPalette.muted).frame(width: 22)
            Text(title).font(.system(size: 12, design: .rounded))
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var divider: some View { Divider().overlay(PopoverPalette.divider).padding(.vertical, 5) }

    private var statusLine: String {
        if !state.isEnabled { return "Sleep mode is available." }
        if state.phase == .holding && state.settings.mode == .ssh { return "Your Mac is ready for SSH." }
        if state.phase == .holding && state.settings.mode == .manual { return "Your Mac is being kept awake." }
        if state.rows.contains(where: { $0.blockedCount > 0 }) { return "An agent needs your input." }
        if state.rows.contains(where: { $0.activeCount > 0 }) { return "An agent is actively working." }
        return switch state.phase {
        case .holding: "Your Mac is being kept awake."
        case .idleCountdown(let seconds): "Ready to sleep in \(seconds) seconds."
        case .disabled: "Sleep mode is available."
        case .paused(let until): "Paused until \(until.formatted(date: .omitted, time: .shortened))."
        case .guarded(let message): message
        }
    }

    private var batteryBarColor: Color {
        if state.battery.percent <= state.settings.batteryCutoffPercent { return .red }
        if state.battery.percent < 30 { return .orange }
        return PopoverPalette.green
    }

    private var batterySymbol: String {
        if state.battery.isCharging { return "battery.100percent.bolt" }
        switch state.battery.percent {
        case 0..<25: return "battery.25percent"
        case 25..<50: return "battery.50percent"
        case 50..<75: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

private struct BatteryBadge: View {
    let percent: Int
    let symbol: String
    let colour: Color

    var body: some View {
        ZStack {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(colour)
            Text("\(percent)")
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundStyle(PopoverPalette.primary)
                .offset(x: -1)
        }
        .frame(width: 30, height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Battery \(percent) percent")
    }
}

private enum PopoverPalette {
    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let divider = Color(nsColor: .separatorColor)
    static let primary = Color(nsColor: .labelColor)
    static let muted = Color(nsColor: .secondaryLabelColor)
    static let green = Color(red: 0.36, green: 0.55, blue: 1.0)
    static let accent = Color(red: 0.36, green: 0.55, blue: 1.0)
    static let active = Color(red: 0.10, green: 0.78, blue: 0.26)
    static let orange = Color(red: 1.0, green: 0.61, blue: 0.18)
    static let red = Color(red: 1.0, green: 0.30, blue: 0.34)
}

private struct PauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(PopoverPalette.surface.opacity(configuration.isPressed ? 1.7 : 1)))
            .foregroundStyle(PopoverPalette.primary)
    }
}

private struct AgentChip: View {
    let agent: AgentKind
    let row: AgentRow?

    var body: some View {
        VStack(spacing: 6) {
            AgentBrandIcon(agent: agent)
                .frame(width: 21, height: 21)
                .opacity(row == nil ? 0.45 : 1)
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
        }
        .frame(width: 30)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(agent.rawValue), \(row == nil ? "inactive" : row?.statusText ?? "inactive")")
    }

    private var dotColor: Color {
        guard let row else { return PopoverPalette.muted.opacity(0.35) }
        if row.blockedCount > 0 { return PopoverPalette.orange }
        if row.activeCount > 0 { return PopoverPalette.active }
        return PopoverPalette.muted.opacity(0.45)
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

struct AgentBrandIcon: View {
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
