//
//  GesturePostprocessor.swift
//  TAPKit
//

import Foundation
import Darwin

class GesturePostprocessor {

    static let LBL_IDX: [String: Int] = [
        "NONE": 100,
        "LEFT": 101, "RIGHT": 102, "UP": 103, "DOWN": 104,
        "AB": 105, "AC": 106, "AD": 107, "AE": 108, "FIST": 109,
        "AB_HOLD": 110, "AC_HOLD": 111, "AD_HOLD": 112, "AE_HOLD": 113, "FIST_HOLD": 114,
        "DOUBLE_AB": 115, "DOUBLE_AC": 116, "DOUBLE_AD": 117, "DOUBLE_AE": 118,
    ]

    static let IDX_LBL: [Int: String] = {
        var map = [Int: String]()
        LBL_IDX.forEach { map[$0.value] = $0.key }
        return map
    }()

    static let SWIPES = ["LEFT", "RIGHT", "UP", "DOWN"]
    static let PINCHES = ["AB", "AC", "AD", "AE", "FIST"]
    static let HOLDS = PINCHES.map { "\($0)_HOLD" }
    static let DOUBLES = PINCHES.map { "DOUBLE_\($0)" }
    static let WINDOW_MS = 300.0
    static let COOLDOWN_MS = 200.0

    let holdDebounce: Bool
    let aggregatedDoubles: Bool

    private var history: [Int]
    private var pending: String?
    private var pendingAt: Double = 0
    private var pendingReleased = false
    private var holdActive = false
    private var holdLabel: Int?
    private var lastFiredAt: Double = 0
    private var previousOutputIndex: Int

    init(holdDebounce: Bool = true, aggregatedDoubles: Bool = true) {
        self.holdDebounce = holdDebounce
        self.aggregatedDoubles = aggregatedDoubles
        let none = Self.LBL_IDX["NONE"]!
        self.history = Array(repeating: none, count: 10)
        self.previousOutputIndex = none
    }

    func call(_ classIndex: Int) -> (current: Int, previous: Int) {
        let previous = previousOutputIndex
        let final = process(classIndex)
        previousOutputIndex = final
        return (current: final, previous: previous)
    }

    private func process(_ classIndex: Int) -> Int {
        let now = Self.monotonicTime()
        let n = Self.LBL_IDX["NONE"]!
        let name = Self.IDX_LBL[classIndex] ?? "NONE"
        let prev = history[history.count - 1]
        appendHistory(classIndex)

        let out: Int
        if Self.HOLDS.contains(name), !holdActive || classIndex == holdLabel {
            holdActive = true
            holdLabel = classIndex
            out = classIndex
        } else if holdActive {
            if classIndex == n {
                holdActive = false
                lastFiredAt = now
                out = n
            } else {
                out = holdLabel ?? n
            }
        } else {
            out = prev != n && classIndex != n ? n : classIndex
        }

        var final = out

        if aggregatedDoubles, let pendingName = pending, (now - pendingAt) * 1000 >= Self.WINDOW_MS {
            final = Self.LBL_IDX[pendingName] ?? n
            pending = nil
            pendingReleased = false
            if Self.PINCHES.contains(name) {
                pending = name
                pendingAt = now
            }
        } else if aggregatedDoubles, Self.PINCHES.contains(name) {
            if pending == name, pendingReleased {
                pending = nil
                pendingReleased = false
                final = Self.LBL_IDX["DOUBLE_\(name)"] ?? n
            } else if pending == name {
                final = n
            } else {
                pending = name
                pendingAt = now
                pendingReleased = false
                final = n
            }
        } else if aggregatedDoubles, name == "NONE", pending != nil {
            pendingReleased = true
        }

        let outName = Self.IDX_LBL[final] ?? "NONE"
        if (now - lastFiredAt) * 1000 < Self.COOLDOWN_MS {
            return n
        }
        if !Self.HOLDS.contains(outName), outName != "NONE" {
            lastFiredAt = now
        }
        return final
    }

    private func appendHistory(_ classIndex: Int) {
        history.append(classIndex)
        if history.count > 10 {
            history.removeFirst()
        }
    }

    private static func monotonicTime() -> Double {
        var timespec = Darwin.timespec()
        clock_gettime(CLOCK_MONOTONIC, &timespec)
        return Double(timespec.tv_sec) + Double(timespec.tv_nsec) / 1_000_000_000.0
    }
}

extension GesturePostprocessor {
    static func ToTapXRV2AirGesture(_ classIndex: Int) -> TAPXRV2AirGesture? {
        if let name = GesturePostprocessor.LBL_IDX.first(where: { $0.value == classIndex })?.key {
            switch name {
            case "NONE": return .None
            case "LEFT": return .SwipeLeft
            case "RIGHT": return .SwipeRight
            case "UP": return .SwipeUp
            case "DOWN": return .SwipeDown
            case "AB": return .ClickIndex
            case "AC": return .ClickMiddle
            case "AD": return .ClickRing
            case "AE": return .ClickPinky
            case "AB_HOLD": return .DragIndex
            case "AC_HOLD": return .DragMiddle
            case "AD_HOLD": return .DragRing
            case "AE_HOLD": return .DragPinky
            case "FIST_HOLD": return .Fist
            default: return nil
            }
        } else {
            return nil
        }
    }
}
