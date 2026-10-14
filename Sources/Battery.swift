import Foundation
import IOKit.ps

/// The only data Wick ever reads: the internal battery's charge and power state.
struct BatteryState: Equatable {
    var percent: Int
    var isPluggedIn: Bool
}

/// Listens for power-source changes from IOKit. No polling, no timers:
/// macOS calls us when the battery level or power source changes.
@MainActor
final class BatteryMonitor {
    private let onChange: (BatteryState?) -> Void
    private var source: CFRunLoopSource?

    init(onChange: @escaping (BatteryState?) -> Void) {
        self.onChange = onChange
    }

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            MainActor.assumeIsolated {
                Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue().refresh()
            }
        }
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            self.source = source
        }
        refresh()
    }

    func refresh() {
        onChange(Self.read())
    }

    /// Returns nil on Macs without an internal battery.
    static func read() -> BatteryState? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for item in list {
            guard let desc = IOPSGetPowerSourceDescription(info, item)?.takeUnretainedValue() as? [String: Any],
                  desc[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = desc[kIOPSCurrentCapacityKey] as? Int,
                  let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }

            let percent = Swift.min(100, Swift.max(0, current * 100 / max))
            let pluggedIn = desc[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            return BatteryState(percent: percent, isPluggedIn: pluggedIn)
        }
        return nil
    }
}
