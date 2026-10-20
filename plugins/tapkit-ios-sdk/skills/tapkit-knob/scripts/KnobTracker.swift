// Knob: hold a pinch and twist the wrist to change a value (TapXR / TapBand).
//
// Copy this file into the app. Feed it TAPXRAirGesture.rawValue and the
// roll from tapDidChangeOrientation. It does not import TAPKit.
//
// DragIndex...DragPinky (5...8) grab knobs 0...3. Drop (9) releases.
// The iOS SDK emits those as edges, so this tracker does not count
// repeating "none" packets.

import Foundation

struct KnobTracker {
    var stepDegrees: Double
    private(set) var active: Int?
    private var anchor: Double?

    init(stepDegrees: Double = 1) {
        self.stepDegrees = stepDegrees
    }

    /// Shortest signed angle, so crossing ±180 does not jump.
    static func wrapDegrees(_ delta: Double) -> Double {
        let remainder = (delta + 180).truncatingRemainder(dividingBy: 360)
        let positive = remainder < 0 ? remainder + 360 : remainder
        return positive - 180
    }

    /// `"start"`, `"release"`, or nil. `rawValue` is `TAPXRAirGesture.rawValue`.
    mutating func onGesture(_ rawValue: Int) -> String? {
        if rawValue == 9 {
            guard active != nil else { return nil }
            active = nil
            anchor = nil
            return "release"
        }
        guard (5...8).contains(rawValue) else { return nil }
        let knob = rawValue - 5
        if knob == active { return nil }
        active = knob
        anchor = nil
        return "start"
    }

    /// Signed steps, or 0 when no knob is held or the hand has not moved a full step.
    mutating func onRoll(_ roll: Double) -> Int {
        guard active != nil else { return 0 }
        guard let currentAnchor = anchor else {
            anchor = roll
            return 0
        }
        let steps = Int(KnobTracker.wrapDegrees(roll - currentAnchor) / stepDegrees)
        if steps != 0 {
            anchor = KnobTracker.wrapDegrees(currentAnchor + Double(steps) * stepDegrees)
        }
        return steps
    }
}
