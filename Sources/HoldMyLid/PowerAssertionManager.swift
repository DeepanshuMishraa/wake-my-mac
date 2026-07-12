import Foundation
import IOKit.pwr_mgt

final class PowerAssertionManager {
    private var systemAssertion: IOPMAssertionID = 0
    private var idleAssertion: IOPMAssertionID = 0

    var isHolding: Bool {
        systemAssertion != 0 || idleAssertion != 0
    }

    func hold(reason: String) {
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

        if idleAssertion == 0 {
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
