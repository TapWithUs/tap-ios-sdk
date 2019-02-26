//
//  TAPDevice.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol TAPDeviceDelegate : class {
    func TAPIsReady(identifier:String, name:String)
    func TAPtapped(identifier:String, combination:UInt8)
    func TAPMoused(identifier:String, vX:Int16, vY:Int16, isMouse:Bool)
    func TAPFailed(identifier:String, name:String)
}

class TAPDevice : NSObject {
    private var peripheral : CBPeripheral!
    private weak var delegate : TAPDeviceDelegate?
    private var rx:CBCharacteristic?
    private var uiCommands:CBCharacteristic?
    
    private var neccessaryCharacteristics : [CBUUID : Bool] = [TAPCBUUID.characteristic__RX : false, TAPCBUUID.characteristic__TAPData : false]
    private var optionalCharacteristics : [CBUUID : Bool] = [TAPCBUUID.characteristic__MouseData : false, TAPCBUUID.characteristic__UICommands : false]
    
    var supportsMouse : Bool {
        get {
            return optionalCharacteristics[TAPCBUUID.characteristic__MouseData] == true
        }
    }
    
    private(set) var isReady : Bool = false {
        willSet {
            if self.isReady == false && newValue == true {
                TAPKit.log.event(.info, message: "TAP \(self.identifier.uuidString),\(self.name) is ready to use!")
                self.writeMode()
                self.delegate?.TAPIsReady(identifier: self.identifier.uuidString, name:self.name)
            }
        }
    }
    
    private(set) var identifier : UUID!
    private(set) var name : String!
    private(set) var mode : String = TAPInputMode.defaultMode()
    private(set) var modeEnabled : Bool!
    
    override public var hash: Int {
        get {
            return self.identifier.hashValue
        }
    }
    
    
    init(peripheral p:CBPeripheral, delegate d:TAPDeviceDelegate) {
        super.init()
        self.peripheral = p
        self.identifier = p.identifier
        if let n = p.name {
            self.name = n
        } else {
            self.name = ""
        }
        self.delegate = d
        self.modeEnabled = true
    }
    
    func makeReady() -> Void {
        self.peripheral?.delegate = self
        self.peripheral?.discoverServices([TAPCBUUID.service__TAP, TAPCBUUID.service__NUS])
    }
    
    private func checkIfReady() -> Void {
        var allDiscovered = true
        for (_, value) in self.neccessaryCharacteristics {
            allDiscovered = allDiscovered && value
        }
        if self.name == "" {
            if let p = self.peripheral {
                if let n = p.name {
                    self.name = n
                }
            }
        }
        self.isReady = allDiscovered && self.name != "" && self.rx != nil
        
    }
    
    private func writeRX(_ data:Data) -> Void {
        if let rx = self.rx {
            if (peripheral.state == .connected) {
                let arr = [UInt8](data);
                if arr.count >= 3 {
                    let str = "\(arr[3])"
                    TAPKit.log.event(.info, message: "tap \(self.identifier.uuidString) writing mode data [\(str)]")
                }
                self.peripheral.writeValue(data, for: rx, type: .withoutResponse)
            } else {
                TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed writing mode: peripheral is not connected.")
            }
        }
    }
    
    func disableMode() -> Void {
        TAPKit.log.event(.info, message: "Disabled \(self.mode) for tap identifier \(self.identifier.uuidString)")
        self.modeEnabled = false
        if let data = TAPInputMode.data(forMode: TAPInputMode.modeWhenDisabled()) {
            self.writeRX(data)
        }
    }
    
    func enableMode() -> Void {
        TAPKit.log.event(.info, message: "Enabled [\(TAPInputMode.title(forMode: self.mode)))] for tap identifier \(self.identifier.uuidString)")
        self.modeEnabled = true
        self.writeMode()
    }
    
    func writeMode() -> Void {
        if (self.modeEnabled) {
            if let data = TAPInputMode.data(forMode: self.mode) {
                self.writeRX(data)
            }
        }
    }
    
    func setNewMode(_ newMode:String) -> Void {
        TAPKit.log.event(.info, message: "New Mode Set: \(TAPInputMode.title(forMode: self.mode)) for tap identifier \(self.identifier.uuidString)")
        self.mode = newMode
        self.writeMode()
    }
}

extension TAPDevice : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed discovered services: \(err.localizedDescription)")
            self.delegate?.TAPFailed(identifier: self.identifier.uuidString, name: self.name)
            return
        }
        if let services = peripheral.services {
            for service in services {
                var characteristicsToDiscover = [CBUUID]()
                for (characteristic, _) in self.neccessaryCharacteristics {
                    if let matchingService = TAPCBUUID.getService(for: characteristic) {
                        
                        if matchingService.uuidString == service.uuid.uuidString {
                            characteristicsToDiscover.append(characteristic)
                        }
                    }
                }
                for (characteristic, _) in self.optionalCharacteristics {
                    if let matchingService = TAPCBUUID.getService(for: characteristic) {
                        if matchingService.uuidString == service.uuid.uuidString {
                            characteristicsToDiscover.append(characteristic)
                        }
                    }
                }
                // Mouse is optional :
                
                if characteristicsToDiscover.count > 0 {
                    peripheral.discoverCharacteristics(characteristicsToDiscover, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed discovered characteristics: \(err.localizedDescription)")
            self.delegate?.TAPFailed(identifier: self.identifier.uuidString, name: self.name)
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if self.neccessaryCharacteristics.contains(where: { $0.key == characteristic.uuid}) {
                    self.neccessaryCharacteristics[characteristic.uuid] = true
                    if characteristic.uuid.uuidString == TAPCBUUID.characteristic__RX.uuidString {
                        self.rx = characteristic
                    } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TAPData.uuidString {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    }
                    self.checkIfReady()
                } else if self.optionalCharacteristics.contains(where: { $0.key == characteristic.uuid}) {
                    self.optionalCharacteristics[characteristic.uuid] = true
                    if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__MouseData.uuidString) {
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    } else if (characteristic.uuid.uuidString == TAPCBUUID.characteristic__UICommands.uuidString) {
                        self.uiCommands = characteristic
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            if characteristic.uuid.uuidString == TAPCBUUID.characteristic__RX.uuidString {
                TAPKit.log.event(.error, message: "tap \(self.identifier.uuidString) failed writing input mode: \(err.localizedDescription)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid.uuidString == TAPCBUUID.characteristic__TAPData.uuidString {
            if let value = characteristic.value {
                let bytes = [UInt8](value)
                if let first = bytes.first {
                    if first > 0 && first <= 31 {
                        self.delegate?.TAPtapped(identifier: self.identifier.uuidString, combination: first)
                    }
                }
                
            }
        } else if characteristic.uuid.uuidString == TAPCBUUID.characteristic__MouseData.uuidString {
            
            if let value = characteristic.value {
                let bytes : [UInt8] = [UInt8](value)
                if bytes.count >= 10 {
                    if (bytes[0] == 0 ) {
                        self.delegate?.TAPMoused(identifier: self.identifier.uuidString, vX: (Int16)(bytes[2]) << 8 | (Int16)(bytes[1]), vY: (Int16)(bytes[4]) << 8 | (Int16)(bytes[3]), isMouse: bytes[9] == 1)
                    }
                }
            }
        }
    }
}
