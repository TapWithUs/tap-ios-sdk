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
    
    @objc public static let allFingers = 31
    
    @objc public static func fromFingers(_ thumb:Bool, _ index:Bool, _ middle:Bool, _ ring:Bool, _ pinky:Bool) -> UInt8 {
        let fingers = [thumb, index, middle, ring, pinky]
        var res : UInt8 = 0
        for i in 0..<fingers.count {
            if fingers[i] {
                res = res | ( 0b00001 << i)
            }
        }
        return res
    }
    
    @objc public static func toFingerNumbers (_ combination : UInt8) -> [UInt8] {
        var res : [UInt8] = [UInt8]()
        for i in (UInt8(0)..<UInt8(5)).reversed() {
            if (combination & (0b1 << i) > 0) {
                res.insert(i+1, at: 0)
            }
        }
        return res
    }
    
    @objc public static func combinationSpeakableString(for combination:UInt8) -> String {
        
        var str : String = ""
        let fingers = TAPCombination.toFingerNumbers(combination)
        let allFingers : Bool = fingers.elementsEqual([1,2,3,4,5])
        if (allFingers) {
            str = "all fingers"
        } else {
            str = fingers.count == 1 ? "Finger; " : "Fingers; "
            for i in 0..<fingers.count {
                let current = fingers[i]
                str += String(current) + " "
                if (i == fingers.count - 2) {
                    str += " And "
                } else if (i < fingers.count-2) {
                    str += "; "
                }
            }
        }
        return str
        
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
