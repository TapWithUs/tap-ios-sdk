//
//  TAPXRV2AirGestureConverter.swift
//  TAPKit
//

import Foundation

enum TAPXRV2AirGestureConverter {
    
    /// Converts a V2 gesture stream step using the current and previous V2 values.
    /// Pass `.None` as `previous` on the first frame.
    static func convert(current: TAPXRV2AirGesture, previous: TAPXRV2AirGesture) -> [TAPXRAirGesture] {
        switch current {
        case .None:
            if previous == .Fist {
                return [.FistEnd]
            }
            if isDrag(previous) {
                return [.Drop]
            }
            return []
        case .Fist:
            if previous != .Fist {
                return [.FistBegin]
            }
            return []
        case .ClickIndex:
            return [.ClickIndex]
        case .ClickMiddle:
            return [.ClickMiddle]
        case .ClickRing:
            return [.ClickRing]
        case .ClickPinky:
            return [.ClickPinky]
        case .DragIndex:
            if previous != .DragIndex {
                return [.DragIndex]
            }
            return []
        case .DragMiddle:
            if previous != .DragMiddle {
                return [.DragMiddle]
            }
            return []
        case .DragRing:
            if previous != .DragRing {
                return [.DragRing]
            }
            return []
        case .DragPinky:
            if previous != .DragPinky {
                return [.DragPinky]
            }
            return []
        case .SwipeLeft, .SwipeRight, .SwipeUp, .SwipeDown:
            if let gesture = TAPXRAirGesture(rawValue: current.rawValue) {
                return [gesture]
            }
            return []
        }
    }
    
    private static func isDrag(_ gesture: TAPXRV2AirGesture) -> Bool {
        switch gesture {
        case .DragIndex, .DragMiddle, .DragRing, .DragPinky:
            return true
        default:
            return false
        }
    }
}
