//
//  TAPCBUUID.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

class TAPCBUUID {
    private init() {
    
    }
    static var service__TAP = CBUUID(string: "C3FF0001-1D8B-40FD-A56F-C7BD5D0F3370")
    static var service__NUS = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static var characteristic__TAPData = CBUUID(string: "C3FF0005-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__MouseData = CBUUID(string: "C3FF0006-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__UICommands = CBUUID(string: "C3FF0009-1D8B-40FD-A56F-C7BD5D0F3370")
    static var characteristic__RX = CBUUID(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    
    
    static func getService(for characteristic:CBUUID) -> CBUUID? {
        if characteristic == characteristic__TAPData {
            return service__TAP
        } else if characteristic == characteristic__RX {
            return service__NUS
        } else if characteristic == characteristic__MouseData {
            return service__TAP
        } else if characteristic == characteristic__UICommands {
            return service__TAP
        }
        return nil
    }
}
