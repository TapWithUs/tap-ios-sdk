// D-Pad: swipe to move, click to select, pinch-hold to rotate or drag (TapXR / TapBand).
//
// Copy this file into the app. Feed it TAPXRAirGesture.rawValue, moused
// deltas, and roll from tapDidChangeOrientation. It does not import TAPKit.
//
// The iOS SDK emits edges, so release is a single Drop (9) and show is
// a single FistEnd (15). There is no run of "none" packets to count.

import Foundation

enum DpadEvent {
    case direction(String)
    case pinch(Int)
    case hold(Int)
    case mode(String)
    case rotate(Double)
    case drag(dx: Int, dy: Int)
    case release(Int)
    case hide
    case show
}

struct DpadController {
    var rotateLockDegrees: Double
    var lockWindow: Double
    var debounce: Double
    private(set) var held: Int?
    private(set) var mode: String?
    private(set) var hidden = false

    private var holdStart = 0.0
    private var refRoll: Double?
    private var lastRoll: Double?
    private var rollTravel = 0.0
    private var lastCode: Int?
    private var lastCodeTime = -1.0

    init(rotateLockDegrees: Double = 25, lockWindow: Double = 1, debounce: Double = 0.04) {
        self.rotateLockDegrees = rotateLockDegrees
        self.lockWindow = lockWindow
        self.debounce = debounce
    }

    mutating func tick(_ now: Double) -> [DpadEvent] {
        if mode == "pending", now - holdStart >= lockWindow {
            return lock(rollTravel >= rotateLockDegrees ? "rotate" : "drag")
        }
        return []
    }

    mutating func onGesture(_ code: Int, now: Double) -> [DpadEvent] {
        var events = tick(now)
        if code == 9 {
            if !hidden { events += release() }
            return events
        }
        if code == 15 {
            if hidden {
                hidden = false
                events.append(.show)
            }
            return events
        }
        if hidden { return events }

        if code == 14 {
            if !isRepeat(code, now) {
                events += release()
                hidden = true
                events.append(.hide)
            }
            return events
        }
        if let name = swipeName(code) {
            if !isRepeat(code, now) { events.append(.direction(name)) }
            return events
        }
        if (5...8).contains(code) {
            let index = code - 5
            if index != held, !isRepeat(code, now) {
                events += release()
                held = index
                mode = "pending"
                holdStart = now
                rollTravel = 0
                refRoll = nil
                lastRoll = nil
                events.append(.hold(index))
            }
            return events
        }
        if (1...4).contains(code), held == nil, !isRepeat(code, now) {
            events.append(.pinch(code - 1))
        }
        return events
    }

    mutating func onMotion(dx: Int, dy: Int, roll: Double, now: Double) -> [DpadEvent] {
        var events = tick(now)
        guard held != nil else { return events }
        if mode == "drag" {
            if dx != 0 || dy != 0 { events.append(.drag(dx: dx, dy: dy)) }
            return events
        }
        if let previous = lastRoll { rollTravel += abs(roll - previous) }
        lastRoll = roll
        if refRoll == nil { refRoll = roll }
        if mode == "pending", rollTravel >= rotateLockDegrees {
            events += lock("rotate")
        }
        if let refRoll = refRoll { events.append(.rotate(roll - refRoll)) }
        return events
    }

    private mutating func lock(_ newMode: String) -> [DpadEvent] {
        mode = newMode
        return [.mode(newMode)]
    }

    private mutating func release() -> [DpadEvent] {
        let events: [DpadEvent] = held.map { [.release($0)] } ?? []
        held = nil
        mode = nil
        refRoll = nil
        lastRoll = nil
        rollTravel = 0
        return events
    }

    private mutating func isRepeat(_ code: Int, _ now: Double) -> Bool {
        if code == lastCode, now - lastCodeTime < debounce { return true }
        lastCode = code
        lastCodeTime = now
        return false
    }

    private func swipeName(_ code: Int) -> String? {
        switch code {
        case 17: return "left"
        case 18: return "right"
        case 19: return "up"
        case 20: return "down"
        default: return nil
        }
    }
}

extension DpadEvent: Equatable {
    static func == (lhs: DpadEvent, rhs: DpadEvent) -> Bool {
        switch (lhs, rhs) {
        case (.direction(let a), .direction(let b)):
            return a == b
        case (.pinch(let a), .pinch(let b)):
            return a == b
        case (.hold(let a), .hold(let b)):
            return a == b
        case (.mode(let a), .mode(let b)):
            return a == b
        case (.rotate(let a), .rotate(let b)):
            return a == b
        case (.drag(let ax, let ay), .drag(let bx, let by)):
            return ax == bx && ay == by
        case (.release(let a), .release(let b)):
            return a == b
        case (.hide, .hide):
            return true
        case (.show, .show):
            return true
        default:
            return false
        }
    }
}
