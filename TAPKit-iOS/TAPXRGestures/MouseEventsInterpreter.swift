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
        switch (self.prev, m) {
        case (.release, .press(let finger)) :
                self.dragTimer = Timer.scheduledTimer(withTimeInterval: self.clickTimeInterval, repeats: false, block: {
                    _ in
                    self.prev = .drag
                    self.prevts = Date().timeIntervalSince1970
                    self.onDrag?(finger)
                })
            self.onPotentialDragOrClick?(finger)
            break
        case (.press(let finger), .release) :
            self.onClick?(finger)
            break
        case (.drag, .release) :
            self.onDrop?()
            break
        case (.release, .fist):
            self.onFistBegin?()
            break
        case (.fist, .release):
            self.onFistEnd?()
        
        default : break
        }
        self.prev = m
        self.prevts = ts
    }
    
    
}
