import AppKit
import Combine
import Sparkle

enum UpdateStatus: Equatable {
    case unavailable
    case ready
    case checking
    case available(version: String)
    case current
    case failed(message: String)

    var title: String {
        switch self {
        case .unavailable: "Updates unavailable"
        case .ready: "Ready to check"
        case .checking: "Checking for updates…"
        case .available(let version): "Version \(version) is available"
        case .current: "Wake My Mac is up to date"
        case .failed: "Couldn’t check for updates"
        }
    }

    var detail: String {
        switch self {
        case .unavailable:
            "Install a published build to receive signed updates."
        case .ready:
            "Updates are checked automatically and downloaded securely."
        case .checking:
            "Looking for the latest signed release."
        case .available:
            "Sparkle will guide you through the update."
        case .current:
            "You already have the newest available version."
        case .failed(let message):
            message
        }
    }

    var symbolName: String {
        switch self {
        case .unavailable: "exclamationmark.triangle.fill"
        case .ready: "arrow.triangle.2.circlepath"
        case .checking: "arrow.triangle.2.circlepath"
        case .available: "arrow.down.circle.fill"
        case .current: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
final class UpdateService: NSObject, ObservableObject, SPUUpdaterDelegate, NSMenuItemValidation {
    static let shared = UpdateService()

    @Published private(set) var status: UpdateStatus = .unavailable
    @Published private(set) var automaticallyChecksForUpdates = false
    @Published private(set) var automaticallyDownloadsUpdates = false

    private var controller: SPUStandardUpdaterController?

    override private init() {
        super.init()

        let info = Bundle.main.infoDictionary ?? [:]
        let feedURL = info["SUFeedURL"] as? String ?? ""
        let publicKey = info["SUPublicEDKey"] as? String ?? ""
        guard !feedURL.isEmpty, !publicKey.isEmpty else { return }

        let updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
        controller = updaterController
        status = .ready
        syncPreferences()

        if updaterController.updater.automaticallyChecksForUpdates {
            status = .checking
            updaterController.updater.checkForUpdatesInBackground()
        }
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
        status = .checking
        controller.checkForUpdates(sender)
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        guard let updater = controller?.updater else { return }
        updater.automaticallyChecksForUpdates = enabled
        syncPreferences()
    }

    func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        guard let updater = controller?.updater else { return }
        updater.automaticallyDownloadsUpdates = enabled
        syncPreferences()
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menuItem.action == #selector(checkForUpdates(_:)) ? canCheckForUpdates : true
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        status = .available(version: item.displayVersionString)
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        status = .current
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: (any Error)?
    ) {
        syncPreferences()
        guard let error else {
            if status == .checking {
                status = .ready
            }
            return
        }
        if status == .checking {
            status = .failed(message: error.localizedDescription)
        }
    }

    func updater(
        _ updater: SPUUpdater,
        failedToDownloadUpdate item: SUAppcastItem,
        error: any Error
    ) {
        status = .failed(message: error.localizedDescription)
    }

    private func syncPreferences() {
        automaticallyChecksForUpdates =
            controller?.updater.automaticallyChecksForUpdates ?? false
        automaticallyDownloadsUpdates =
            controller?.updater.automaticallyDownloadsUpdates ?? false
    }
}
