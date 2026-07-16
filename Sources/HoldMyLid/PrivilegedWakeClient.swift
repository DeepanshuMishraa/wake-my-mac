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

@MainActor
final class PrivilegedWakeClient {
    var onStateChange: ((ReliableWakeState) -> Void)?

    private let service = SMAppService.daemon(plistName: WakeHelperConstants.launchDaemonPlistName)
    private let leaseIdentifier = "wake-my-mac-\(UUID().uuidString)"
    private var connection: NSXPCConnection?
    private var desiredHolding = false
    private var generation = 0
    private(set) var state: ReliableWakeState = .checking {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    func refreshServiceStatus() {
        switch service.status {
        case .enabled:
            state = desiredHolding ? .activating : .ready
            if desiredHolding {
                renewLease(reason: "Wake My Mac")
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

    func registerHelper() {
        state = .checking
        do {
            try service.register()
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

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func renewLease(reason: String) {
        desiredHolding = true
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

        proxy.renewLease(
            identifier: leaseIdentifier,
            reason: reason,
            duration: WakeHelperConstants.defaultLeaseDuration
        ) { [weak self] success, message in
            Task { @MainActor in
                guard let self, self.generation == currentGeneration, self.desiredHolding else { return }
                self.state = success ? .active : .failed(message ?? "macOS did not enable reliable wake.")
            }
        }
    }

    func releaseLease() {
        guard desiredHolding || state == .active || state == .activating else { return }
        desiredHolding = false
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
            Task { @MainActor in
                guard let self, self.generation == currentGeneration, !self.desiredHolding else { return }
                self.state = success ? .ready : .failed(message ?? "macOS did not restore normal sleep.")
            }
        }
    }

    func shutdown() {
        let shouldRelease = desiredHolding || state == .active || state == .activating
        desiredHolding = false
        generation += 1

        if shouldRelease, service.status == .enabled {
            let semaphore = DispatchSemaphore(value: 0)
            let connection = connection ?? makeConnection()
            self.connection = connection
            let proxy = connection.remoteObjectProxyWithErrorHandler { _ in
                semaphore.signal()
            } as? WakeHelperXPCProtocol
            proxy?.releaseLease(identifier: leaseIdentifier) { _, _ in
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 2)
        }

        connection?.invalidate()
        connection = nil
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
}
