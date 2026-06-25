//
//  TAPDeviceProtocol.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

public enum TAPDeviceProtocol {
    case legacy
    case v2
}

public enum TAPDeviceFeature {
    case battery
    case hardwareVersion
    case firmwareVersion
    case serialNumber
}

public struct TAPProtocolWrite {
    public let characteristic: CBUUID
    public let data: Data
    
    public init(characteristic: CBUUID, data: Data) {
        self.characteristic = characteristic
        self.data = data
    }
}

public struct TAPProtocolParsedMessage {
    public let characteristic: CBUUID
    public let payload: Data
    
    public init(characteristic: CBUUID, payload: Data) {
        self.characteristic = characteristic
        self.payload = payload
    }
}
