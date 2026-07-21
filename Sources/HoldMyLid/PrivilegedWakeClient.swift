import Foundation
import ServiceManagement
import WakeHelperShared

enum ReliableWakeState: Equatable {
    case checking
    case setupRequired
    case approvalRequired
    case ready
    case activating
    case active
    case failed(String)

    var needsSetupAction: Bool {
        switch self {
        case .setupRequired, .approvalRequired, .failed: true
        case .checking, .ready, .activating, .active: false
        }
    }

    var isHelperReady: Bool {
        switch self {
        case .ready, .activating, .active: true
        case .checking, .setupRequired, .approvalRequired, .failed: false
        }
    }
}

enum WakeRequestKind: Equatable {
    case leased
    case persistent
}

extension HoldMode {
    var wakeRequestKind: WakeRequestKind {
        switch self {
        case .agents: .leased
        case .ssh, .manual: .persistent
        }
    }
}

@MainActor
final class PrivilegedWakeClient {
    var onStateChange: ((ReliableWakeState) -> Void)?

    private let service = SMAppService.daemon(plistName: WakeHelperConstants.launchDaemonPlistName)
    private let legacyServices = WakeHelperConstants.legacyLaunchDaemonPlistNames.map(SMAppService.daemon(plistName:))
    private let registeredVersionKey = "WakeMyMacHelper.registeredVersion"
    private let leaseIdentifier = WakeHelperConstants.leasedRequestIdentifier
    private var connection: NSXPCConnection?
    private var desiredRequest: (kind: WakeRequestKind, reason: String)?
    private var generation = 0
    private var isRefreshingRegistration = false
    private var isCleaningLegacyServices = false
    private var didCleanLegacyServices = false
    private(set) var state: ReliableWakeState = .checking {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    func refreshServiceStatus() {
        if !didCleanLegacyServices {
            cleanLegacyServices()
            return
        }
        switch service.status {
        case .enabled:
            if registeredVersion != expectedRegistrationVersion && !isRefreshingRegistration {
                refreshRegistration()
                return
            }
            state = desiredRequest == nil ? .ready : .activating
            if let desiredRequest {
                hold(reason: desiredRequest.reason, kind: desiredRequest.kind)
            }
        case .requiresApproval:
            invalidateConnection()
            state = .approvalRequired
        case .notRegistered, .notFound:
            invalidateConnection()
            state = .setupRequired
        @unknown default:
            invalidateConnection()
            state = .failed("The reliable wake helper has an unknown macOS status.")
        }
    }

    private func cleanLegacyServices() {
        guard !isCleaningLegacyServices else { return }
        let registeredServices = legacyServices.filter { $0.status == .enabled || $0.status == .requiresApproval }
        guard !registeredServices.isEmpty else {
            didCleanLegacyServices = true
            refreshServiceStatus()
            return
        }

        isCleaningLegacyServices = true
        let group = DispatchGroup()
        let errors = LegacyCleanupErrors()
        for legacyService in registeredServices {
            group.enter()
            legacyService.unregister { error in
                if let error { errors.append(error.localizedDescription) }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isCleaningLegacyServices = false
            self.didCleanLegacyServices = true
            if let message = errors.first {
                self.state = .failed("Could not remove the outdated wake helper: \(message). Normal sleep remains enabled; retry from Settings.")
            } else {
                self.refreshServiceStatus()
            }
        }
    }

    func registerHelper() {
        if service.status == .enabled {
            refreshRegistration()
            return
        }
        registerCurrentHelper()
    }

    private func registerCurrentHelper() {
        state = .checking
        do {
            try service.register()
            registeredVersion = expectedRegistrationVersion
            refreshServiceStatus()
            if service.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
        } catch {
            refreshServiceStatus()
            if case .setupRequired = state {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func refreshRegistration() {
        guard !isRefreshingRegistration else { return }
        isRefreshingRegistration = true
        state = .checking
        invalidateConnection()
        service.unregister { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.isRefreshingRegistration = false
                if let error {
                    self.state = .failed("Could not replace the outdated wake helper: \(error.localizedDescription). The existing power policy was preserved; retry from Settings.")
                    return
                }
                self.registerCurrentHelper()
            }
        }
    }

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func hold(reason: String, kind: WakeRequestKind) {
        let nextRequest = (kind: kind, reason: reason)
        if desiredRequest?.kind != kind || desiredRequest?.reason != reason {
            generation += 1
        }
        desiredRequest = nextRequest
        guard service.status == .enabled else {
            refreshServiceStatus()
            return
        }

        let currentGeneration = generation
        if state != .active {
            state = .activating
        }

        guard let proxy = remoteProxy() else {
            state = .failed("Could not connect to the reliable wake helper.")
            return
        }
        let leaseIdentifier = self.leaseIdentifier

        switch kind {
        case .persistent:
            proxy.releaseLease(identifier: leaseIdentifier) { [weak self] success, message in
                guard success else {
                    self?.finishActivation(
                        generation: currentGeneration,
                        expectedKind: kind,
                        success: false,
                        message: message
                    )
                    return
                }
                proxy.activatePersistentWake(
                    identifier: WakeHelperConstants.persistentRequestIdentifier,
                    reason: reason
                ) { [weak self] success, message in
                    self?.finishActivation(
                        generation: currentGeneration,
                        expectedKind: kind,
                        success: success,
                        message: message
                    )
                }
            }
        case .leased:
            proxy.releasePersistentWake(identifier: WakeHelperConstants.persistentRequestIdentifier) { [weak self] success, message in
                guard success else {
                    self?.finishActivation(
                        generation: currentGeneration,
                        expectedKind: kind,
                        success: false,
                        message: message
                    )
                    return
                }
                proxy.renewLease(
                    identifier: leaseIdentifier,
                    reason: reason,
                    duration: WakeHelperConstants.defaultLeaseDuration
                ) { [weak self] success, message in
                    self?.finishActivation(
                        generation: currentGeneration,
                        expectedKind: kind,
                        success: success,
                        message: message
                    )
                }
            }
        }
    }

    func releaseAll() {
        desiredRequest = nil
        generation += 1
        let currentGeneration = generation

        guard service.status == .enabled else {
            refreshServiceStatus()
            return
        }
        guard let proxy = remoteProxy() else {
            state = .failed("Could not connect to the reliable wake helper to restore normal sleep.")
            return
        }

        proxy.releaseLease(identifier: leaseIdentifier) { [weak self] success, message in
            guard success else {
                self?.finishRelease(generation: currentGeneration, success: false, message: message)
                return
            }
            proxy.releasePersistentWake(identifier: WakeHelperConstants.persistentRequestIdentifier) { [weak self] success, message in
                self?.finishRelease(generation: currentGeneration, success: success, message: message)
            }
        }
    }

    func shutdown() {
        let shouldReleaseLease = desiredRequest?.kind == .leased
        desiredRequest = nil
        generation += 1

        guard shouldReleaseLease, service.status == .enabled, let proxy = remoteProxy(), let activeConnection = connection else {
            invalidateConnection()
            return
        }

        proxy.releaseLease(identifier: leaseIdentifier) { [weak self] _, _ in
            Task { @MainActor in
                self?.finishShutdown(connection: activeConnection)
            }
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.finishShutdown(connection: activeConnection)
        }
    }

    private func finishActivation(
        generation: Int,
        expectedKind: WakeRequestKind,
        success: Bool,
        message: String?
    ) {
        Task { @MainActor [weak self] in
            guard let self,
                  self.generation == generation,
                  self.desiredRequest?.kind == expectedKind else { return }
            guard success else {
                self.state = .failed(message ?? "macOS did not enable reliable wake.")
                return
            }
            self.verifyStatus(generation: generation, expectedKind: expectedKind)
        }
    }

    private func verifyStatus(generation: Int, expectedKind: WakeRequestKind) {
        guard let proxy = remoteProxy() else {
            state = .failed("Wake protection was requested, but its effective system state could not be verified.")
            return
        }
        proxy.status { [weak self] sleepDisabled, leaseCount, persistentCount, protocolVersion, message in
            Task { @MainActor in
                guard let self,
                      self.generation == generation,
                      self.desiredRequest?.kind == expectedKind else { return }
                guard protocolVersion == WakeHelperConstants.protocolVersion else {
                    self.state = .failed("The reliable wake helper is out of date. Re-enable it from Settings, then retry.")
                    return
                }
                let hasExpectedRequest = switch expectedKind {
                case .leased: leaseCount > 0
                case .persistent: persistentCount > 0
                }
                if sleepDisabled && hasExpectedRequest {
                    self.state = .active
                } else {
                    self.state = .failed(message ?? "The helper accepted wake protection, but macOS still allows system sleep. Your previous power settings remain recoverable; retry or reinstall the helper.")
                }
            }
        }
    }

    private func finishRelease(generation: Int, success: Bool, message: String?) {
        Task { @MainActor [weak self] in
            guard let self, self.generation == generation, self.desiredRequest == nil else { return }
            guard success else {
                self.state = .failed(message ?? "Wake My Mac could not restore its previous sleep policy. Retry turning it off; the ownership record was preserved for recovery.")
                return
            }
            self.verifyReleasedStatus(generation: generation)
        }
    }

    private func verifyReleasedStatus(generation: Int) {
        guard let proxy = remoteProxy() else {
            state = .failed("Wake My Mac released protection, but could not verify the restored policy. Retry turning it off.")
            return
        }
        proxy.status { [weak self] _, leaseCount, persistentCount, protocolVersion, message in
            Task { @MainActor in
                guard let self, self.generation == generation, self.desiredRequest == nil else { return }
                guard protocolVersion == WakeHelperConstants.protocolVersion else {
                    self.state = .failed("The reliable wake helper is out of date. Re-enable it from Settings, then retry.")
                    return
                }
                self.state = leaseCount == 0 && persistentCount == 0
                    ? .ready
                    : .failed(message ?? "The helper still reports active Wake My Mac requests. Retry turning protection off; the previous power policy remains recorded.")
            }
        }
    }

    private func remoteProxy() -> WakeHelperXPCProtocol? {
        let connection = connection ?? makeConnection()
        self.connection = connection
        return connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.connection?.invalidate()
                self.connection = nil
                self.state = .failed(error.localizedDescription)
            }
        } as? WakeHelperXPCProtocol
    }

    private func makeConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(
            machServiceName: WakeHelperConstants.machServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: WakeHelperXPCProtocol.self)
        connection.interruptionHandler = { [weak self] in
            Task { @MainActor in
                self?.connection = nil
                self?.state = .failed("The reliable wake helper was interrupted.")
            }
        }
        connection.invalidationHandler = { [weak self] in
            Task { @MainActor in
                self?.connection = nil
            }
        }
        connection.resume()
        return connection
    }

    private func invalidateConnection() {
        connection?.invalidate()
        connection = nil
    }

    private func finishShutdown(connection activeConnection: NSXPCConnection) {
        guard connection === activeConnection else { return }
        invalidateConnection()
    }

    private var expectedRegistrationVersion: String {
        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "development"
        let helperBuild = Bundle.main.object(forInfoDictionaryKey: "WakeHelperBuildIdentifier") as? String ?? "unknown-helper"
        return "\(bundleVersion)-protocol-\(WakeHelperConstants.protocolVersion)-helper-\(helperBuild)"
    }

    private var registeredVersion: String? {
        get { UserDefaults.standard.string(forKey: registeredVersionKey) }
        set { UserDefaults.standard.set(newValue, forKey: registeredVersionKey) }
    }
}

private final class LegacyCleanupErrors: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var first: String? {
        lock.withLock { messages.first }
    }

    func append(_ message: String) {
        lock.withLock { messages.append(message) }
    }
}
