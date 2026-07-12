import Foundation
import IOKit.ps

final class BatteryMonitor {
    func snapshot() -> BatterySnapshot {
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
            let source = list.first,
            let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatterySnapshot(percent: 100, isCharging: false, isPluggedIn: true, isLowPowerMode: lowPower)
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 100
        let max = description[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let percent = max == 0 ? 100 : Int((Double(current) / Double(max) * 100).rounded())
        let state = description[kIOPSPowerSourceStateKey as String] as? String ?? ""
        let isCharging = (description[kIOPSIsChargingKey as String] as? Bool) ?? false
        let pluggedIn = state == kIOPSACPowerValue

        return BatterySnapshot(percent: percent, isCharging: isCharging, isPluggedIn: pluggedIn, isLowPowerMode: lowPower)
    }
}
