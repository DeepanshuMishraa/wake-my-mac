import AppKit
import Carbon
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusBarController?
    private var appState: AppState?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        IntegrationInstaller.install()
        let state = AppState()
        let status = StatusBarController(state: state)
        let shortcut = GlobalHotKey(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(optionKey | cmdKey)) {
            state.toggleEnabledFromShortcut()
        }

        appState = state
        statusController = status
        hotKey = shortcut

        setupMainMenu()

        NotificationService.shared.requestAuthorization()
        state.start()
        if CommandLine.arguments.contains("--open-dashboard") {
            state.openDashboard()
        }
        showDebugLaunchNoticeIfNeeded()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Wake My Mac")
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Open Wake My Mac", action: #selector(openDashboard), keyEquivalent: "o")
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        let updateItem = appMenu.addItem(withTitle: "Check for Updates…", action: #selector(UpdateService.checkForUpdates(_:)), keyEquivalent: "")
        updateItem.target = UpdateService.shared
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Wake My Mac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        mainMenu.addItem(appItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        mainMenu.addItem(windowItem)
        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    @objc private func openDashboard() { appState?.openDashboard() }
    @objc private func openSettings() { appState?.openSettings() }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.stop()
        hotKey?.unregister()
    }

    private func showDebugLaunchNoticeIfNeeded() {
        guard Bundle.main.bundleURL.pathExtension != "app" else { return }

        let alert = NSAlert()
        alert.messageText = "Wake My Mac is running outside an app bundle"
        alert.informativeText = "Xcode is launching the SwiftPM executable directly, so macOS notifications are disabled for this debug run. Use `make app` and open `build/Wake My Mac.app` for the real menu bar app behavior."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
