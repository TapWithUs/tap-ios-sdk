//
//  TAPXRStateController.swift
//  TAPKit
//
//  Created by Shahar Biran on 24/06/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

protocol TAPXRStateControllerDelegate : AnyObject {
    func tapxrStateControllerUpdate(states:[String:TAPXRState]) -> Void
}

class TAPXRStateController {
    
    private var states : [String:TAPXRState]
    private var verified : Set<String>
    private var defaultState : TAPXRState
    private var timer:Timer?
    
    private var isActive : Bool
    weak var delegate : TAPXRStateControllerDelegate?
    
    init() {
        self.isActive = false
        self.defaultState = .userControl()
        self.states = [String:TAPXRState]()
        self.verified = Set<String>()
    }
    
    func get(identifier:String) -> TAPXRState? {
        guard self.verified.contains(identifier) else { return nil }
        return self.states[identifier] ?? self.defaultState
    }
    
    func add(identifier:String) -> Void {
        self.verified.insert(identifier)
        self.states[identifier] = self.defaultState
        if (self.isActive ) {
            DispatchQueue.main.async {
                self.delegate?.tapxrStateControllerUpdate(states: [identifier: self.states[identifier] ?? self.defaultState ])
            }
        }
    }
    
    func remove(identifier:String) -> Void {
        self.verified.remove(identifier)
        self.states.removeValue(forKey: identifier)
    }
    
    func set(state:TAPXRState, for identifier:String) -> Void {
        self.states[identifier] = state
        if (self.isActive) {
            if let state = self.get(identifier: identifier) {
                DispatchQueue.main.async {
                    self.delegate?.tapxrStateControllerUpdate(states: [identifier:state])
                }
            }
        }
        
    }
    
    func start() -> Void {
        self.isActive = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { _ in
            self.updateAll()
        })
        self.updateAll()
    }
    
    func resume() -> Void {
        self.start()
    }
    
    func pause(andSetState state:TAPXRState) -> Void {
        self.stop()
        let newStates = self.states.mapValues({ _ in state })
        self.delegate?.tapxrStateControllerUpdate(states: newStates)
    }
    
    func stop() -> Void {
        self.isActive = false
        self.timer?.invalidate()
    }
    
    @objc private func updateAll() -> Void {
        DispatchQueue.main.async {
            self.delegate?.tapxrStateControllerUpdate(states: self.states.filter({ self.verified.contains($0.key)}))
        }
    }
    
    func setDefault(state:TAPXRState, applyImmediate:Bool) -> Void {
        self.defaultState = state
        if (applyImmediate) {
            self.states.keys.forEach({ key in
                self.states[key] = state
            })
            self.updateAll()
        }
    }
    
}
