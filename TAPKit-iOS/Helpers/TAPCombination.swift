//
//  TAPCombination.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class TAPCombination : NSObject {
    override private init() {
        super.init()
    }
    
    @objc public static func toFingers(_ combination:UInt8) -> [Bool] {
        return [combination & 0b00001 > 0, combination & 0b00010 > 0, combination & 0b00100 > 0, combination & 0b01000 > 0, combination & 0b10000 > 0]
    }
    
    @objc public static func fingerName(_ finger:Int) -> String {
        switch finger {
        case 0 : return "Thumb"
        case 1 : return "Index"
        case 2 : return "Middle"
        case 3 : return "Ring"
        case 4 : return "Pinky"
        default : return ""
        }
    }
}
