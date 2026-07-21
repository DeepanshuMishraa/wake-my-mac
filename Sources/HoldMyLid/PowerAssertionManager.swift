import Foundation
import IOKit.pwr_mgt

@MainActor
final class PowerAssertionManager {
    private var idleAssertion: IOPMAssertionID = 0
    private let privilegedClient = PrivilegedWakeClient()

    var onStateChange: ((ReliableWakeState) -> Void)? {
        didSet { privilegedClient.onStateChange = onStateChange }
    }

    var reliableWakeState: ReliableWakeState { privilegedClient.state }

    var isHolding: Bool {
        reliableWakeState == .active
    }

    /// The supported IOKit assertion is retained as a best-effort fallback.
    /// Reliable wake is provided by the privileged helper lease, whose state is
    /// reported separately and must be acknowledged before the UI says "Awake".
    func hold(reason: String, kind: WakeRequestKind) {
        if idleAssertion == 0 {
            var assertion = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertPreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &assertion
            )
            if result == kIOReturnSuccess {
                idleAssertion = assertion
            }
        }
        privilegedClient.hold(reason: reason, kind: kind)
    }

    func release() {
        if idleAssertion != 0 {
            IOPMAssertionRelease(idleAssertion)
            idleAssertion = 0
        }
        privilegedClient.releaseAll()
    }

    func refreshHelperStatus() { privilegedClient.refreshServiceStatus() }
    func registerHelper() { privilegedClient.registerHelper() }
    func openApprovalSettings() { privilegedClient.openApprovalSettings() }
    func shutdown() { privilegedClient.shutdown() }
}
