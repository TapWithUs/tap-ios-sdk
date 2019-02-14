//
//  HapticSequencePlayer.swift
//  TAPKit
//
//  Created by Shahar Biran on 14/10/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public class HapticSequencePlayer {
    private var sequence : HapticSequence
    
    public var onHapticPlay : ((UInt16)->Void)?
    public var onHapticWait : ((UInt16)->Void)?
    
    private var timer : Timer?

    public init() {
        self.sequence = HapticSequence()
    }
    
    public func play(_ hapticSequence:HapticSequence) -> Void {
        self.stop()
        self.sequence.set(other: hapticSequence)
        self.start()
    }
    
    private func start() -> Void {
        self.sequence.reset()
        self.playNext(timer:nil)
    }
    
    public func stop() -> Void {
        self.timer?.invalidate()
    }

    @objc func playNext(timer:Timer?) -> Void {
        self.timer?.invalidate()
        if let next = self.sequence.getNext() {
            switch next.type {
            case .play : self.onHapticPlay?(next.interval)
                break
            case .wait : self.onHapticWait?(next.interval)
                break
            }
            self.timer = Timer.scheduledTimer(timeInterval: Double(next.interval)/1000.0, target: self, selector: #selector(playNext(timer:)), userInfo: nil, repeats: false)
        } else {
            self.stop()
        }
    }
}
