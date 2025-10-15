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
    case fist = 105
}

@objc public enum TAPXRAirGesture : Int {
    case ClickIndex = 1
    case ClickMiddle = 2
    case ClickRing = 3
    case DragIndex = 4
    case DragMiddle = 5
    case DragRing = 6
    case Drop = 7
    case PotentialDragOrClickIndex = 8
    case PotentialDragOrClickMiddle = 9
    case PotentialDragOrClickRing = 10
    case FistBegin = 11
    case FistEnd = 12
}
