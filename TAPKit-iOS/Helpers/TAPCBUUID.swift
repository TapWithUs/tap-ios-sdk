//
//  TAPCBUUID.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol TAPCBUUIDProtocol : AnyObject {
    func getService(for characteristic:CBUUID) -> CBUUID?
}


class TAPCBUUIDManager {
    
    static let sharedManager = TAPCBUUIDManager()
    
    private(set) var UUIDS : TAPCBUUIDProtocol!
    
    private init() {
        self.UUIDS = TAPCBUUID()
    }
    
    func use(_ uuidsProtocol:TAPCBUUIDProtocol) {
        self.UUIDS = uuidsProtocol
    }
    
    func getService(for characteristic:CBUUID) -> CBUUID? {
        return self.UUIDS.getService(for: characteristic)
    }
}


class TAPCBUUID : TAPCBUUIDProtocol {
    
    init() {
        
    }
    
    static var service__DeviceInformation = CBUUID(string: "180A")
    static var service__TAP = CBUUID(string: "C3FF0001-1D8B-40FD-A56F-C7BD5D0F3370")
    static var service__NUS = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static var characteristic__TAPData = CBUUID(string: "C3FF0005-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__MouseData = CBUUID(string: "C3FF0006-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__AirGestures = CBUUID(string: "C3FF000A-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__UICommands = CBUUID(string: "C3FF0009-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__RX = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static var characteristic__TX = CBUUID(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    static var characteristic__HW = CBUUID(string: "2A27")
    static var characteristic__FW = CBUUID(string: "2A26")
    
    func getService(for characteristic:CBUUID) -> CBUUID? {
        if characteristic == TAPCBUUID.characteristic__TAPData {
            return TAPCBUUID.service__TAP
        } else if characteristic == TAPCBUUID.characteristic__RX || characteristic == TAPCBUUID.characteristic__TX {
            return TAPCBUUID.service__NUS
        } else if characteristic == TAPCBUUID.characteristic__MouseData {
            return TAPCBUUID.service__TAP
        } else if characteristic == TAPCBUUID.characteristic__UICommands {
            return TAPCBUUID.service__TAP
        } else if characteristic == TAPCBUUID.characteristic__AirGestures {
            return TAPCBUUID.service__TAP
        } else if characteristic == TAPCBUUID.characteristic__FW || characteristic == TAPCBUUID.characteristic__HW {
            return TAPCBUUID.service__DeviceInformation
        }
        return nil
    }
    
    
}

