//
//  TAPCombination.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public class TAPCombination {
    private init() {
        
    }
    
    public static func toFingers(_ combination:UInt8) -> [Bool] {
        return [combination & 0b00001 > 0, combination & 0b00010 > 0, combination & 0b00100 > 0, combination & 0b01000 > 0, combination & 0b10000 > 0]
    }
}
