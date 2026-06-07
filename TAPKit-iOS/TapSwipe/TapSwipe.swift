//
//  TapSwipe.swift
//  TAPKit
//
//  Created by Shahar Biran on 01/01/2026.
//  Copyright © 2026 Shahar Biran. All rights reserved.
//

import Foundation

class TapSwipe {
    private var canSwipe : [String:Date]
    private let canSwipeInterval : TimeInterval = 0.2
    init() {
        self.canSwipe = [String:Date]()
    }
    
    func swipe(identifier:String) -> Bool {
        let now = Date()
        if !self.canSwipe.keys.contains(identifier) {
            self.canSwipe[identifier] = now
            return true
        }
        let last = self.canSwipe[identifier]!
        self.canSwipe[identifier] = now
        print("now = \(now), last = \(last), diff = \(now.timeIntervalSince(last))")
        return now.timeIntervalSince(last) >= canSwipeInterval
    }
}
