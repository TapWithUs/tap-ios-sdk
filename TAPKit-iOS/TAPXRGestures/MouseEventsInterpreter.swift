//
//  MouseEventsInterpreter.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 30/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class MouseEventsInterpreter {
    let clickTimeInterval : TimeInterval = 0.2
    
    private var prev : MouseEventsAction
    private var prevts : TimeInterval
    private var dragTimer : Timer?
    
    var onClick : ((MouseEventFinger) -> Void)?
    var onDrag : ((MouseEventFinger) -> Void)?
    var onDrop : (() -> Void)?
    var onPotentialDragOrClick : ((MouseEventFinger) -> Void)?
    var onFistBegin : (() -> Void)?
    var onFistEnd : (() -> Void)?
    
    init() {
        self.prevts = Date().timeIntervalSince1970
        self.prev = .release
    }
    
    
    
    func action(_ m : MouseEventsAction) {
        let ts = Date().timeIntervalSince1970
        self.dragTimer?.invalidate()
        // let previous = self.prev
        // var outcome = "ignored"
        switch (self.prev, m) {
        case (.release, .press(let finger)) :
                self.dragTimer = Timer.scheduledTimer(withTimeInterval: self.clickTimeInterval, repeats: false, block: {
                    _ in
                    self.prev = .drag
                    self.prevts = Date().timeIntervalSince1970
                    // print("[TAPKit][AirGesture] interpreter drag timer fired -> tapXRAirGestured(drag \(finger.descriptionString()))")
                    self.onDrag?(finger)
                })
            self.onPotentialDragOrClick?(finger)
            // outcome = "tapXRAirGestured(potential \(finger.descriptionString())), drag timer armed"
            break
        case (.press(let finger), .release) :
            self.onClick?(finger)
            // outcome = "tapXRAirGestured(click \(finger.descriptionString()))"
            break
        case (.drag, .release) :
            self.onDrop?()
            // outcome = "tapXRAirGestured(Drop)"
            break
        case (.release, .fist):
            self.onFistBegin?()
            // outcome = "tapXRAirGestured(FistBegin)"
            break
        case (.fist, .release):
            self.onFistEnd?()
            // outcome = "tapXRAirGestured(FistEnd)"
        
        default : break
        }
        // print("[TAPKit][AirGesture] interpreter \(previous.descriptionString()) -> \(m.descriptionString()): \(outcome)")
        self.prev = m
        self.prevts = ts
    }
    
    
}
