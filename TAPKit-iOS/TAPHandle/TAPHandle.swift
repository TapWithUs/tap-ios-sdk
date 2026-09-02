//
//  TAPHandle.swift
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
    func TAPHandleDidWriteCharacteristicValue(_ handle:TAPHandle, characteristic:CBUUID, value:Data?)
    func TAPValidate(_ handle:TAPHandle) -> Bool
}

public class TAPHandle : NSObject {
    
    
    private(set) var isReady : Bool
    private(set) var protocolAdapter : TAPProtocolAdapter?
    
    private var peripheral : CBPeripheral!
    private var handleConfig : TAPHandleConfig
    private var values : [CBUUID: Data]
    private var characteristics : [CBUUID : CBCharacteristic]
    private var fullyDiscoveredServices : [CBUUID : Bool]
    private var protocolActivated : Bool
    
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
    
    var name : String {
        get {
            return self.peripheral.name ?? "TAP\(self.identifierString)"
        }
        
    }
    

    public override var hash: Int {
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
        self.protocolActivated = false
        self.delegate = delegate
        super.init()
        self.peripheral.delegate = self
        
    }
    
    private func checkIfReady() -> Void {
        guard !self.isReady else { return }
        let servicesDiscovered : Bool = self.fullyDiscoveredServices.filter({ entry in entry.value == false}).count == 0
        if (servicesDiscovered) {
            if !self.protocolActivated {
                self.activateProtocolAdapter()
            }
            self.isReady = self.delegate?.TAPValidate(self) ?? false
        }
        
        if (self.isReady) {
            self.delegate?.TAPHandleIsReady(self)
        }
        
    }
    
    private func activateProtocolAdapter() {
        self.protocolAdapter = TAPProtocolDetector.detect(handle: self)
        self.protocolActivated = true
        guard let adapter = self.protocolAdapter else { return }
        adapter.characteristicInstructions().forEach { uuid, instructions in
            if let characteristic = self.characteristics[uuid] {
                if instructions.readOnDiscover {
                    self.peripheral.readValue(for: characteristic)
                }
                if instructions.notify {
                    self.peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    private func serviceFullyDiscovered(_ uuid:CBUUID) {
        self.fullyDiscoveredServices[uuid] = true
        self.checkIfReady()
    }
    
    func makeReady() -> Void {

        self.peripheral.discoverServices(Array(self.handleConfig.getServices()))
    }
    
    func read(_ uuid:CBUUID, forcePeripheralRead:Bool = false) {
        if let c = self.characteristics[uuid] {
            
            if (!forcePeripheralRead) {
                if let value = self.values[uuid] {
                    self.delegate?.TAPHandleDidUpdateCharacteristicValue(self, characteristic: uuid, value: value)
                } else {
                    self.peripheral.readValue(for: c)
                }
            } else {
                self.peripheral.readValue(for: c)
            }
        }
    }
    
    func hasCharacteristic(_ uuid:CBUUID) -> Bool {
        return self.characteristics.keys.contains(uuid)
    }
    
    public func getStoredValue(_ characteristic:CBUUID) -> Data? {
        return self.values[characteristic]
    }
    
    func write(_ uuid:CBUUID, value:Data) {
        if let c = self.characteristics[uuid] {
            self.peripheral.writeValue(value, for: c, type: TAPCBUUIDManager.sharedManager.getWriteType(for: uuid))
        }
    }
    
    func write(_ writes: [TAPProtocolWrite]) {
        writes.forEach { write in
            self.write(write.characteristic, value: write.data)
        }
    }
    
}

extension TAPHandle : CBPeripheralDelegate {
    // These must be public: TAPHandle is a public class, and non-public methods in
    // this extension don't witness the @objc optional requirements, so no Objective-C
    // entrypoint is generated. Without it, CoreBluetooth can't deliver delegate
    // callbacks (API MISUSE warning, service discovery never completes).
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        guard error == nil && peripheral.identifier == self.identifier else { return }
        
        peripheral.services?.forEach({ service in
            TAPKit.log.event(.info, message: "tap \(peripheral.identifier.uuidString) discovered service \(service.uuid.uuidString)")
            self.fullyDiscoveredServices[service.uuid] = false
        })
        peripheral.services?.forEach({ service in
            peripheral.discoverCharacteristics(Array(self.handleConfig.getCharacteristics(forService: service.uuid)), for: service)
        })
    }
     
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        guard error == nil && peripheral.identifier == self.identifier else { return }
        
        if let value = characteristic.value {
            if let adapter = self.protocolAdapter,
               characteristic.uuid == TAPCBUUID.characteristic__V2Read {
                adapter.parseNotification(value).forEach { message in
                    self.delegate?.TAPHandleDidUpdateCharacteristicValue(self, characteristic: message.characteristic, value: message.payload)
                }
            } else {
                let instructions = self.protocolAdapter?.characteristicInstructions()[characteristic.uuid]
                    ?? self.handleConfig.get(characteristic.uuid)
                if let instructions = instructions {
                    if (instructions.storeLastReadValue || instructions.readOnDiscover) {
                        self.values[characteristic.uuid] = value
                    }
                }
                self.delegate?.TAPHandleDidUpdateCharacteristicValue(self, characteristic: characteristic.uuid, value: value)
            }
        }
        
        self.checkIfReady()
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            TAPKit.log.event(.error, message: error.localizedDescription)
        }
        
        guard error == nil && peripheral.identifier == self.identifier else { return }
        self.delegate?.TAPHandleDidWriteCharacteristicValue(self, characteristic: characteristic.uuid, value: characteristic.value)
    }
    
}
