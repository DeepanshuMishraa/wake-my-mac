import AppKit
import SwiftUI

struct PopoverView: View {
    static let preferredWidth: CGFloat = 330

    static func preferredHeight(
        agentCount: Int,
        agentsExpanded: Bool,
        showsReliableWakeSetup: Bool = false
    ) -> CGFloat {
        let setupHeight: CGFloat = showsReliableWakeSetup ? 42 : 0
        guard agentsExpanded else { return 309 + setupHeight }
        // Every installed agent adds one 23pt row and one 2pt stack gap.
        // The expanded empty state needs slightly more room than a single row.
        let contentHeight: CGFloat = agentCount == 0 ? 343 : 309 + CGFloat(agentCount) * 25
        return contentHeight + setupHeight
    }

    @ObservedObject var state: AppState
    let onAgentsExpansionChange: (Bool) -> Void
    @State private var areAgentsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if state.reliableWakeState.needsSetupAction {
                sectionDivider
                reliableWakeSetup
            }
            sectionDivider
            batterySection
            sectionDivider
            agentsSection
            sectionDivider
            modeSection
            pauseSection
            sectionDivider
            footer
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(
            width: Self.preferredWidth,
            height: Self.preferredHeight(
                agentCount: state.rows.count,
                agentsExpanded: areAgentsExpanded,
                showsReliableWakeSetup: state.reliableWakeState.needsSetupAction
            ),
            alignment: .topLeading
        )
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wake My Mac")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(headerDetail(at: context.date))
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(
                "Keep awake",
                isOn: Binding(get: { state.isEnabled }, set: { state.setEnabled($0) })
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(.blue)
            .accessibilityLabel("Keep Mac awake")
        }
    }

    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battery")
                .font(.system(size: 14, weight: .semibold))

            ProgressView(value: Double(state.battery.percent), total: 100)
                .progressViewStyle(.linear)
                .tint(batteryColor)

            HStack {
                Text("\(state.battery.percent)% left")
                    .foregroundStyle(.primary)
                Spacer()
                Text("stops below \(state.settings.batteryCutoffPercent)%")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11))
        }
    }

    private var reliableWakeSetup: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)

            Text(reliableWakeSetupText)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 6)

            Button(reliableWakeSetupButtonTitle) {
                state.performReliableWakeSetupAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(height: 26)
    }

    private var reliableWakeSetupText: String {
        switch state.reliableWakeState {
        case .approvalRequired: "macOS approval required once"
        case .failed: "Reliable wake needs attention"
        default: "Enable reliable wake once"
        }
    }

    private var reliableWakeSetupButtonTitle: String {
        state.reliableWakeState == .approvalRequired ? "Approve…" : "Enable"
    }

    private var agentsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: toggleAgents) {
                HStack(spacing: 6) {
                    Image(systemName: areAgentsExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)

                    Text("Agents")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    Text(agentSummary)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(areAgentsExpanded ? "Collapse agents" : "Expand agents")

            if areAgentsExpanded {
                if state.rows.isEmpty {
                    Text("No supported agent CLIs found in your configured PATH.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                } else {
                    ForEach(state.rows) { row in
                        AgentLine(row: row)
                    }
                }
            }
        }
    }

    private var modeSection: some View {
        ModePopupControl(
            selectedMode: state.settings.mode,
            onSelect: selectMode
        )
        .frame(width: Self.preferredWidth - 32, height: 28)
    }

    private var pauseSection: some View {
        HStack(spacing: 7) {
            Text("Pause")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            CompactActionButton(title: "30 min") { state.pause(for: 30 * 60) }
            CompactActionButton(title: "1 hour") { state.pause(for: 60 * 60) }
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        VStack(spacing: 2) {
            MenuRow(title: "Settings…", shortcut: "⌘,") { state.openSettings() }
            MenuRow(title: "Quit Wake My Mac", shortcut: "⌘Q") { NSApp.terminate(nil) }
        }
        .padding(.bottom, 4)
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 7)
    }

    private var engagedSessionCount: Int {
        state.rows.reduce(0) { $0 + $1.engagedCount }
    }

    private var agentSummary: String {
        engagedSessionCount == 0 ? "idle" : "\(engagedSessionCount) working"
    }

    private func toggleAgents() {
        let expanded = !areAgentsExpanded
        areAgentsExpanded = expanded
        onAgentsExpansionChange(expanded)
    }

    private func selectMode(_ mode: HoldMode) {
        var settings = state.settings
        settings.mode = mode
        state.updateSettings(settings)
    }

    private var batteryColor: Color {
        if state.battery.percent <= state.settings.batteryCutoffPercent { return .red }
        if state.battery.percent < 30 { return .orange }
        return .green
    }

    private func headerDetail(at date: Date) -> String {
        switch state.reliableWakeState {
        case .setupRequired, .approvalRequired:
            return "Setup required · Mac may sleep"
        case .failed:
            return "Wake failed · Mac may sleep"
        case .activating where state.phase == .holding:
            return "Enabling · \(state.settings.mode.title)"
        default:
            break
        }

        let status: String
        switch state.phase {
        case .holding: status = state.reliableWakeState == .active ? "Awake" : "Enabling"
        case .paused: status = "Paused"
        case .idleCountdown: status = "Finishing"
        case .disabled: status = "Off"
        case .guarded: status = state.isEnabled ? "Monitoring" : "Off"
        }

        var parts = [status, state.settings.mode.title]
        if let heldSince = state.heldSince, state.phase == .holding {
            parts.append(elapsedText(from: heldSince, to: date))
        } else if case .paused(let until) = state.phase {
            parts.append("until \(until.formatted(date: .omitted, time: .shortened))")
        }
        return parts.joined(separator: " · ")
    }

    private func elapsedText(from start: Date, to end: Date) -> String {
        let minutes = max(0, Int(end.timeIntervalSince(start)) / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

private struct ModePopupControl: NSViewRepresentable {
    let selectedMode: HoldMode
    let onSelect: (HoldMode) -> Void

    func makeNSView(context: Context) -> ModePopupView {
        let view = ModePopupView()
        view.selectedMode = selectedMode
        view.onSelect = onSelect
        return view
    }

    func updateNSView(_ nsView: ModePopupView, context: Context) {
        nsView.selectedMode = selectedMode
        nsView.onSelect = onSelect
        nsView.updateAccessibilityValue()
    }
}

private final class ModePopupView: NSView {
    var selectedMode: HoldMode = .agents
    var onSelect: ((HoldMode) -> Void)?

    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Mode")
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let chevronView: NSImageView = {
        let view = NSImageView()
        let configuration = NSImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
        view.image = NSImage(
            systemSymbolName: "chevron.down",
            accessibilityDescription: "Show mode options"
        )?.withSymbolConfiguration(configuration)
        view.contentTintColor = .secondaryLabelColor
        view.imageScaling = .scaleProportionallyDown
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addSubview(titleLabel)
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 10),
            chevronView.heightAnchor.constraint(equalToConstant: 10)
        ])

        setAccessibilityRole(.popUpButton)
        setAccessibilityLabel("Mode")
        updateAccessibilityValue()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        showMenu(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.charactersIgnoringModifiers == " " {
            showMenu(with: event)
        } else {
            super.keyDown(with: event)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    func updateAccessibilityValue() {
        setAccessibilityValue(selectedMode.title)
    }

    private func showMenu(with event: NSEvent) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        for mode in HoldMode.allCases {
            let item = NSMenuItem(
                title: mode.title,
                action: #selector(selectMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = mode == selectedMode ? .on : .off
            item.isEnabled = true
            menu.addItem(item)
        }

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let mode = HoldMode(rawValue: rawValue)
        else { return }

        selectedMode = mode
        updateAccessibilityValue()
        onSelect?(mode)
    }
}

private struct CompactActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MenuRow: View {
    let title: String
    let shortcut: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .font(.system(size: 12))
            .padding(.horizontal, 6)
            .frame(height: 26)
            .background(isHovered ? Color.primary.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, -6)
        .onHover { isHovered = $0 }
    }
}

private struct AgentLine: View {
    let row: AgentRow

    var body: some View {
        HStack(spacing: 9) {
            AgentBrandIcon(agent: row.agent, size: 18)

            Text(row.agent.rawValue)
                .font(.system(size: 12, weight: row.engagedCount > 0 ? .medium : .regular))
                .foregroundStyle(row.engagedCount > 0 ? .primary : .secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(sessionText)
                .font(.system(size: 11))
                .foregroundStyle(row.engagedCount > 0 ? .secondary : .tertiary)

            if row.engagedCount > 0 {
                Circle()
                    .fill(row.blockedCount > 0 ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 23)
    }

    private var sessionText: String {
        guard row.engagedCount > 0 else { return "idle" }
        return row.engagedCount == 1 ? "1 session" : "\(row.engagedCount) sessions"
    }
}

struct AgentBrandIcon: View {
    let agent: AgentKind
    var size: CGFloat = 22
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let image = brandImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.27)
                        .fill(Color.secondary.opacity(0.16))
                    Text(agent.brandMark)
                        .font(.system(size: agent == .pi ? size * 0.77 : size * 0.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23))
    }

    private var brandImage: NSImage? {
        if let name = agent.bundledIconName(darkMode: colorScheme == .dark),
           let url = agentResourceBundle?.url(
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

    private var agentResourceBundle: Bundle? {
        let name = "WatchMyMac_WatchMyMac"
        let candidates = [
            Bundle.main.url(forResource: name, withExtension: "bundle"),
            Bundle.main.resourceURL?.appendingPathComponent("\(name).bundle"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(name).bundle")
        ].compactMap { $0 }

        return candidates.compactMap(Bundle.init(url:)).first
    }
}
