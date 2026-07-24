import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let state: AppState
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var areAgentsExpanded = false
    private var appDeactivationObserver: NSObjectProtocol?

    init(state: AppState) {
        self.state = state
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        let dashboard = NSHostingController(
            rootView: PopoverView(state: state) { [weak self] expanded in
                self?.setAgentsExpanded(expanded)
            }
        )
        popover.contentViewController = dashboard
        popover.contentSize = preferredPopoverSize
        popover.animates = true
        popover.behavior = .transient
        popover.delegate = self

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "StayRunning")
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        state.onVisualStateChange = { [weak self] in
            self?.refreshStatusItem()
            self?.refreshPopoverSize()
        }
        refreshStatusItem()
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        let hasBlocked = state.rows.contains { $0.blockedCount > 0 }
        let wakeFailed: Bool
        if case .failed = state.reliableWakeState { wakeFailed = true } else { wakeFailed = false }
        let isReliablyAwake = state.reliableWakeState == .active
        let symbol = wakeFailed ? "exclamationmark.triangle.fill" : (isReliablyAwake ? "bolt.fill" : "laptopcomputer")
        let color: NSColor = (hasBlocked || wakeFailed) ? .systemOrange : (isReliablyAwake ? .systemGreen : .labelColor)
        let configuration = NSImage.SymbolConfiguration(paletteColors: [color])
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "StayRunning")?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = false
        button.image = image
        button.contentTintColor = nil
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Accessory apps have no regular window to activate them. Activating first
            // avoids a focus race where AppKit immediately dismisses (or never presents)
            // a transient popover when another application owns the menu bar interaction.
            NSApp.activate(ignoringOtherApps: true)
            refreshPopoverSize()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            DispatchQueue.main.async { [weak self] in
                self?.focusPopover()
                self?.startDismissalMonitoring()
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        stopDismissalMonitoring()
    }

    private var preferredPopoverSize: NSSize {
        NSSize(
            width: PopoverView.preferredWidth,
            height: PopoverView.preferredHeight(
                agentCount: state.rows.count,
                agentsExpanded: areAgentsExpanded,
                showsReliableWakeSetup: state.reliableWakeState.needsSetupAction
            )
        )
    }

    private func setAgentsExpanded(_ expanded: Bool) {
        guard areAgentsExpanded != expanded else { return }
        areAgentsExpanded = expanded
        refreshPopoverSize()
    }

    private func refreshPopoverSize() {
        let preferredSize = preferredPopoverSize
        guard popover.contentSize != preferredSize else { return }
        popover.contentSize = preferredSize
    }

    private func focusPopover() {
        guard popover.isShown,
              let contentView = popover.contentViewController?.view,
              let window = contentView.window else { return }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKey()
        window.makeFirstResponder(contentView)
    }

    private func startDismissalMonitoring() {
        guard appDeactivationObserver == nil else { return }
        appDeactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.popover.isShown else { return }
                self.popover.performClose(nil)
            }
        }
    }

    private func stopDismissalMonitoring() {
        guard let appDeactivationObserver else { return }
        NotificationCenter.default.removeObserver(appDeactivationObserver)
        self.appDeactivationObserver = nil
    }
}
