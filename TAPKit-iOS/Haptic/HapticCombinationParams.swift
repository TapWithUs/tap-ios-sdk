//
//  HapticCombinationParams.swift
//  TAPKit
//
//  Created by Shahar Biran on 14/10/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public struct HapticCombinationParams {
    public var tapInterval : UInt16
    public var noTapInterval : UInt16
    public var breakInterval : UInt16
    
    public init(tapInterval:UInt16, noTapInterval:UInt16, breakInterval:UInt16) {
        self.tapInterval = tapInterval
        self.noTapInterval = noTapInterval
        self.breakInterval = breakInterval
    }
}
