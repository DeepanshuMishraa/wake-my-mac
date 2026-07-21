import Foundation

public enum WakeHelperConstants {
    public static let applicationBundleIdentifier = "com.dipxsy.watchmymac"
    public static let machServiceName = "com.dipxsy.watchmymac.helper.v2"
    public static let launchDaemonPlistName = "com.dipxsy.watchmymac.helper.v2.plist"
    public static let legacyLaunchDaemonPlistNames = ["com.dipxsy.watchmymac.helper.plist"]
    public static let defaultLeaseDuration: TimeInterval = 120
    public static let protocolVersion = 2
    public static let persistentRequestIdentifier = "wake-my-mac-persistent"
    public static let leasedRequestIdentifier = "wake-my-mac-agent-activity"
}

@objc(WakeHelperXPCProtocol)
public protocol WakeHelperXPCProtocol {
    func activatePersistentWake(
        identifier: String,
        reason: String,
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func releasePersistentWake(
        identifier: String,
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func renewLease(
        identifier: String,
        reason: String,
        duration: TimeInterval,
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func releaseLease(
        identifier: String,
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func status(
        withReply reply: @escaping (Bool, Int, Int, Int, String?) -> Void
    )
}

public struct WakeRequestLedger: Sendable {
    public struct PersistentSnapshot: Codable, Equatable, Sendable {
        public let holds: [String: String]

        public init(holds: [String: String] = [:]) {
            self.holds = holds
        }
    }

    public struct Lease: Equatable, Sendable {
        public let reason: String
        public let expiresAt: Date

        public init(reason: String, expiresAt: Date) {
            self.reason = reason
            self.expiresAt = expiresAt
        }
    }

    public private(set) var leases: [String: Lease] = [:]
    private var persistentHolds: [String: String]

    public init(persistentSnapshot: PersistentSnapshot = PersistentSnapshot()) {
        persistentHolds = persistentSnapshot.holds
    }

    @discardableResult
    public mutating func activatePersistent(identifier: String, reason: String) -> Bool {
        guard !identifier.isEmpty, !reason.isEmpty else { return false }
        persistentHolds[identifier] = reason
        return true
    }

    @discardableResult
    public mutating func releasePersistent(identifier: String) -> Bool {
        persistentHolds.removeValue(forKey: identifier) != nil
    }

    @discardableResult
    public mutating func renew(
        identifier: String,
        reason: String,
        duration: TimeInterval,
        now: Date = Date()
    ) -> Bool {
        guard !identifier.isEmpty, duration > 0 else { return false }
        leases[identifier] = Lease(
            reason: reason,
            expiresAt: now.addingTimeInterval(duration)
        )
        return true
    }

    @discardableResult
    public mutating func release(identifier: String) -> Bool {
        leases.removeValue(forKey: identifier) != nil
    }

    @discardableResult
    public mutating func removeExpired(now: Date = Date()) -> Int {
        let expired = leases.filter { $0.value.expiresAt <= now }.map(\.key)
        expired.forEach { leases.removeValue(forKey: $0) }
        return expired.count
    }

    public var persistentSnapshot: PersistentSnapshot {
        PersistentSnapshot(holds: persistentHolds)
    }

    public var shouldDisableSleep: Bool { !persistentHolds.isEmpty || !leases.isEmpty }
    public var hasActiveRequests: Bool { shouldDisableSleep }
    public var activeLeaseCount: Int { leases.count }
    public var activePersistentCount: Int { persistentHolds.count }

    // Compatibility for callers that only manage expiring requests.
    public var hasActiveLeases: Bool { !leases.isEmpty }
    public var activeCount: Int { leases.count }
}
