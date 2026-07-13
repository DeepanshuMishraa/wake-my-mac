import Foundation
import IOKit.pwr_mgt

final class PowerAssertionManager {
    private var systemAssertion: IOPMAssertionID = 0
    private var idleAssertion: IOPMAssertionID = 0

    var isHolding: Bool {
        systemAssertion != 0 || idleAssertion != 0
    }

    /// Holds system sleep. SSH mode deliberately skips the user-idle assertion:
    /// the system assertion keeps the Mac reachable, while avoiding an extra
    /// assertion that can interfere with normal idle/display power behavior.
    func hold(reason: String, conserveEnergy: Bool = false) {
        if systemAssertion == 0 {
            var assertion = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &assertion
            )
            if result == kIOReturnSuccess {
                systemAssertion = assertion
            }
        }

        if !conserveEnergy, idleAssertion == 0 {
            var assertion = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &assertion
            )
            if result == kIOReturnSuccess {
                idleAssertion = assertion
            }
        }

        if conserveEnergy, idleAssertion != 0 {
            IOPMAssertionRelease(idleAssertion)
            idleAssertion = 0
        }
    }

    func release() {
        if systemAssertion != 0 {
            IOPMAssertionRelease(systemAssertion)
            systemAssertion = 0
        }
        if idleAssertion != 0 {
            IOPMAssertionRelease(idleAssertion)
            idleAssertion = 0
        }
    }
}
