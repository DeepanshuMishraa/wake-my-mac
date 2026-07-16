import Foundation

final class DisplayManager {
    private var pendingDisplayOff: DispatchWorkItem?
    private let turnDisplayOff: () -> Void
    private let stateLock = NSLock()
    private var displayOffAllowed = true

    init(turnDisplayOff: @escaping () -> Void = DisplayManager.performDisplayOff) {
        self.turnDisplayOff = turnDisplayOff
    }

    var hasPendingDisplayOff: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return pendingDisplayOff != nil
    }

    func setDisplayOffAllowed(_ allowed: Bool) {
        stateLock.lock()
        displayOffAllowed = allowed
        stateLock.unlock()
    }

    func turnDisplayOffAfter(seconds: Int) {
        guard seconds >= 0 else { return }
        cancelPendingDisplayOff()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.stateLock.lock()
            self.pendingDisplayOff = nil
            let allowed = self.displayOffAllowed
            self.stateLock.unlock()
            guard allowed else { return }
            self.turnDisplayOff()
        }
        stateLock.lock()
        pendingDisplayOff = work
        stateLock.unlock()
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + .seconds(seconds), execute: work)
    }

    func turnDisplayOffNow() {
        cancelPendingDisplayOff()
        turnDisplayOff()
    }

    func cancelPendingDisplayOff() {
        stateLock.lock()
        let pending = pendingDisplayOff
        pendingDisplayOff = nil
        stateLock.unlock()
        pending?.cancel()
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
