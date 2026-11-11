//
//  TAPV2StandbyTracker.swift
//  TAPKit
//

import Foundation

/// Which V2 devices must not receive input-mode writes because they are in
/// standby or about to enter it.
///
/// Writes used to be held only once the device *reported* standby. A write
/// sent after `setStandbyState(true)` but before that report reached a device
/// that was going to sleep, and a TapBand then sent no air gestures for the
/// rest of the connection. TAPKit itself sends such a write at connect: the
/// hardware-version read registers the XR state and triggers `modeUpdate`. So
/// any app that puts the device in standby right after it connects could hit
/// it. Holding from the command closes that window. The current mode is still
/// re-applied when the device reports waking.
struct TAPV2StandbyTracker {
    private(set) var asleep: Set<String> = []

    /// Standby was sent to the device. Holding starts now. Waking is left to
    /// the device's report, so the mode is re-applied after it.
    mutating func commanded(standby: Bool, identifier: String) {
        if standby {
            asleep.insert(identifier)
        }
    }

    /// The device reported its standby state. Returns `true` when it left
    /// standby while writes were held: the input mode must be re-applied.
    mutating func reported(standby: Bool, identifier: String) -> Bool {
        if standby {
            asleep.insert(identifier)
            return false
        }
        return asleep.remove(identifier) != nil
    }

    func holdsWrites(for identifier: String) -> Bool {
        return asleep.contains(identifier)
    }

    mutating func forget(_ identifier: String) {
        asleep.remove(identifier)
    }
}
