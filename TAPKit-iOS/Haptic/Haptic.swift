//
//  Haptic.swift
//  TAPKit
//
//  Created by Shahar Biran on 17/10/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public class Haptic {
    private init() {
        
    }
    
    public static let minInterval:UInt16 = 0
    public static let maxInterval:UInt16 = 250
    
    public static func toRange(_ value:UInt16) -> UInt16 {
        return (value > maxInterval ? maxInterval : (value < minInterval ? minInterval : value))
    }
}
