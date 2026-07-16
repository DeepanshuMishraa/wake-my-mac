import Foundation
import Darwin
import MachO
import Security
import WakeHelperShared

private final class PowerOverrideController {
    private enum OwnershipState: String {
        case pending
        case owned
    }

    private static let pmsetDeadline: TimeInterval = 5
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
                    if FileManager.default.fileExists(atPath: ownershipMarker.path) {
                        try writeOwnershipMarker(.owned)
                        ownsOverride = true
                    }
                    return .success(true)
                }

                // Persist intent before changing global power policy. A crash at
                // any later point leaves enough information for startup recovery.
                try writeOwnershipMarker(.pending)
                try setSleepDisabled(true)
                try writeOwnershipMarker(.owned)
                ownsOverride = true
                return .success(true)
            }

            guard ownsOverride || FileManager.default.fileExists(atPath: ownershipMarker.path) else {
                return .success(!currentlyDisabled)
            }

            if currentlyDisabled {
                try setSleepDisabled(false)
            }
            try FileManager.default.removeItem(at: ownershipMarker)
            ownsOverride = false
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
        ownsOverride = true
        do {
            try setSleepDisabled(false)
            try FileManager.default.removeItem(at: ownershipMarker)
            ownsOverride = false
        } catch {
            // Keep the marker and ownership flag so the lease timer can retry.
        }
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
        let termination = DispatchSemaphore(value: 0)
        let readers = DispatchGroup()
        let output = PipeCapture()
        let errorOutput = PipeCapture()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        process.terminationHandler = { _ in termination.signal() }

        try process.run()
        readers.enter()
        DispatchQueue.global(qos: .utility).async {
            output.data = stdout.fileHandleForReading.readDataToEndOfFile()
            readers.leave()
        }
        readers.enter()
        DispatchQueue.global(qos: .utility).async {
            errorOutput.data = stderr.fileHandleForReading.readDataToEndOfFile()
            readers.leave()
        }

        if termination.wait(timeout: .now() + Self.pmsetDeadline) == .timedOut {
            process.terminate()
            if termination.wait(timeout: .now() + 1) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = termination.wait(timeout: .now() + 1)
            }
            if readers.wait(timeout: .now() + 1) == .timedOut {
                try? stdout.fileHandleForReading.close()
                try? stderr.fileHandleForReading.close()
                _ = readers.wait(timeout: .now() + 1)
            }
            throw HelperError.pmsetTimedOut
        }
        readers.wait()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorOutput.data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw HelperError.pmsetFailed(message ?? "pmset exited with status \(process.terminationStatus)")
        }
        return String(data: output.data, encoding: .utf8) ?? ""
    }

    private func writeOwnershipMarker(_ state: OwnershipState) throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        try Data("\(state.rawValue)\n".utf8).write(to: ownershipMarker, options: .atomic)
        let handle = try FileHandle(forWritingTo: ownershipMarker)
        defer { try? handle.close() }
        try handle.synchronize()
    }
}

private final class PipeCapture: @unchecked Sendable {
    var data = Data()
}

private enum HelperError: LocalizedError {
    case invalidPMSetOutput
    case verificationFailed
    case pmsetTimedOut
    case pmsetFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPMSetOutput:
            "Could not read the current macOS sleep policy."
        case .verificationFailed:
            "macOS did not apply the requested sleep policy."
        case .pmsetTimedOut:
            "Timed out while asking macOS to update the sleep policy."
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
        guard isAuthorized(connection) else { return false }
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
        let removedLease = ledger.removeExpired() > 0
        guard removedLease || (power.ownsOverride && !ledger.hasActiveLeases) else { return }
        _ = applyDesiredState()
    }

    private func applyDesiredState() -> (Bool, String?) {
        switch power.reconcile(shouldDisableSleep: ledger.hasActiveLeases) {
        case .success(let applied):
            (applied, nil)
        case .failure(let error):
            (false, error.localizedDescription)
        }
    }

    private func isAuthorized(_ connection: NSXPCConnection) -> Bool {
        let attributes = [kSecGuestAttributePid as String: NSNumber(value: connection.processIdentifier)] as CFDictionary
        var guestCode: SecCode?
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &guestCode) == errSecSuccess,
              let guestCode,
              let guestStaticCode = staticCode(for: guestCode),
              let applicationCode = authorizedApplicationCode(),
              let guestIdentity = signingIdentity(for: guestStaticCode),
              let applicationIdentity = signingIdentity(for: applicationCode) else {
            return false
        }
        return guestIdentity.identifier == WakeHelperConstants.applicationBundleIdentifier
            && guestIdentity.identifier == applicationIdentity.identifier
            && guestIdentity.uniqueHash == applicationIdentity.uniqueHash
    }

    private func staticCode(for code: SecCode) -> SecStaticCode? {
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess else { return nil }
        return staticCode
    }

    private func authorizedApplicationCode() -> SecStaticCode? {
        guard let executable = currentExecutableURL() else { return nil }
        let application = executable
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        guard application.pathExtension == "app" else { return nil }
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(application as CFURL, [], &staticCode) == errSecSuccess else {
            return nil
        }
        return staticCode
    }

    private func currentExecutableURL() -> URL? {
        var size: UInt32 = 0
        _ = _NSGetExecutablePath(nil, &size)
        var path = [CChar](repeating: 0, count: Int(size))
        guard _NSGetExecutablePath(&path, &size) == 0 else { return nil }
        return path.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return nil }
            return URL(
                fileURLWithFileSystemRepresentation: baseAddress,
                isDirectory: false,
                relativeTo: nil
            ).resolvingSymlinksInPath()
        }
    }

    private func signingIdentity(for code: SecStaticCode) -> (identifier: String, uniqueHash: Data)? {
        var information: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let values = information as? [CFString: Any],
              let identifier = values[kSecCodeInfoIdentifier] as? String,
              let uniqueHash = values[kSecCodeInfoUnique] as? Data else {
            return nil
        }
        return (identifier, uniqueHash)
    }
}

private let service = WakeHelperService()
private let listener = NSXPCListener(machServiceName: WakeHelperConstants.machServiceName)
listener.delegate = service
listener.resume()
RunLoop.current.run()
