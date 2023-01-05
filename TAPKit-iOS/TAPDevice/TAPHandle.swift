//
//  TAPDevice2.swift
//  TAPKit
//
//  Created by Shahar Biran on 06/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol TAPHandleDelegate : class {
    func TAPHandleIsReady(_ handle:TAPHandle)
    func TAPHandleDidUpdateCharacteristicValue(_ handle:TAPHandle, characteristic:CBUUID, value:Data)
}

class TAPHandle : NSObject {
    
    
    private(set) var isReady : Bool
    
    private var peripheral : CBPeripheral!
    private var handleConfig : TAPHandleConfig!
    private var values : [CBUUID: Data]
    private var characteristics : [CBUUID : CBCharacteristic]
    private var fullyDiscoveredServices : [CBUUID : Bool]
    
    
    private weak var delegate : TAPHandleDelegate?
    
    
    var identifier : UUID {
        get {
            return self.peripheral.identifier
        }
    }
    var identifierString : String {
        get {
            return self.peripheral.identifier.uuidString
        }
    }
    
    public var name : String {
        get {
            return self.peripheral.name ?? "TAP\(self.identifierString)"
        }
        
    }
    

    override public var hash: Int {
        get {
            return self.identifier.hashValue
        }
    }
    
    init(peripheral: CBPeripheral!, handleConfig : TAPHandleConfig, delegate:TAPHandleDelegate) {
        self.peripheral = peripheral
        self.handleConfig = handleConfig
        self.values = [CBUUID : Data]()
        self.fullyDiscoveredServices = [CBUUID : Bool]()
        self.characteristics = [CBUUID : CBCharacteristic]()
        self.isReady = false
        self.delegate = delegate
        super.init()
        
        self.peripheral.delegate = self
        
    }
    
    private func checkIfReady() -> Void {
        guard !self.isReady else { return }
        let servicesDiscovered : Bool = self.fullyDiscoveredServices.filter({ entry in entry.value == false}).count == 0
        if (servicesDiscovered) {
            // Check for mandatory values.
            var hasMandatoryValues = true
            self.handleConfig.forEach({ uuid, config in
                if config.valueIsMandatory {
                    if !self.values.keys.contains(uuid) {
                        hasMandatoryValues = false
                    }
                }
            })
            self.isReady = hasMandatoryValues
        }
        
        if (self.isReady) {
            self.delegate?.TAPHandleIsReady(self)
        }
        
    }
    
    private func serviceFullyDiscovered(_ uuid:CBUUID) {
        self.fullyDiscoveredServices[uuid] = true
        self.checkIfReady()
//        self.isReady = self.fullyDiscoveredServices.filter({ entry in entry.value == false}).count == 0
//        if (self.isReady) {
//            // Tap is Ready
//            self.delegate?.TAPHandleIsReady(self)
//        }
//
    }
    
    func makeReady() -> Void {
        self.peripheral.discoverServices(Array(self.handleConfig.getServices()))
    }
    
    func read(_ uuid:CBUUID, forcePeripheralRead:Bool = false) {
        if let c = self.characteristics[uuid] {
            print("FOUND CHARACTERISTIC!")
            if (!forcePeripheralRead) {
                if let value = self.values[uuid] {
                    self.delegate?.TAPHandleDidUpdateCharacteristicValue(self, characteristic: uuid, value: value)
                } else {
                    self.peripheral.readValue(for: c)
                }
            } else {
                self.peripheral.readValue(for: c)
            }
        } else {
            print("CHARACTERISTIC \(uuid.uuidString) NOT FOUND ")
        }
    }
    
    func getStoredValue(characteristic:CBUUID) -> Data? {
        return self.values[characteristic]
    }
    
    func write(_ uuid:CBUUID, value:Data) {
        if let c = self.characteristics[uuid] {
            self.peripheral.writeValue(value, for: c, type: .withoutResponse)
        }
    }
    
}

extension TAPHandle : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        guard error == nil && peripheral.identifier == self.identifier else { return }
        
        peripheral.services?.forEach({ service in
            TAPKit.log.event(.info, message: "tap \(peripheral.identifier.uuidString) discovered service \(service.uuid.uuidString)")
            self.fullyDiscoveredServices[service.uuid] = false
        })
        // Twice. So we'll know which services are expected to be fully discovered
        peripheral.services?.forEach({ service in
            peripheral.discoverCharacteristics(Array(self.handleConfig.getCharacteristics(forService: service.uuid)), for: service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        
        guard error == nil && peripheral.identifier == self.identifier else {
            self.serviceFullyDiscovered(service.uuid)
            return
        }
        
        var discovered = Set<CBUUID>()
        
        service.characteristics?.forEach({ c in
            TAPKit.log.event(.info, message: "tap \(peripheral.identifier.uuidString) discovered characteristic \(c.uuid.uuidString) for service \(service.uuid.uuidString)")
            discovered.insert(c.uuid)
            self.characteristics[c.uuid] = c
            if let instructions = self.handleConfig.get(c.uuid) {
                if instructions.readOnDiscover {
                    self.peripheral.readValue(for: c)
                }
                if instructions.notify {
                    self.peripheral.setNotifyValue(true, for: c)
                }
            }
        })
        let shouldBeDiscovered = self.handleConfig.getCharacteristics(forService: service.uuid)
        shouldBeDiscovered.forEach( { uuid in
            if (!discovered.contains(uuid)) {
                if let instructions = self.handleConfig.get(uuid) {
                    if let defaultValue = instructions.defaultValueIfNotDiscovered {
                        self.values[uuid] = defaultValue
                    }
                }
            }
        })
        self.serviceFullyDiscovered(service.uuid)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        guard error == nil && peripheral.identifier == self.identifier else { return }
        
        if let value = characteristic.value {
            if let instructions = self.handleConfig.get(characteristic.uuid) {
                if (instructions.storeLastReadValue || instructions.readOnDiscover) {
                    self.values[characteristic.uuid] = value
                }
            }
            
            self.delegate?.TAPHandleDidUpdateCharacteristicValue(self, characteristic: characteristic.uuid, value: value)
        }
        
        self.checkIfReady()
    }
    
    
}
