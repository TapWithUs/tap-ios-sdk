//
//  TAPXRAirGesture.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/06/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

@objc public enum XRGestureState : Int {
    case none = 100
    case thumb_index = 101
    case thumb_middle = 102
    case thumb_ring = 103
    case thumb_pinky = 104
    case fist = 105
}

@objc public enum TAPXRAirGesture : Int {
    case ClickIndex = 1
    case ClickMiddle = 2
    case ClickRing = 3
    case ClickPinky = 4
    case DragIndex = 5
    case DragMiddle = 6
    case DragRing = 7
    case DragPinky = 8
    case Drop = 9
    case PotentialDragOrClickIndex = 10
    case PotentialDragOrClickMiddle = 11
    case PotentialDragOrClickRing = 12
    case PotentialDragOrClickPinky = 13
    case FistBegin = 14
    case FistEnd = 15
    
    public func descriptionString() -> String {
        switch self {
        case .ClickRing : return "ClickRing"
        case .ClickIndex : return "ClickIndex"
        case .ClickPinky : return "ClickPinky"
        case .ClickMiddle : return "ClickMiddle"
        case .DragIndex : return "DragIndex"
        case .DragMiddle : return "DragMiddle"
        case .DragRing : return "DragRing"
        case .DragPinky : return "DragPinky"
        case .Drop : return "Drop"
        case .FistBegin : return "FistBegin"
        case .FistEnd : return "FistEnd"
        case .PotentialDragOrClickIndex : return "PotentialDragOrClickIndex"
        case .PotentialDragOrClickMiddle : return "PotentialDragOrClickMiddle"
        case .PotentialDragOrClickPinky : return "PotentialDragOrClickPinky"
        case .PotentialDragOrClickRing : return "PotentialDragOrClickRing"
        }
    }
}
