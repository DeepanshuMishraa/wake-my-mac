import Foundation
import SwiftUI
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled: Bool
    @Published var settings: HoldSettings
    @Published var battery: BatterySnapshot = .unknown
    @Published var rows: [AgentRow] = []
    @Published var phase: HoldPhase = .disabled
    @Published var heldSince: Date?
    @Published var pauseUntil: Date?
    @Published var lastLimitMessage: String?
    @Published var activityMatches: [ActivityMatch] = []
    @Published var reliableWakeState: ReliableWakeState = .checking
    let history = SessionHistoryStore()

    var onVisualStateChange: (() -> Void)?

    private let powerManager = PowerAssertionManager()
    private let batteryMonitor = BatteryMonitor()
    private let agentMonitor = AgentMonitor()
    private let agentScanQueue = DispatchQueue(label: "com.dipxsy.watchmymac.agent-scan", qos: .utility)
    private let activityMonitor = ActivityRuleMonitor()
    private var timer: Timer?
    private var isStarted = false
    private var isAgentScanInFlight = false
    private var idleBeganAt: Date?
    private var wasHolding = false
    private var workspaceObservers: [NSObjectProtocol] = []

    init(settings: HoldSettings = SettingsStore.shared.load()) {
        self.settings = settings
        self.isEnabled = settings.isEnabled
        powerManager.onStateChange = { [weak self] state in
            guard let self else { return }
            self.reliableWakeState = state
            self.onVisualStateChange?()
        }
    }

    func start() {
        isStarted = true
        observePowerLifecycle()
        powerManager.refreshHelperStatus()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        isStarted = false
        timer?.invalidate()
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers.removeAll()
        history.update(isHolding: false, reasons: [], agents: [], battery: battery.percent)
        powerManager.shutdown()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        settings.isEnabled = enabled
        SettingsStore.shared.save(settings)
        if !enabled {
            pauseUntil = nil
            idleBeganAt = nil
            heldSince = nil
            powerManager.release()
            notify(title: "StayRunning off", body: "Wake assertions released.")
        } else {
            notify(title: "StayRunning on", body: settings.mode.explanation)
            if !reliableWakeState.isHelperReady {
                powerManager.registerHelper()
            }
        }
        refresh()
    }

    func toggleEnabledFromShortcut() {
        setEnabled(!isEnabled)
    }

    func pause(for interval: TimeInterval) {
        pauseUntil = Date().addingTimeInterval(interval)
        powerManager.release()
        heldSince = nil
        idleBeganAt = nil
        notify(title: "StayRunning paused", body: "Wake assertions are paused temporarily.")
        refresh()
    }

    func updateSettings(_ newSettings: HoldSettings) {
        let modeChanged = settings.mode != newSettings.mode
        settings = newSettings
        isEnabled = newSettings.isEnabled
        SettingsStore.shared.save(newSettings)
        if modeChanged {
            // A mode switch is a new lifecycle. Do not carry an SSH assertion,
            // idle countdown, or wake lease into the new mode.
            idleBeganAt = nil
            heldSince = nil
            wasHolding = false
            powerManager.release()
        }
        refresh()
    }

    func openSettings() {
        DashboardWindowController.shared.show(state: self, section: .settings)
    }

    func openDashboard() {
        DashboardWindowController.shared.show(state: self, section: .overview)
    }

    func setupReliableWake() {
        powerManager.registerHelper()
    }

    func openReliableWakeApprovalSettings() {
        powerManager.openApprovalSettings()
    }

    func performReliableWakeSetupAction() {
        if reliableWakeState == .approvalRequired {
            openReliableWakeApprovalSettings()
        } else {
            setupReliableWake()
        }
    }

    private func refresh() {
        battery = batteryMonitor.snapshot()
        refreshAgents()
        activityMatches = activityMonitor.scan(rules: settings.activityRules)
        if reliableWakeState.needsSetupAction {
            powerManager.refreshHelperStatus()
        }

        evaluateCurrentPolicy()
    }

    private func refreshAgents() {
        guard isStarted, !isAgentScanInFlight else { return }
        isAgentScanInFlight = true
        let monitor = agentMonitor
        agentScanQueue.async { [weak self] in
            let rows = monitor.scan()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAgentScanInFlight = false
                guard self.isStarted else { return }
                self.rows = rows
                self.evaluateCurrentPolicy()
            }
        }
    }

    private func evaluateCurrentPolicy() {
        if let pauseUntil, pauseUntil <= Date() {
            self.pauseUntil = nil
        }

        let engagedCount = rows.reduce(0) { $0 + $1.engagedCount }
        let shouldHold = HoldPolicy.shouldHold(mode: settings.mode, isEnabled: isEnabled, engagedAgentCount: engagedCount, activityMatchCount: activityMatches.count)
        applyPolicy(shouldHold: shouldHold)
        let activeAgents = rows.flatMap(\.sessions).filter { $0.status == .working || $0.status == .blocked }.map(\.agent.rawValue)
        let reasons = activityMatches.map(\.reason) + (engagedCount > 0 ? ["Agent activity"] : []) + (settings.mode == .ssh ? ["SSH mode"] : []) + (settings.mode == .manual ? ["Manual mode"] : [])
        history.update(isHolding: powerManager.isHolding, reasons: Array(Set(reasons)).sorted(), agents: Array(Set(activeAgents)).sorted(), battery: battery.percent)
        onVisualStateChange?()
    }

    private func applyPolicy(shouldHold: Bool) {
        guard isEnabled else {
            phase = .disabled
            powerManager.release()
            return
        }

        if let pauseUntil {
            phase = .paused(until: pauseUntil)
            powerManager.release()
            return
        }

        if let guardrail = currentGuardrail() {
            phase = .guarded(guardrail)
            if wasHolding {
                notify(title: "Battery guardrail reached", body: guardrail)
            }
            wasHolding = false
            heldSince = nil
            idleBeganAt = nil
            powerManager.release()
            return
        }

        if shouldHold {
            idleBeganAt = nil
            phase = .holding
            if heldSince == nil {
                heldSince = Date()
                notify(title: "StayRunning engaged", body: "A wake rule is active, so sleep is being held.")
            }
            powerManager.hold(reason: holdReason, kind: settings.mode.wakeRequestKind)
            wasHolding = true
            return
        }

        guard wasHolding else {
            phase = .guarded("No watched agents are working.")
            powerManager.release()
            return
        }

        let idleStart = idleBeganAt ?? Date()
        idleBeganAt = idleStart
        let elapsed = Int(Date().timeIntervalSince(idleStart))
        let secondsLeft = max(0, 30 - elapsed)

        if secondsLeft > 0 {
            phase = .idleCountdown(secondsLeft: secondsLeft)
            powerManager.hold(reason: "StayRunning: waiting for idle grace period", kind: .leased)
        } else {
            phase = .guarded("Agents have been idle for 30 seconds.")
            heldSince = nil
            idleBeganAt = nil
            wasHolding = false
            powerManager.release()
            notify(title: "Agent finished", body: "Idle grace period ended. Your Mac can sleep.")
        }
    }

    private func currentGuardrail() -> String? {
        if settings.onlyWhenPluggedIn && !battery.isPluggedIn {
            return "Only-when-plugged-in mode is enabled."
        }

        if HoldPolicy.shouldStopForLowPowerMode(
            mode: settings.mode,
            respectLowPowerMode: settings.respectLowPowerMode,
            isLowPowerMode: battery.isLowPowerMode
        ) {
            return "Low Power Mode is on."
        }

        if battery.percent <= settings.batteryCutoffPercent && !battery.isPluggedIn {
            return "Battery is at \(battery.percent)%, below the \(settings.batteryCutoffPercent)% cutoff."
        }

        return nil
    }

    private func notify(title: String, body: String) {
        guard settings.notificationsEnabled else { return }
        NotificationService.shared.send(title: title, body: body, soundName: settings.soundName)
    }

    private var holdReason: String {
        switch settings.mode {
        case .agents: "StayRunning: automation is active"
        case .ssh: "StayRunning: SSH mode"
        case .manual: "StayRunning: manual mode"
        }
    }

    private func observePowerLifecycle() {
        guard workspaceObservers.isEmpty else { return }
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            })
        }
    }
}
