//
//  TapHoldController.swift
//  TAPKit
//
//  Created by Shahar Biran on 15/10/2025.
//  Copyright © 2025 Shahar Biran. All rights reserved.
//

import Foundation

protocol TapHoldControllerDelegate : AnyObject {
    func tapHoldSingleTap(identifier:String, combination:UInt8)
    func tapHoldStarted(identifier:String, combination:UInt8)
    func tapHoldEnded(identifier:String, combination:UInt8)
}

class TapHoldController {
    private var t : [String:TapStateStruct]
    
    weak var delegate : TapHoldControllerDelegate?
    private var ma : [String:MajorityVoting<UInt8>]
    private enum TapStateEnum {
        case tappedOnce
        case tappedMore
    }
    
    private struct TapStateStruct {
        let combination:UInt8
        var state:TapStateEnum
    }
    
    init() {
        self.t = [String:TapStateStruct]()
        self.ma = [String:MajorityVoting<UInt8>]()
    }
    
    init(delegate:TapHoldControllerDelegate) {
        self.t = [String:TapStateStruct]()
        self.delegate = delegate
        self.ma = [String:MajorityVoting<UInt8>]()
    }
    
    func delegateFunc(f:(TapHoldControllerDelegate)->Void) -> Void {
        if let d = self.delegate {
            f(d)
        }
    }
    
    private func getMajority(identifier:String, combination:UInt8) -> UInt8? {
        
        if !self.ma.keys.contains(identifier) {
            self.ma[identifier] = MajorityVoting(len: 3, defaultValue: 0)
        }
        return self.ma[identifier]?.call(combination)
    }
    
    func tapped(identifier:String, combination:UInt8) {
        // Old state can be: nil, TappedOnce, TappedMore.
        // New state can be: None (Combination == 0), Tapped (Combination > 0)
        
        // If new state is None (combination = 0):
        //   If old state is nil: Ignore.
        //   If old state is tappedOnce : Ignore.
        //   If old state is TappedMore : fire TapHoldEnded event.
        //   oldState ==> nil.
        
        // If new state is Tapped(combination > 0):
        //   If old state is nil : state = tappedOnce. Fire tapped event.
        //   Else If states combination equal:
        //      If old state is TappedOnce: set new state to TappedMore. Fire tapHoldStart event.
        //      If old state is TappedMore: Ignore.
        //   Else if states combination are not equal:
        //      Fire tapHoldEndEvent with old combination.
        //      Set old state to nil.
        //      Recursive call with same parameters.

        
        
        guard let comb = self.getMajority(identifier: identifier, combination: combination) else { return }
        let oldState = self.t[identifier]
        let newStateTapped = comb > 0
        
        if newStateTapped {
            if let oldState {
                if oldState.combination == comb {
                    if oldState.state == .tappedOnce {
                        self.t[identifier]?.state = .tappedMore
                        self.delegateFunc(f: { f in f.tapHoldStarted(identifier: identifier, combination: comb)})
                    }
                } else {
                    self.delegateFunc(f: { f in f.tapHoldEnded(identifier: identifier, combination: oldState.combination)})
                    self.t.removeValue(forKey: identifier)
                    self.tapped(identifier: identifier, combination: comb)
                }
            } else {
                self.t[identifier] = TapStateStruct(combination: comb, state: .tappedOnce)
                self.delegateFunc(f: { f in f.tapHoldSingleTap(identifier: identifier, combination: comb)})
            }
        } else {
            if let oldState {
                if oldState.state == .tappedMore {
                    self.delegateFunc(f: { f in f.tapHoldEnded(identifier: identifier, combination: oldState.combination)})
                }
                self.t.removeValue(forKey: identifier)
            }
        }
    }
}
