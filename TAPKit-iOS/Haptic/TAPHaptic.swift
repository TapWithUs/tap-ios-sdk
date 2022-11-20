//
//  TAPHaptic.swift
//  TAPKit
//
//  Created by Shahar Biran on 14/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

class TAPHaptic {
    private init() {
        
    }
    
    static func toData(durations:Array<UInt16>) -> Data? {
        guard durations.count > 0 else { return nil }
        var bytes = [UInt8].init(repeating: 0, count: 20)
        bytes[0] = 0
        bytes[1] = 2
        for i in 0..<min(18,durations.count) {
            bytes[i+2] = UInt8( Double(durations[i])/10.0)
        }
        return Data.init(bytes: bytes)
    }
}
