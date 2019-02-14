////
////  TapCombination.swift
////  TapAloud
////
////  Created by Shahar Biran on 03/05/2018.
////  Copyright © 2018 Shahar Biran. All rights reserved.
////
//
//import Foundation
//
//public class TapCombination {
//    
//    static let allFingers = 31
//    
//    private init() {
//        
//        
//    }
//    
//    public static func fromFingers(_ thumb:UInt8, _ index:UInt8, _ middle:UInt8, _ ring:UInt8, _ pinky:UInt8) -> UInt8 {
//        let fingers = [thumb>0, index>0, middle>0, ring>0, pinky>0]
//        var res : UInt8 = 0
//        for i in 0..<fingers.count {
//            if fingers[i] {
//                res = res | ( 0b00001 << i)
//            }
//        }
//        return res
//    }
//    
//    public static func toFingers(_ combination:UInt8) -> [Bool] {
//        var res : [Bool] = [false, false, false, false, false]
//        for i in 0..<5 {
//            if combination & ( 0b00001 << i) > 0 {
//                res[i] = true
//            }
//        }
//        return res
//    }
//    public static func toFingerNumbers (_ combination : UInt8) -> [UInt8] {
//        var res : [UInt8] = [UInt8]()
//        for i in (UInt8(0)..<UInt8(5)).reversed() {
//            if (combination & (0b1 << i) > 0) {
//                res.insert(i+1, at: 0)
//            }
//        }
//        return res
//    }
//    
//    public static func combinationSpeakableString(for combination:UInt8) -> String {
//        
//            var str : String = ""
//            let fingers = TapCombination.toFingerNumbers(combination)
//            let allFingers : Bool = fingers.elementsEqual([1,2,3,4,5])
//            if (allFingers) {
//                str = "all fingers"
//            } else {
//                str = fingers.count == 1 ? "Finger; " : "Fingers; "
//                for i in 0..<fingers.count {
//                    let current = fingers[i]
//                    str += String(current) + " "
//                    if (i == fingers.count - 2) {
//                        str += " And "
//                    } else if (i < fingers.count-2) {
//                        str += "; "
//                    }
//                }
//            }
//            return str
//
//    }
//}
