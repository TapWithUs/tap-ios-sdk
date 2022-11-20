//
//  TAPAirGestureController.swift
//  TAPKit
//
//  Created by Shahar Biran on 16/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

class TAPAirGestureController : NSObject {
    
    private var inStates : [String : Bool]
    override init() {
        self.inStates = [String : Bool]()
        super.init()
    }
    
    func reset() {
        self.inStates.removeAll()
    }
    
    func setInState(uuid:String, inState:Bool) {
        self.inStates[uuid] = inState
    }
    
    func isInState(uuid:String) -> Bool {
        return self.inStates[uuid] ?? false
    }
    
}
