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
    
    
    public var onXRAirGestured : ((TAPXRAirGesture) -> Void)?
    
    private let cursorFillTimeInterval : TimeInterval = 0.1
    
    public init() {
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
    private func getClick(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .ClickIndex
        case .middle : return .ClickMiddle
        }
    }
    
    private func getDrag(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .DragIndex
        case .middle : return .DragMiddle
        }
    }
    
    private func getPotentialDragOrClick(finger:MouseEventFinger) -> TAPXRAirGesture {
        switch finger {
        case .index : return .PotentialDragOrClickIndex
        case .middle : return .PotentialDragOrClickMiddle
        }
    }
    
    func mouseEventsInterpreterOnClick(finger:MouseEventFinger) {
        DispatchQueue.main.async {
            self.onXRAirGestured?(self.getClick(finger: finger))
        }
        
    }
    
    func mouseEventsInterpreterOnDrag(finger:MouseEventFinger) {
        DispatchQueue.main.async {
            self.onXRAirGestured?(self.getDrag(finger: finger))
        }
        
        
    }
    
    func mouseEventsInterpreterOnDrop() {
        DispatchQueue.main.async {
            self.onXRAirGestured?(.Drop)
        }
        
    }
    
    func mouseEventsInterpreterOnPotientialDragOrClick(finger:MouseEventFinger) {
        DispatchQueue.main.async {
            self.onXRAirGestured?(self.getPotentialDragOrClick(finger: finger))
        }
        
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
        if let g = self.clickMajorityVoting.call(gesture) {
            self.mouseEvents.put(.click(gesture: g, ts: self.timestamp()))
        }
    }
}

