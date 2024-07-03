//
//  TAPXRState.swift
//  TAPKit
//
//  Created by Shahar Biran on 24/06/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class TAPXRState : NSObject {
    @objc public static let kUserControl : String = "User"
    @objc public static let kAirMouse : String = "AirMouse"
    @objc public static let kTapping : String = "Tapping"
    @objc public static let kDontSend : String = "DontSend"
    private static let stateByte : [String:UInt8] = [TAPXRState.kUserControl : 0x3, TAPXRState.kTapping : 0x2, TAPXRState.kAirMouse : 0x1]
    
    public let type:String
    
    private init(type:String) {
        self.type = type
        super.init()
    }
    
    @objc public static func userControl() -> TAPXRState {
        return TAPXRState(type: TAPXRState.kUserControl)
    }
    
    @objc public static func airMouse() -> TAPXRState {
        return TAPXRState(type: TAPXRState.kAirMouse)
    }
    
    @objc public static func tapping() -> TAPXRState {
        return TAPXRState(type: TAPXRState.kTapping)
    }
    
    @objc public static func dontSend() -> TAPXRState {
        return TAPXRState(type: TAPXRState.kDontSend)
    }
    
    func data() -> Data? {
        guard let stateValue = TAPXRState.stateByte[self.type] else {
            return nil
        }
        
        let bytes : [UInt8] = [0x3,0xd,0x0,stateValue]
        let d = Data.init(bytes: bytes)
        return d
    }
    

}
