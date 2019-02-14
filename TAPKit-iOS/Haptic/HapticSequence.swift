//
//  HapticSequence.swift
//  TAPKit
//
//  Created by Shahar Biran on 11/10/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

enum HapticPlayType {
    case play
    case wait
}

public class HapticSequence {
//    var onHapticPlay : ((Double)->Void)?
//    var onHapticWait : ((Double)->Void)?
//    
//    var timer : Timer?
    
    var sequence : Array<UInt16> // Haptic,Break,Haptic,Break, etc...
    
    
    
    private var currentIndex : Int;
    
    public init() {
        self.sequence = Array<UInt16>()
        self.currentIndex = -1
    }
    
    public init(newSequence:Array<UInt16>) {
        self.sequence = Array<UInt16>()
        self.currentIndex = -1
        self.set(newSequence: newSequence)
    }
    
//    private func clamp(_ interval:UInt16) -> UInt16 {
//        return (interval < Haptic.minInterval ? Haptic.minInterval : (interval > Haptic.maxInterval ? Haptic.maxInterval : interval))
//    }
    
    public func set(newSequence:Array<UInt16>) -> Void {
        self.sequence.removeAll()
        for interval in newSequence {
            self.sequence.append(interval)
        }
        self.currentIndex = -1
    }
    
    public func set(other:HapticSequence) -> Void {
        self.sequence.removeAll()
        for i in 0..<other.sequence.count {
            self.sequence.append(other.sequence[i])
        }
        self.currentIndex = -1
    }
    
    func reset() -> Void {
        self.currentIndex = -1
    }
    
    func getNext() -> (interval:UInt16, type:HapticPlayType)? {
        if self.currentIndex + 1 < self.sequence.count {
            self.currentIndex = self.currentIndex + 1
            return (self.sequence[self.currentIndex], self.currentIndex % 2 == 0 ? .play : .wait)
        } else {
            return nil
        }
    }
    
    public func getArray(maxCapacity:Int? = nil) -> Array<UInt16> {
        var res = Array<UInt16>()
        var count = self.sequence.count
        if let m = maxCapacity {
            count = min(count,m)
        }
        for i in 0..<count {
            res.append(sequence[i])
        }
        return res
    }
    
    public func getDurationsSum() -> Int {
        return self.sequence.reduce(0, {
            $0 + Int($1)
        })
    }
}

extension HapticSequence {
    public static func fromTapCombination(tapCombination:UInt8, params:HapticCombinationParams) -> HapticSequence {
        let fingers = TAPCombination.toFingers(tapCombination)
        var seq = Array<UInt16>()
        for i in 0..<fingers.count {
            seq.append(fingers[i] ? params.tapInterval : params.noTapInterval)
            if i < fingers.count-1 {
                seq.append(params.breakInterval)
            }
            
        }
        return HapticSequence(newSequence: seq)
    }
    
    public static func fromTapCombination(tapCombination:UInt8, tapInterval:UInt16, noTapInterval:UInt16, breakInterval:UInt16) -> HapticSequence {
        let params = HapticCombinationParams(tapInterval: tapInterval, noTapInterval: noTapInterval, breakInterval: breakInterval)
        return HapticSequence.fromTapCombination(tapCombination: tapCombination, params: params)
    }
}
