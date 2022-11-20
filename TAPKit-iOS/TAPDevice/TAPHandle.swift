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
}

class TAPHandle : NSObject {
    
    
    private(set) var isReady : Bool
    
    private var peripheral : CBPeripheral!
    private var handleInit : TAPHandleInit
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
    
    private(set) var name : String
    override public var hash: Int {
        get {
            return self.identifier.hashValue
        }
    }
    
    init(peripheral: CBPeripheral!, handleInit : TAPHandleInit, delegate:TAPHandleDelegate) {
        self.name = ""
        self.peripheral = peripheral
        self.handleInit = handleInit
        self.values = [CBUUID : Data]()
        self.fullyDiscoveredServices = [CBUUID : Bool]()
        self.characteristics = [CBUUID : CBCharacteristic]()
        self.isReady = false
        self.delegate = delegate
        super.init()
        
        self.peripheral.delegate = self
        
    }
    
    private func serviceFullyDiscovered(_ uuid:CBUUID) {
        self.fullyDiscoveredServices[uuid] = true
        self.isReady = self.fullyDiscoveredServices.filter({ entry in entry.value == false}).count == 0
        if self.name == "" {
            self.name = self.peripheral.name ?? ""
        }
        if (self.isReady) {
            // Tap is Ready
            self.delegate?.TAPHandleIsReady(self)
        }
        
    }
    
    func makeReady() -> Void {
        self.peripheral.discoverServices(Array(self.handleInit.getServices()))
    }
    
    
    
    func read(_ uuid:CBUUID) {
        if let c = self.characteristics[uuid] {
            self.peripheral.readValue(for: c)
        }
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
            self.fullyDiscoveredServices[service.uuid] = false
        })
        // Twice. So we'll know which services are expected to be fully discovered
        peripheral.services?.forEach({ service in
            peripheral.discoverCharacteristics(Array(self.handleInit.getCharacteristics(forService: service.uuid)), for: service)
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
            discovered.insert(c.uuid)
            self.characteristics[c.uuid] = c
            if let instructions = self.handleInit.get(c.uuid) {
                if instructions.readWhenDiscovered {
                    self.peripheral.readValue(for: c)
                }
                if instructions.notify {
                    self.peripheral.setNotifyValue(true, for: c)
                }
            }
        })
        let shouldBeDiscovered = self.handleInit.getCharacteristics(forService: service.uuid)
        shouldBeDiscovered.forEach( { uuid in
            if (!discovered.contains(uuid)) {
                if let instructions = self.handleInit.get(uuid) {
                    if let defaultValue = instructions.defaultValueIfNotDiscovered {
                        self.values[uuid] = defaultValue
                    }
                }
            }
            
            
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        guard error == nil && peripheral.identifier == self.identifier else { return }
        if let instructions = self.handleInit.get(characteristic.uuid) {
            if (instructions.storeLastReadValue || instructions.readWhenDiscovered) {
                if let value = characteristic.value {
                    self.values[characteristic.uuid] = value
                }
                
            }
        }
    }
    
    
}
