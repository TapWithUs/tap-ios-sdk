//
//  XRGestures.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

enum XRGestureState : Int {
    case none = 100
    case thumb_finger = 101
    case thumb_middle = 102
}

@objc public enum TAPXRAirGesture : Int {
    case Click = 1
    case Drag = 2
    case Drop = 3
    case PotentialDragOrClick = 4
}

class XRGesturesMain {

    
    
    private var mouseEvents : MouseEvents
    private var mouseEventsInterpreter : MouseEventsInterpreter
    private var cursorThreadTimer : Timer?
    private var clickMajorityVoting : MajorityVoting<Int>
    
    
    var onXRAirGestured : ((TAPXRAirGesture) -> Void)?
    
    private let cursorFillTimeInterval : TimeInterval = 0.1
    
    init() {
        self.clickMajorityVoting = MajorityVoting(len: 3, defaultValue: XRGestureState.none.rawValue)
        self.mouseEvents = MouseEvents()
        self.mouseEventsInterpreter = MouseEventsInterpreter()
        self.mouseEvents.delegate = self
        self.mouseEventsInterpreter.onDrag = self.mouseEventsInterpreterOnDrag
        self.mouseEventsInterpreter.onClick = self.mouseEventsInterpreterOnClick
        self.mouseEventsInterpreter.onDrop = self.mouseEventsInterpreterOnDrop
        self.mouseEventsInterpreter.onPotentialDragOrClick = self.mouseEventsInterpreterOnPotientialDragOrClick
    }
    
    private func timestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
}

extension XRGesturesMain : MouseEventsDelegate {
    func mouseEventsAction(_ action: MouseEventsAction) {
        DispatchQueue.main.async {
            self.mouseEventsInterpreter.action(action)
        }
        
    }
}


extension XRGesturesMain {
    // Mouse events interpreter callbacks.
    
    func mouseEventsInterpreterOnClick() {
        DispatchQueue.main.async {
            self.onXRAirGestured?(.Click)
        }
        
    }
    
    func mouseEventsInterpreterOnDrag() {
        DispatchQueue.main.async {
            self.onXRAirGestured?(.Drag)
        }
        
        
    }
    
    func mouseEventsInterpreterOnDrop() {
        DispatchQueue.main.async {
            self.onXRAirGestured?(.Drop)
        }
        
    }
    
    func mouseEventsInterpreterOnPotientialDragOrClick() {
        DispatchQueue.main.async {
            self.onXRAirGestured?(.PotentialDragOrClick)
        }
        
    }
}

extension XRGesturesMain {
    // Public interface.
    func onMouse(vx:Int, vy:Int) {
        self.cursorThreadTimer?.invalidate()
        self.mouseEvents.put(.cursor(vx: vx, vy: vy, ts: self.timestamp()))
        self.cursorThreadTimer = Timer.scheduledTimer(withTimeInterval: self.cursorFillTimeInterval, repeats: false, block: { _ in
            self.onMouse(vx: 0, vy: 0)
        })
    }
    
    func onGesture(gesture:Int) {
        if let g = self.clickMajorityVoting.call(gesture) {
            self.mouseEvents.put(.click(gesture: g, ts: self.timestamp()))
        }
    }
}

