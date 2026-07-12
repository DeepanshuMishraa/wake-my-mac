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
    let history = SessionHistoryStore()

    var onVisualStateChange: (() -> Void)?

    private let powerManager = PowerAssertionManager()
    private let batteryMonitor = BatteryMonitor()
    private let agentMonitor = AgentMonitor()
    private let activityMonitor = ActivityRuleMonitor()
    private let displayManager = DisplayManager()
    private var timer: Timer?
    private var idleBeganAt: Date?
    private var wasHolding = false
    private var workspaceObservers: [NSObjectProtocol] = []

    init(settings: HoldSettings = SettingsStore.shared.load()) {
        self.settings = settings
        self.isEnabled = settings.isEnabled
    }

    func start() {
        observePowerLifecycle()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        workspaceObservers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        workspaceObservers.removeAll()
        displayManager.cancelPendingDisplayOff()
        history.update(isHolding: false, reasons: [], agents: [], battery: battery.percent)
        powerManager.release()
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
            notify(title: "Wake My Mac off", body: "Wake assertions released.")
        } else {
            notify(title: "Wake My Mac on", body: settings.mode.explanation)
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
        notify(title: "Wake My Mac paused", body: "Wake assertions are paused temporarily.")
        refresh()
    }

    func updateSettings(_ newSettings: HoldSettings) {
        settings = newSettings
        isEnabled = newSettings.isEnabled
        SettingsStore.shared.save(newSettings)
        refresh()
    }

    func openSettings() {
        SettingsWindowController.shared.show(state: self)
    }

    func openDashboard() {
        DashboardWindowController.shared.show(state: self)
    }

    private func refresh() {
        battery = batteryMonitor.snapshot()
        rows = agentMonitor.scan()
        activityMatches = activityMonitor.scan(rules: settings.activityRules)

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
            // A previous idle cycle may have scheduled display sleep. Once work
            // resumes that delayed action must never fire during the new task.
            displayManager.cancelPendingDisplayOff()
            idleBeganAt = nil
            phase = .holding
            if heldSince == nil {
                heldSince = Date()
                notify(title: "Wake My Mac engaged", body: "A wake rule is active, so sleep is being held.")
            }
            powerManager.hold(reason: holdReason)
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
            powerManager.hold(reason: "Wake My Mac: waiting for idle grace period")
        } else {
            phase = .guarded("Agents have been idle for 30 seconds.")
            heldSince = nil
            idleBeganAt = nil
            wasHolding = false
            powerManager.release()
            notify(title: "Agent finished", body: "Idle grace period ended. Your Mac can sleep.")
            displayManager.turnDisplayOffAfter(seconds: settings.turnDisplayOffAfterFinishSeconds)
        }
    }

    private func currentGuardrail() -> String? {
        if settings.onlyWhenPluggedIn && !battery.isPluggedIn {
            return "Only-when-plugged-in mode is enabled."
        }

        if settings.respectLowPowerMode && battery.isLowPowerMode {
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
        case .agents: "Wake My Mac: automation is active"
        case .ssh: "Wake My Mac: SSH mode"
        case .manual: "Wake My Mac: manual mode"
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
