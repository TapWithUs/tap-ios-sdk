//
//  TAPHandleInit.swift
//  TAPKit
//
//  Created by Shahar Biran on 07/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

struct TAPHandleInitCharacteristic {
    let uuid : CBUUID
    let readWhenDiscovered : Bool
    let defaultValueIfNotDiscovered : Data?
    let storeLastReadValue : Bool
    let notify:Bool
    
    
    init(uuid:CBUUID, readWhenDiscovered:Bool=false, defaultValueIfNotDiscovered : Data? = nil, storeLastReadValue : Bool=false, notify:Bool=false) {
        self.uuid = uuid
        self.readWhenDiscovered = readWhenDiscovered
        self.defaultValueIfNotDiscovered = defaultValueIfNotDiscovered
        self.storeLastReadValue = storeLastReadValue;
        self.notify = notify
    }
}

class TAPHandleInit {
    private(set) var characteristics : [CBUUID : TAPHandleInitCharacteristic]!
    
    init(characteristics: [TAPHandleInitCharacteristic]) {
        self.characteristics = [CBUUID : TAPHandleInitCharacteristic]();
        characteristics.forEach({ c in
            self.characteristics[c.uuid] = c
        })
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
            if let service = TAPCBUUID.sharedManager.getService(for: uuid) {
                if service == serviceUUID {
                    characteristics.insert(uuid)
                }
            }
        })
        return characteristics
    }
    
    public func get(_ uuid:CBUUID) -> TAPHandleInitCharacteristic? {
        return self.characteristics[uuid]
    }
    
    
}
