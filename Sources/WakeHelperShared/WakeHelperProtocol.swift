import Foundation

public enum WakeHelperConstants {
    public static let applicationBundleIdentifier = "com.dipxsy.watchmymac"
    public static let machServiceName = "com.dipxsy.watchmymac.helper"
    public static let launchDaemonPlistName = "com.dipxsy.watchmymac.helper.plist"
    public static let defaultLeaseDuration: TimeInterval = 12
}

@objc(WakeHelperXPCProtocol)
public protocol WakeHelperXPCProtocol {
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

    func status(withReply reply: @escaping (Bool, Int, String?) -> Void)
}

public struct WakeLeaseLedger: Sendable {
    public struct Lease: Equatable, Sendable {
        public let reason: String
        public let expiresAt: Date

        public init(reason: String, expiresAt: Date) {
            self.reason = reason
            self.expiresAt = expiresAt
        }
    }

    public private(set) var leases: [String: Lease] = [:]

    public init() {}

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

    public var hasActiveLeases: Bool { !leases.isEmpty }
    public var activeCount: Int { leases.count }
}
