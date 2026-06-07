//
//  MajorityVoting.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class MajorityVoting<T:Hashable> {
    
//    var useMajority : Bool {
//        didSet {
//            if oldValue != self.useMajority {
//                self.resetDQ()
//            }
//            
//        }
//    }
    let defaultValue:T
    let len:Int
    var dq : Deque<T>
    
    init(len:Int, defaultValue:T) {
//        self.useMajority = true
        self.defaultValue = defaultValue
        self.len = len
        self.dq = Deque<T>.init(len: len)
        self.resetDQ()
        for _ in 0..<len {
            self.dq.add(defaultValue)
        }
    }
    
    private func resetDQ() {
        self.dq = Deque<T>.init(len: self.len)
        for _ in 0..<self.len {
            self.dq.add(defaultValue)
        }
    }
    
    func call(_ item:T) -> T? {
//        guard self.useMajority else { return item }
        self.dq.add(item)
        let counts = Dictionary(self.dq.all().map({ ($0,1) }), uniquingKeysWith: +)
        return (counts.max(by: { $0.1 < $1.1 }))?.key as? T
        
    }
}

