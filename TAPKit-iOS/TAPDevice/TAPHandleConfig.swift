//
//  TAPHandleInit.swift
//  TAPKit
//
//  Created by Shahar Biran on 07/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

struct TAPHandleConfigCharacteristic {
    let uuid : CBUUID
    let readOnDiscover : Bool
    let defaultValueIfNotDiscovered : Data?
    let storeLastReadValue : Bool
    let notify:Bool
    
    
    init(uuid:CBUUID, readOnDiscover:Bool=false, defaultValueIfNotDiscovered : Data? = nil, storeLastReadValue : Bool=false, notify:Bool=false) {
        self.uuid = uuid
        self.readOnDiscover = readOnDiscover
        self.defaultValueIfNotDiscovered = defaultValueIfNotDiscovered
        self.storeLastReadValue = storeLastReadValue;
        self.notify = notify
    }
}

class TAPHandleConfig {
    private(set) var characteristics : [CBUUID : TAPHandleConfigCharacteristic]!
    
    init() {
        self.characteristics = [CBUUID : TAPHandleConfigCharacteristic]()
    }
    
    init(characteristics: [TAPHandleConfigCharacteristic]) {
        self.characteristics = [CBUUID : TAPHandleConfigCharacteristic]();
        characteristics.forEach({ c in
            self.characteristics[c.uuid] = c
        })
    }
    
    public func add(_ characteristic:TAPHandleConfigCharacteristic, overwrite:Bool=false) -> Void {
        
        if let _ = self.characteristics[characteristic.uuid] {
            if overwrite {
                self.characteristics[characteristic.uuid] = characteristic
            }
        } else {
            self.characteristics[characteristic.uuid] = characteristic
        }
    }
    
    public func getServices() -> Set<CBUUID> {
        var services : Set<CBUUID> = Set<CBUUID>()
        self.characteristics.forEach( { (uuid, c) in
            if let service = TAPCBUUIDManager.sharedManager.getService(for: c.uuid) {
                services.insert(service)
            }
        })
        return services
    }
    
    public func getCharacteristics(forService serviceUUID : CBUUID) -> Set<CBUUID> {
        var characteristics : Set<CBUUID> = Set<CBUUID>()
        self.characteristics.forEach({ (uuid, c) in
            if let service = TAPCBUUIDManager.sharedManager.getService(for: uuid) {
                if service == serviceUUID {
                    characteristics.insert(uuid)
                }
            }
        })
        return characteristics
    }
    
    public func get(_ uuid:CBUUID) -> TAPHandleConfigCharacteristic? {
        return self.characteristics[uuid]
    }
    
}
