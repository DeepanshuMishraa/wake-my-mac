import AppKit
import Sparkle

@MainActor
final class UpdateService: NSObject {
    static let shared = UpdateService()

    private let controller: SPUStandardUpdaterController?

    override private init() {
        let info = Bundle.main.infoDictionary ?? [:]
        let feedURL = info["SUFeedURL"] as? String ?? ""
        let publicKey = info["SUPublicEDKey"] as? String ?? ""
        if feedURL.isEmpty || publicKey.isEmpty {
            controller = nil
        } else {
            controller = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        }
        super.init()
    }

    var isConfigured: Bool { controller != nil }
    var canCheckForUpdates: Bool { controller?.updater.canCheckForUpdates ?? false }

    @objc func checkForUpdates(_ sender: Any?) {
        guard let controller else {
            let alert = NSAlert()
            alert.messageText = "Updates are unavailable in this build"
            alert.informativeText = "Install a published Wake My Mac release to receive updates from GitHub Releases."
            alert.alertStyle = .informational
            alert.runModal()
            return
        }
        controller.checkForUpdates(sender)
    }
}
