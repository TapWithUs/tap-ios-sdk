//
//  TAPInputModeController.swift
//  TAPKit
//
//  Created by Shahar Biran on 14/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

@objc protocol TAPInputModeControllerDelegate : AnyObject {
    @objc func TAPInputModeUpdate(modes:[String:TAPInputMode]) -> Void
}

class TAPInputModeController : NSObject {
    
    private var timer:Timer?
    private var defaultInputMode : TAPInputMode
    public var modes : [String : TAPInputMode]
    weak var delegate : TAPInputModeControllerDelegate?
    private var interval : TimeInterval
    private var isActive : Bool
    
    init(interval:TimeInterval, delegate:TAPInputModeControllerDelegate?=nil) {
        self.isActive = false
        self.interval = interval
        self.delegate = delegate
        self.timer = nil
        self.defaultInputMode = TAPInputMode.controller()
        self.modes = [String : TAPInputMode]()
        super.init()
    }
    
    func reset(defaultInputMode:TAPInputMode = TAPInputMode.controller()) {
        self.stop()
        self.defaultInputMode = defaultInputMode
        self.modes.removeAll()
    }
    
    func set(defaultInputMode:TAPInputMode, immediate:Bool) -> Void {
        
        self.defaultInputMode = defaultInputMode
        self.modes.keys.forEach({ uuid in
            self.modes[uuid] = defaultInputMode
        })
    }
    
    func set(inputMode:TAPInputMode, identifiers:[String]? = nil) {
        if let identifiers = identifiers {
            identifiers.forEach( { uuid in
                self.modes[uuid] = inputMode
            })
        } else {
            self.modes.keys.forEach({ uuid in
                self.modes[uuid] = inputMode
            })
        }
        self.delegate?.TAPInputModeUpdate(modes: self.modes)
    }
    
    func get(identifier:String) -> TAPInputMode? {
        return self.modes[identifier]
    }
    
    func add(_ uuid:String) -> Void {
        self.modes[uuid] = self.defaultInputMode
        if (self.isActive) {
            self.delegate?.TAPInputModeUpdate(modes: [uuid:self.defaultInputMode])
        }
    }
    
    func remove(_ uuid:String) -> Void {
        self.modes.removeValue(forKey: uuid)
    }
    
    func start() {
        self.isActive = true
        self.timer = Timer.scheduledTimer(timeInterval: self.interval, target: self, selector: #selector(modeTimerTick(timer:)), userInfo: nil, repeats: true)
        self.modeTimerTick(timer: self.timer)
    }
    
    func refresh() -> Void {
        if self.isActive {
            self.delegate?.TAPInputModeUpdate(modes: self.modes)
        }
    }
    
    @objc func modeTimerTick(timer: Timer?) -> Void {
        if self.isActive {
            self.delegate?.TAPInputModeUpdate(modes: self.modes)
        }
        
    }
    
    func stop() {
        self.isActive = false
        self.timer?.invalidate()
    }
    
    func pause(andSetMode mode:TAPInputMode) {
        self.stop()
        let newModes = self.modes.mapValues({ _ in mode })
        self.delegate?.TAPInputModeUpdate(modes: newModes)
    }
    
    func resume() {
        self.start()
    }
}
