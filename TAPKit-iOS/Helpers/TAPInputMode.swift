//
//  TAPMode.swift
//  TAPKit
//
//  Created by Shahar Biran on 26/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation


@objc public class TAPInputMode : NSObject {

     
    
    @objc public static let controller : String = "tapinputmodecontroller"
    @objc public static let text : String = "tapinputmodetext"
    
    private override init() {
        super.init()
    }
    
    static func modeWhenDisabled() -> String {
        return TAPInputMode.text
    }
    
    static func defaultMode() -> String {
        return TAPInputMode.controller
    }
    
    static func data(forMode mode:String) -> Data {
        var modeValue : UInt8 = 0x0
        if (mode == TAPInputMode.controller) {
            modeValue = 0x1
        }
        let bytes : [UInt8] = [0x3,0xc,0x0,modeValue]
        let d = Data.init(bytes: bytes)
        return d
    }
    
    static func title(forMode mode:String) -> String {
        switch mode {
        case TAPInputMode.text : return "Text Mode"
        case TAPInputMode.controller : return "Controller mode"
        default : return ""
        }
    }
}
