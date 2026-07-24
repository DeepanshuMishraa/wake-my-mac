import Foundation
import Darwin
import MachO
import Security
import WakeHelperShared

private final class PowerOverrideController {
    private enum OwnershipState: String, Codable {
        case pending
        case owned
    }

    private struct OwnershipRecord: Codable {
        let state: OwnershipState
        let previousSleepDisabled: Bool
    }

    private static let pmsetDeadline: TimeInterval = 5
    // Preserve the original storage path so upgrades can restore owned power policy safely.
    private let stateDirectory = URL(fileURLWithPath: "/Library/Application Support/Wake My Mac", isDirectory: true)
    private var ownershipMarker: URL {
        stateDirectory.appendingPathComponent("helper-owned-sleep-override")
    }

    private var ownershipRecord: OwnershipRecord?
    var ownsOverride: Bool { ownershipRecord != nil }

    init() {
        ownershipRecord = Self.loadOwnershipRecord(from: ownershipMarker)
    }

    func reconcile(shouldDisableSleep: Bool) -> Result<Bool, Error> {
        do {
            let currentlyDisabled = try readSleepDisabled()

            if shouldDisableSleep {
                if ownershipRecord == nil {
                    let pending = OwnershipRecord(
                        state: .pending,
                        previousSleepDisabled: currentlyDisabled
                    )
                    try writeOwnershipRecord(pending)
                    ownershipRecord = pending
                }

                if !currentlyDisabled {
                    try setSleepDisabled(true)
                }
                guard let ownershipRecord else { throw HelperError.missingOwnershipRecord }
                let owned = OwnershipRecord(
                    state: .owned,
                    previousSleepDisabled: ownershipRecord.previousSleepDisabled
                )
                try writeOwnershipRecord(owned)
                self.ownershipRecord = owned
                return .success(true)
            }

            guard let ownershipRecord else {
                // Another tool may own SleepDisabled. Releasing StayRunning's
                // request must not overwrite that external policy.
                return .success(true)
            }

            if currentlyDisabled != ownershipRecord.previousSleepDisabled {
                try setSleepDisabled(ownershipRecord.previousSleepDisabled)
            }
            try FileManager.default.removeItem(at: ownershipMarker)
            self.ownershipRecord = nil
            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    func currentStatus() -> Result<Bool, Error> {
        Result { try readSleepDisabled() }
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

    private func writeOwnershipRecord(_ record: OwnershipRecord) throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        try JSONEncoder().encode(record).write(to: ownershipMarker, options: .atomic)
        let handle = try FileHandle(forWritingTo: ownershipMarker)
        defer { try? handle.close() }
        try handle.synchronize()
    }

    private static func loadOwnershipRecord(from url: URL) -> OwnershipRecord? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let record = try? JSONDecoder().decode(OwnershipRecord.self, from: data) {
            return record
        }
        // Older helpers wrote only "pending" or "owned". They only created
        // the marker when changing SleepDisabled from off to on.
        let legacyState = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard legacyState == OwnershipState.pending.rawValue || legacyState == OwnershipState.owned.rawValue else {
            return nil
        }
        return OwnershipRecord(state: .owned, previousSleepDisabled: false)
    }
}

private final class PersistentWakeStore {
    // Preserve the original storage path so existing persistent requests survive the rebrand.
    private let stateDirectory = URL(fileURLWithPath: "/Library/Application Support/Wake My Mac", isDirectory: true)
    private var stateFile: URL { stateDirectory.appendingPathComponent("persistent-wake-requests.json") }

    func load() throws -> WakeRequestLedger.PersistentSnapshot {
        guard FileManager.default.fileExists(atPath: stateFile.path) else {
            return WakeRequestLedger.PersistentSnapshot()
        }
        return try JSONDecoder().decode(
            WakeRequestLedger.PersistentSnapshot.self,
            from: Data(contentsOf: stateFile)
        )
    }

    func save(_ snapshot: WakeRequestLedger.PersistentSnapshot) throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true)
        try JSONEncoder().encode(snapshot).write(to: stateFile, options: .atomic)
        let handle = try FileHandle(forWritingTo: stateFile)
        defer { try? handle.close() }
        try handle.synchronize()
    }
}

private final class PipeCapture: @unchecked Sendable {
    var data = Data()
}

private enum HelperError: LocalizedError {
    case missingOwnershipRecord
    case invalidPMSetOutput
    case verificationFailed
    case pmsetTimedOut
    case pmsetFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingOwnershipRecord:
            "StayRunning lost ownership state while enabling the sleep override. The previous power policy is preserved; retry enabling wake protection."
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
    private let power: PowerOverrideController
    private let persistentStore: PersistentWakeStore
    private var ledger: WakeRequestLedger
    private var persistentStateLoadError: String?
    private var timer: DispatchSourceTimer?

    override init() {
        let persistentStore = PersistentWakeStore()
        let loadedSnapshot: WakeRequestLedger.PersistentSnapshot
        let loadError: String?
        do {
            loadedSnapshot = try persistentStore.load()
            loadError = nil
        } catch {
            loadedSnapshot = WakeRequestLedger.PersistentSnapshot()
            loadError = error.localizedDescription
        }
        self.persistentStore = persistentStore
        power = PowerOverrideController()
        ledger = WakeRequestLedger(persistentSnapshot: loadedSnapshot)
        persistentStateLoadError = loadError
        super.init()
        _ = applyDesiredState()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 1, repeating: 5)
        timer.setEventHandler { [weak self] in
            self?.reconcileRequests()
        }
        timer.resume()
        self.timer = timer
    }

    func activatePersistentWake(
        identifier: String,
        reason: String,
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        stateLock.lock()
        let previousLedger = ledger
        let previousLoadError = persistentStateLoadError
        guard ledger.activatePersistent(identifier: identifier, reason: reason) else {
            stateLock.unlock()
            return reply(false, "Persistent wake requires a non-empty identifier and reason.")
        }
        do {
            if previousLedger.persistentSnapshot != ledger.persistentSnapshot || persistentStateLoadError != nil {
                try persistentStore.save(ledger.persistentSnapshot)
            }
            persistentStateLoadError = nil
        } catch {
            ledger = previousLedger
            persistentStateLoadError = previousLoadError
            stateLock.unlock()
            return reply(false, "Could not save persistent wake intent: \(error.localizedDescription)")
        }
        let result = applyDesiredState()
        stateLock.unlock()
        reply(result.0, result.1)
    }

    func releasePersistentWake(identifier: String, withReply reply: @escaping (Bool, String?) -> Void) {
        stateLock.lock()
        let previousLedger = ledger
        let previousLoadError = persistentStateLoadError
        ledger.releasePersistent(identifier: identifier)
        do {
            if previousLedger.persistentSnapshot != ledger.persistentSnapshot || persistentStateLoadError != nil {
                try persistentStore.save(ledger.persistentSnapshot)
            }
            persistentStateLoadError = nil
        } catch {
            ledger = previousLedger
            persistentStateLoadError = previousLoadError
            stateLock.unlock()
            return reply(false, "Could not save the restored sleep intent: \(error.localizedDescription)")
        }
        let result = applyDesiredState()
        stateLock.unlock()
        reply(result.0, result.1)
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
        guard ledger.renew(identifier: identifier, reason: reason, duration: min(duration, 300)) else {
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

    func status(withReply reply: @escaping (Bool, Int, Int, Int, String?) -> Void) {
        stateLock.lock()
        ledger.removeExpired()
        let leaseCount = ledger.activeLeaseCount
        let persistentCount = ledger.activePersistentCount
        let result = power.currentStatus()
        let loadError = persistentStateLoadError
        stateLock.unlock()
        if let loadError {
            return reply(
                false,
                leaseCount,
                persistentCount,
                WakeHelperConstants.protocolVersion,
                "Could not read saved wake intent: \(loadError). The existing sleep override was preserved; explicitly enable or disable StayRunning to repair it."
            )
        }
        switch result {
        case .success(let disabled):
            reply(disabled, leaseCount, persistentCount, WakeHelperConstants.protocolVersion, nil)
        case .failure(let error):
            reply(false, leaseCount, persistentCount, WakeHelperConstants.protocolVersion, error.localizedDescription)
        }
    }

    private func reconcileRequests() {
        stateLock.lock()
        defer { stateLock.unlock() }
        ledger.removeExpired()
        _ = applyDesiredState()
    }

    private func applyDesiredState() -> (Bool, String?) {
        let preserveUnrecoverableOverride = persistentStateLoadError != nil && power.ownsOverride
        switch power.reconcile(shouldDisableSleep: ledger.shouldDisableSleep || preserveUnrecoverableOverride) {
        case .success(let applied):
            return (applied, nil)
        case .failure(let error):
            return (false, error.localizedDescription)
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
