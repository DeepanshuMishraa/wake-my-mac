import Foundation

final class DisplayManager {
    private var pendingDisplayOff: DispatchWorkItem?
    private let turnDisplayOff: () -> Void

    init(turnDisplayOff: @escaping () -> Void = DisplayManager.performDisplayOff) {
        self.turnDisplayOff = turnDisplayOff
    }

    var hasPendingDisplayOff: Bool {
        pendingDisplayOff != nil
    }

    func turnDisplayOffAfter(seconds: Int) {
        guard seconds >= 0 else { return }
        cancelPendingDisplayOff()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingDisplayOff = nil
            self.turnDisplayOff()
        }
        pendingDisplayOff = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(seconds), execute: work)
    }

    func cancelPendingDisplayOff() {
        pendingDisplayOff?.cancel()
        pendingDisplayOff = nil
    }

    private static func performDisplayOff() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }

    deinit {
        pendingDisplayOff?.cancel()
    }
}
