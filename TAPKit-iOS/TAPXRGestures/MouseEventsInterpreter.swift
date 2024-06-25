//
//  MouseEventsInterpreter.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 30/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class MouseEventsInterpreter {
    let clickTimeInterval : TimeInterval = 0.13
    
    private var prev : MouseEventsAction
    private var prevts : TimeInterval
    private var dragTimer : Timer?
    
    var onClick : (() -> Void)?
    var onDrag : (() -> Void)?
    var onDrop : (() -> Void)?
    var onPotentialDragOrClick : (() -> Void)?
    init() {
        self.prevts = Date().timeIntervalSince1970
        self.prev = .release
    }
    
    
    
    func action(_ m : MouseEventsAction) {
        let ts = Date().timeIntervalSince1970
        switch (self.prev, m) {
        case (.release, .press) :
            self.dragTimer = Timer.scheduledTimer(withTimeInterval: self.clickTimeInterval, repeats: false, block: {
                _ in
                self.prev = .drag
                self.prevts = Date().timeIntervalSince1970
                DispatchQueue.main.async { self.onDrag?() }
            })
            DispatchQueue.main.async { self.onPotentialDragOrClick?() }
            break
        case (.press, .release) :
            self.dragTimer?.invalidate()
            DispatchQueue.main.async { self.onClick?() }
            break
        case (.drag, .release) :
            DispatchQueue.main.async { self.onDrop?() }
            break
        default : break
        }
        self.prev = m
        self.prevts = ts
    }
    
    
}
