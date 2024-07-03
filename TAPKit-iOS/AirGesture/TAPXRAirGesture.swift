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
}

@objc public enum TAPXRAirGesture : Int {
    case ClickIndex = 1
    case ClickMiddle
    case DragIndex = 3
    case DragMiddle = 4
    case Drop = 5
    case PotentialDragOrClickIndex = 6
    case PotentialDragOrClickMiddle = 7
}
