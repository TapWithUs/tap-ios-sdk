//
//  MajorityVoting.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class MajorityVoting<T:Hashable> {
    var dq : Deque<T>
    
    init(len:Int, defaultValue:T) {
        
        self.dq = Deque<T>.init(len: len)
        for _ in 0..<len {
            self.dq.add(defaultValue)
        }
        
        
    }
    
    func call(_ item:T) -> T? {
        self.dq.add(item)
        
        let counts = Dictionary(self.dq.all().map({ ($0,1) }), uniquingKeysWith: +)
        return (counts.max(by: { $0.1 < $1.1 }))?.key as? T
        
    }
}

