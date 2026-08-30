//
//  TAPDeviceProtocol.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

enum TAPDeviceProtocol {
    case legacy
    case v2
}

enum TAPDeviceFeature {
    case battery
    case hardwareVersion
    case firmwareVersion
    case serialNumber
}

struct TAPProtocolWrite {
    let characteristic: CBUUID
    let data: Data
    
    init(characteristic: CBUUID, data: Data) {
        self.characteristic = characteristic
        self.data = data
    }
}

struct TAPProtocolParsedMessage {
    let characteristic: CBUUID
    let payload: Data
    
    init(characteristic: CBUUID, payload: Data) {
        self.characteristic = characteristic
        self.payload = payload
    }
}
