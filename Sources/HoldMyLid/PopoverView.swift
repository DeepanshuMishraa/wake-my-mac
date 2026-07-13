import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            
            VStack(spacing: 6) {
                agentsSection
                modeSection
                pauseSection
            }
            .padding(.vertical, 6)
            
            divider
            footer
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .frame(width: 320, alignment: .topLeading)
        .background(PopoverPalette.background)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Wake My Mac")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PopoverPalette.primary)
                HStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Image(systemName: batterySymbol)
                            .font(.system(size: 10))
                        Text("\(state.battery.percent)%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(batteryBarColor)
                    
                    Text("·")
                        .foregroundStyle(PopoverPalette.muted)
                    
                    Text(statusLine)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(PopoverPalette.muted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: Binding(get: { state.isEnabled }, set: { state.setEnabled($0) }))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(PopoverPalette.accent)
        }
        .padding(.vertical, 4)
    }

    private var agentsSection: some View {
        HStack {
            Text("Agents")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(PopoverPalette.muted)
            Spacer()
            let activeRows = state.rows.filter { $0.engagedCount > 0 }
            if activeRows.isEmpty {
                Text("None active")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(PopoverPalette.muted)
            } else {
                HStack(spacing: 6) {
                    ForEach(activeRows) { row in
                        AgentBrandIcon(agent: row.agent)
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var modeSection: some View {
        HStack {
            Text("Mode")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(PopoverPalette.muted)
            Spacer()
            HStack(spacing: 4) {
                ForEach(HoldMode.allCases) { mode in
                    ModeButton(title: mode.title, isSelected: state.settings.mode == mode) {
                        var newSettings = state.settings
                        newSettings.mode = mode
                        state.updateSettings(newSettings)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var pauseSection: some View {
        HStack {
            Text("Pause")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(PopoverPalette.muted)
            Spacer()
            PauseButton(title: "30m") { state.pause(for: 30 * 60) }
            PauseButton(title: "1h") { state.pause(for: 60 * 60) }
        }
        .padding(.vertical, 4)
    }

    private var footer: some View {
        VStack(spacing: 2) {
            MenuButton("Settings…") { state.openSettings() }
            MenuButton("Configure Agent Integrations…") { IntegrationInstaller.presentConfiguration() }
            MenuButton("Check for Updates…") { UpdateService.shared.checkForUpdates(nil) }
            MenuButton("Quit Wake My Mac", isDestructive: true) { NSApp.terminate(nil) }
        }
        .padding(.top, 4)
    }

    private var divider: some View { Divider().overlay(PopoverPalette.divider).padding(.vertical, 6) }

    private var statusLine: String {
        if !state.isEnabled { return "Sleep mode is available." }
        if state.battery.percent <= 20 && !state.battery.isPluggedIn {
            return "Battery low. Sleep allowed below \(state.settings.batteryCutoffPercent)%."
        }
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
        return PopoverPalette.muted
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

private enum PopoverPalette {
    static let background = Color(red: 255/255, green: 241/255, blue: 223/255)
    static let surface = Color(red: 255/255, green: 251/255, blue: 247/255)
    static let hover = Color(red: 244/255, green: 225/255, blue: 205/255)
    static let divider = Color(red: 41/255, green: 37/255, blue: 36/255).opacity(0.24)
    static let primary = Color(red: 41/255, green: 37/255, blue: 36/255)
    static let muted = Color(red: 136/255, green: 119/255, blue: 107/255)
    static let accent = Color(red: 41/255, green: 37/255, blue: 36/255)
    static let blue = Color(red: 138/255, green: 158/255, blue: 228/255)
    static let green = Color(red: 169/255, green: 203/255, blue: 36/255)
    static let orange = Color(red: 1.0, green: 0.61, blue: 0.18)
    static let red = Color(red: 219/255, green: 68/255, blue: 85/255)
}

private struct PauseButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isHovered ? Color(red: 231/255, green: 210/255, blue: 187/255) : PopoverPalette.hover, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(PopoverPalette.divider, lineWidth: 1)
                }
                .foregroundStyle(PopoverPalette.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct ModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected 
                        ? PopoverPalette.primary 
                        : (isHovered ? Color(red: 231/255, green: 210/255, blue: 187/255) : PopoverPalette.hover),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(PopoverPalette.divider, lineWidth: 1)
                    }
                }
                .foregroundStyle(isSelected ? PopoverPalette.background : PopoverPalette.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct MenuButton: View {
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    @State private var isHovered = false

    init(_ title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isDestructive ? PopoverPalette.red : PopoverPalette.primary)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(isHovered ? PopoverPalette.hover : Color.clear, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -6)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
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
