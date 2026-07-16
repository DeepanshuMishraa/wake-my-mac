import Foundation
import WakeHelperShared

private final class PowerOverrideController {
    private let stateDirectory = URL(fileURLWithPath: "/Library/Application Support/Wake My Mac", isDirectory: true)
    private var ownershipMarker: URL {
        stateDirectory.appendingPathComponent("helper-owned-sleep-override")
    }

    private(set) var ownsOverride = false

    init() {
        recoverStaleOverrideIfNeeded()
    }

    func reconcile(shouldDisableSleep: Bool) -> Result<Bool, Error> {
        do {
            let currentlyDisabled = try readSleepDisabled()

            if shouldDisableSleep {
                if currentlyDisabled {
                    return .success(true)
                }

                try setSleepDisabled(true)
                ownsOverride = true
                try writeOwnershipMarker()
                return .success(true)
            }

            guard ownsOverride || FileManager.default.fileExists(atPath: ownershipMarker.path) else {
                return .success(!currentlyDisabled)
            }

            if currentlyDisabled {
                try setSleepDisabled(false)
            }
            ownsOverride = false
            try? FileManager.default.removeItem(at: ownershipMarker)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func currentStatus() -> Result<Bool, Error> {
        Result { try readSleepDisabled() }
    }

    private func recoverStaleOverrideIfNeeded() {
        guard FileManager.default.fileExists(atPath: ownershipMarker.path) else { return }
        _ = try? runPMSet(arguments: ["-a", "disablesleep", "0"])
        try? FileManager.default.removeItem(at: ownershipMarker)
        ownsOverride = false
    }

    private func readSleepDisabled() throws -> Bool {
        let output = try runPMSet(arguments: ["-g", "live"])
        guard let line = output.split(separator: "\n").first(where: { $0.contains("SleepDisabled") }) else {
            throw HelperError.invalidPMSetOutput
        }
        return line.split(whereSeparator: \.isWhitespace).last == "1"
    }

    private func setSleepDisabled(_ disabled: Bool) throws {
        _ = try runPMSet(arguments: ["-a", "disablesleep", disabled ? "1" : "0"])
        guard try readSleepDisabled() == disabled else {
            throw HelperError.verificationFailed
        }
    }

    private func runPMSet(arguments: [String]) throws -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorOutput, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw HelperError.pmsetFailed(message ?? "pmset exited with status \(process.terminationStatus)")
        }
        return String(data: output, encoding: .utf8) ?? ""
    }

    private func writeOwnershipMarker() throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        try Data("owned\n".utf8).write(to: ownershipMarker, options: .atomic)
    }
}

private enum HelperError: LocalizedError {
    case invalidPMSetOutput
    case verificationFailed
    case pmsetFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPMSetOutput:
            "Could not read the current macOS sleep policy."
        case .verificationFailed:
            "macOS did not apply the requested sleep policy."
        case .pmsetFailed(let message):
            message
        }
    }
}

private final class WakeHelperService: NSObject, WakeHelperXPCProtocol, NSXPCListenerDelegate, @unchecked Sendable {
    private let stateLock = NSLock()
    private let power = PowerOverrideController()
    private var ledger = WakeLeaseLedger()
    private var timer: DispatchSourceTimer?

    override init() {
        super.init()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            self?.expireLeases()
        }
        timer.resume()
        self.timer = timer
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: WakeHelperXPCProtocol.self)
        connection.exportedObject = self
        connection.resume()
        return true
    }

    func renewLease(
        identifier: String,
        reason: String,
        duration: TimeInterval,
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        stateLock.lock()
        guard ledger.renew(identifier: identifier, reason: reason, duration: min(duration, 60)) else {
            stateLock.unlock()
            return reply(false, "Invalid wake lease.")
        }
        let result = applyDesiredState()
        stateLock.unlock()
        reply(result.0, result.1)
    }

    func releaseLease(identifier: String, withReply reply: @escaping (Bool, String?) -> Void) {
        stateLock.lock()
        ledger.release(identifier: identifier)
        let result = applyDesiredState()
        stateLock.unlock()
        reply(result.0, result.1)
    }

    func status(withReply reply: @escaping (Bool, Int, String?) -> Void) {
        stateLock.lock()
        ledger.removeExpired()
        let count = ledger.activeCount
        let result = power.currentStatus()
        stateLock.unlock()
        switch result {
        case .success(let disabled): reply(disabled, count, nil)
        case .failure(let error): reply(false, count, error.localizedDescription)
        }
    }

    private func expireLeases() {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard ledger.removeExpired() > 0 else { return }
        _ = applyDesiredState()
    }

    private func applyDesiredState() -> (Bool, String?) {
        switch power.reconcile(shouldDisableSleep: ledger.hasActiveLeases) {
        case .success:
            (true, nil)
        case .failure(let error):
            (false, error.localizedDescription)
        }
    }
}

private let service = WakeHelperService()
private let listener = NSXPCListener(machServiceName: WakeHelperConstants.machServiceName)
listener.delegate = service
listener.resume()
RunLoop.current.run()
