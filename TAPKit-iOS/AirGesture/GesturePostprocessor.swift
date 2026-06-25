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

/*
// Previous GesturePostprocessor implementation (replaced by NovelGesturePostprocessor port).

class GesturePostprocessor {
    
    static let enhancedLabels: [Int: String] = [
        100: "NONE", 101: "LEFT", 102: "RIGHT", 103: "UP", 104: "DOWN",
        105: "AB", 106: "AC", 107: "AD", 108: "AE", 109: "FIST",
        110: "AB_HOLD", 111: "AC_HOLD", 112: "AD_HOLD", 113: "AE_HOLD", 114: "FIST_HOLD",
        115: "DOUBLE_AB", 116: "DOUBLE_AC", 117: "DOUBLE_AD", 118: "DOUBLE_AE",
    ]
    
    static let nameToIdx: [String: Int] = {
        var map = [String: Int]()
        enhancedLabels.forEach { map[$0.value] = $0.key }
        return map
    }()
    
    static let singlePinchToDouble: [String: String] = [
        "AB": "DOUBLE_AB",
        "AC": "DOUBLE_AC",
        "AD": "DOUBLE_AD",
        "AE": "DOUBLE_AE",
    ]
    
    static let doubleToSingle: [String: String] = {
        var map = [String: String]()
        singlePinchToDouble.forEach { map[$0.value] = $0.key }
        return map
    }()
    
    static let holdSuppressIndices: Set<Int> = [105, 106, 107, 108, 109]
    static let holdNames: Set<String> = ["AB_HOLD", "AC_HOLD", "AD_HOLD", "AE_HOLD", "FIST_HOLD"]
    static let holdExitNoneCount = 3
    static let pinchNames: Set<String> = ["AB", "AC", "AD", "AE", "FIST"]
    static let swipeNames: Set<String> = ["LEFT", "RIGHT", "UP", "DOWN"]
    static let pinchDelayFrames = 3
    static let swipeDelayFrames = 3
    static let windowLengthMs = 300.0
    static let cooldownFrames = 2
    static let historyLen = 2
    
    let holdDebounce: Bool
    let aggregatedDoubles: Bool
    
    private var prevLabels: [String]
    private var last = "NONE"
    private var buffer = [(Double, String)]()
    private var cooldown = 0
    private var lastDouble = "NONE"
    private var suppressSingle: String?
    private var pending: (String, Double)?
    private var holdNoneStreak = 0
    private var pinchPending: String?
    private var pinchCount = 0
    private var swipeCount = 0
    private var previousOutputIndex: Int
    
    init(holdDebounce: Bool = true, aggregatedDoubles: Bool = true) {
        self.holdDebounce = holdDebounce
        self.aggregatedDoubles = aggregatedDoubles
        self.prevLabels = Array(repeating: "", count: Self.historyLen)
        self.previousOutputIndex = Self.nameToIdx["NONE"] ?? 100
    }
    
    func call(_ classIndex: Int) -> (current: Int, previous: Int) {
        let timestampMs = Self.monotonicTimeMs()
        let index = Int(classIndex)
        var rawName = Self.enhancedLabels[index] ?? "NONE"
        
        if holdDebounce,
           prevLabels.contains(where: { $0.contains("HOLD") }),
           Self.holdSuppressIndices.contains(index) {
            rawName = "NONE"
        }
        
        rawName = debounceSwipe(rawName: rawName)
        
        let outName: String
        if aggregatedDoubles {
            outName = processAggregated(rawName: rawName, timestampMs: timestampMs)
        } else {
            outName = processSimple(rawName: rawName)
        }
        
        if holdDebounce {
            appendPrevLabel(rawName)
        }
        
        let current = Self.nameToIdx[outName] ?? 0
        let previous = previousOutputIndex
        previousOutputIndex = current
        return (current: current, previous: previous)
    }
    
    private func appendPrevLabel(_ label: String) {
        prevLabels.append(label)
        while prevLabels.count > Self.historyLen {
            prevLabels.removeFirst()
        }
    }
    
    private static func monotonicTimeMs() -> Double {
        var timespec = Darwin.timespec()
        clock_gettime(CLOCK_MONOTONIC, &timespec)
        let monotonicNs = (Int64(timespec.tv_sec) * 1_000_000_000) + Int64(timespec.tv_nsec)
        return Double(monotonicNs) / 1_000_000.0
    }
    
    private func debounceSwipe(rawName: String) -> String {
        if swipeCount > 0 {
            swipeCount -= 1
            return "NONE"
        }
        if Self.swipeNames.contains(rawName) {
            swipeCount = Self.swipeDelayFrames
            return rawName
        }
        return rawName
    }
    
    private func processSimple(rawName: String) -> String {
        if let pendingPinch = pinchPending {
            if Self.holdNames.contains(rawName) {
                pinchPending = nil
                pinchCount = 0
                holdNoneStreak = 0
                last = rawName
                return rawName
            }
            if Self.pinchNames.contains(rawName) {
                pinchPending = rawName
            }
            pinchCount += 1
            if pinchCount >= Self.pinchDelayFrames {
                let committed = pendingPinch
                pinchPending = nil
                pinchCount = 0
                holdNoneStreak = 0
                last = committed
                return committed
            }
            return last
        }
        
        if Self.pinchNames.contains(rawName) {
            pinchPending = rawName
            pinchCount = 0
            return last
        }
        
        if rawName == "NONE" {
            if Self.holdNames.contains(last) {
                holdNoneStreak += 1
                if holdNoneStreak < Self.holdExitNoneCount {
                    return last
                }
            }
            last = "NONE"
            holdNoneStreak = 0
            return "NONE"
        }
        
        holdNoneStreak = 0
        last = rawName
        return last
    }
    
    private func processAggregated(rawName: String, timestampMs: Double) -> String {
        if cooldown > 0 {
            cooldown -= 1
            buffer.removeAll(keepingCapacity: false)
            return lastDouble
        }
        
        buffer.append((timestampMs, rawName))
        let cutoff = timestampMs - Self.windowLengthMs
        while let first = buffer.first, first.0 < cutoff {
            buffer.removeFirst()
        }
        
        if let doubleName = aggregatedDouble() {
            lastDouble = doubleName
            suppressSingle = Self.doubleToSingle[doubleName]
            last = doubleName
            pending = nil
            cooldown = Self.cooldownFrames
            buffer.removeAll(keepingCapacity: false)
            return doubleName
        }
        
        if Self.singlePinchToDouble[rawName] != nil {
            pending = (rawName, timestampMs)
            return last
        }
        
        if let pendingEntry = pending {
            if timestampMs - pendingEntry.1 > Self.windowLengthMs {
                last = pendingEntry.0
                pending = nil
            }
        }
        
        if rawName == "NONE" {
            if Self.holdNames.contains(last) {
                holdNoneStreak += 1
                if holdNoneStreak < Self.holdExitNoneCount {
                    return last
                }
            }
            last = "NONE"
            holdNoneStreak = 0
            return "NONE"
        }
        
        holdNoneStreak = 0
        let saved = last
        last = rawName
        var out = last
        
        if let suppressed = suppressSingle {
            if out == suppressed {
                last = saved
                out = saved
            } else {
                suppressSingle = nil
            }
        }
        
        return out
    }
    
    private func aggregatedDouble() -> String? {
        guard let first = buffer.first else { return nil }
        
        var runs = [first.1]
        for entry in buffer.dropFirst() {
            if entry.1 != runs.last {
                runs.append(entry.1)
            }
        }
        
        var byBase = [String: Int]()
        Self.singlePinchToDouble.keys.forEach { byBase[$0] = 0 }
        for name in runs {
            if byBase[name] != nil {
                byBase[name, default: 0] += 1
            }
        }
        
        for base in ["AB", "AC", "AD", "AE"] {
            if (byBase[base] ?? 0) >= 2 {
                return Self.singlePinchToDouble[base]
            }
        }
        return nil
    }
}
*/

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
