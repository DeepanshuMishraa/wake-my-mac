import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let state: AppState
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(state: AppState) {
        self.state = state
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        let dashboard = NSHostingController(rootView: PopoverView(state: state))
        popover.contentViewController = dashboard
        popover.contentSize = NSSize(width: 320, height: 330)
        popover.appearance = NSAppearance(named: .aqua)
        popover.animates = true
        popover.behavior = .transient

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "Wake My Mac")
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        state.onVisualStateChange = { [weak self] in
            self?.refreshStatusItem()
        }
        refreshStatusItem()
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        let hasBlocked = state.rows.contains { $0.blockedCount > 0 }
        let hasWorking = state.rows.contains { $0.activeCount > 0 }
        let symbol = (hasBlocked || hasWorking) ? "bolt.fill" : "laptopcomputer"
        let color: NSColor = hasBlocked ? .systemOrange : (hasWorking ? .systemGreen : .labelColor)
        let configuration = NSImage.SymbolConfiguration(paletteColors: [color])
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Wake My Mac")?
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
