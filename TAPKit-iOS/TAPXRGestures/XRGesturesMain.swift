//
//  XRGestures.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation


public class XRGesturesMain {

    
    
    private var mouseEvents : MouseEvents
    private var mouseEventsInterpreter : MouseEventsInterpreter
    private var cursorThreadTimer : Timer?
    private var clickMajorityVoting : MajorityVoting<Int>
    public var ignoreEventsUntilRelease : Bool = false
    public var onXRAirGestured : ((TAPXRAirGesture) -> Void)?

    private var eventsCount : Int = 0
    
    private let cursorFillTimeInterval : TimeInterval = 0.1
    private var useMajority : Bool
    public init() {
        self.clickMajorityVoting = MajorityVoting(len: 3, defaultValue: XRGestureState.none.rawValue)
        self.useMajority = false
        self.mouseEvents = MouseEvents()
        self.mouseEventsInterpreter = MouseEventsInterpreter()
        self.mouseEvents.delegate = self
        self.mouseEventsInterpreter.onDrag = self.mouseEventsInterpreterOnDrag
        self.mouseEventsInterpreter.onClick = self.mouseEventsInterpreterOnClick
        self.mouseEventsInterpreter.onDrop = self.mouseEventsInterpreterOnDrop
        self.mouseEventsInterpreter.onPotentialDragOrClick = self.mouseEventsInterpreterOnPotientialDragOrClick
        self.mouseEventsInterpreter.onFistBegin = self.mouseEventsInterpreterOnFistBegin
        self.mouseEventsInterpreter.onFistEnd = self.mouseEventsInterpreterOnFistEnd
//        let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
//            print("events count (1s) = \(self.eventsCount)")
//            self.eventsCount = 0
//        })
    }
    
    private func timestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    public func resetEvents() {
        self.mouseEvents.resetGestures()
    }
}

extension XRGesturesMain : MouseEventsDelegate {
    func mouseEventsAction(_ action: MouseEventsAction) {
        if !self.ignoreEventsUntilRelease {
            self.mouseEventsInterpreter.action(action)
        }
        if action.isRelease() {
            self.ignoreEventsUntilRelease = false
        }
        
    }
}


extension XRGesturesMain {
    // Mouse events interpreter callbacks.
    private func getClick(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .ClickIndex
        case .middle : return .ClickMiddle
        case .ring : return .ClickRing
        case .pinky : return .ClickPinky
        }
    }
    
    private func getDrag(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .DragIndex
        case .middle : return .DragMiddle
        case .ring : return .DragRing
        case .pinky : return .DragPinky
        }
    }
    
    private func getPotentialDragOrClick(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .PotentialDragOrClickIndex
        case .middle : return .PotentialDragOrClickMiddle
        case .ring : return .PotentialDragOrClickRing
        case .pinky : return .PotentialDragOrClickPinky
        }
    }
    
    func mouseEventsInterpreterOnClick(finger:MouseEventFinger) {
        self.useMajority = false
        self.onXRAirGestured?(self.getClick(finger: finger))
    }
    
    func mouseEventsInterpreterOnDrag(finger:MouseEventFinger) {
        self.useMajority = true
        self.onXRAirGestured?(self.getDrag(finger: finger))
    }
    
    func mouseEventsInterpreterOnDrop() {
        self.useMajority = false
        self.onXRAirGestured?(.Drop)
    }
    
    func mouseEventsInterpreterOnPotientialDragOrClick(finger:MouseEventFinger) {
        self.onXRAirGestured?(self.getPotentialDragOrClick(finger: finger))
    }
    
    func mouseEventsInterpreterOnFistBegin() {
        self.onXRAirGestured?(.FistBegin)
    }
    
    func mouseEventsInterpreterOnFistEnd() {
        self.onXRAirGestured?(.FistEnd)
    }
}

extension XRGesturesMain {
    // Public interface.
    public func onMouse(vx:Int, vy:Int) {
        self.cursorThreadTimer?.invalidate()
        self.mouseEvents.put(.cursor(vx: vx, vy: vy, ts: self.timestamp()))
        self.cursorThreadTimer = Timer.scheduledTimer(withTimeInterval: self.cursorFillTimeInterval, repeats: false, block: { _ in
            self.onMouse(vx: 0, vy: 0)
        })
    }
    
    public func onGestureState(gesture:Int) {
//        self.eventsCount = self.eventsCount + 1
        let g = self.clickMajorityVoting.call(gesture)
        if (self.useMajority) {
            if let g {
                self.mouseEvents.put(.click(gesture:g, ts: self.timestamp()))
            }
        } else {
            self.mouseEvents.put(.click(gesture: gesture, ts: self.timestamp()))
        }
    }
}

