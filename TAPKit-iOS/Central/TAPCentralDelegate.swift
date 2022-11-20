//
//  TAPCentralDelegate.swift
//  TAPKit
//
//  Created by Shahar Biran on 09/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol TAPCentralDelegate {
    @objc optional func tapConnected(identifier uuid:String, name:String) -> Void
    @objc optional func tapDisconnected(identifier uuid:String) -> Void
    @objc optional func tapFailedToConnect(identifier uuid:String) -> Void
    @objc optional func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data)
}


//class TAPCentralDelegateWeakRef {
//
//    private weak var ref: TAPCentralDelegate?
//
//    init(_ ref: TAPCentralDelegate) {
//        self.ref = ref
//    }
//
//    func get() -> TAPCentralDelegate? {
//        return self.ref
//    }
//
//    func isAlive() -> Bool {
//        return self.ref != nil
//    }
//}
//
//class TAPCentralDelegatesController {
//    private var delegates : [TAPCentralDelegateWeakRef]
//
//    init() {
//        self.delegates = [TAPCentralDelegateWeakRef]()
//    }
//
//    private func removeNullReferences() -> Void {
//        self.delegates = self.delegates.filter({ $0.isAlive() })
//    }
//
//    func add(_ delegate:TAPCentralDelegate) -> Void {
//        self.removeNullReferences()
//        if (!self.delegates.contains(where: { $0.get() === delegate })) {
//
//            self.delegates.append(TAPCentralDelegateWeakRef(delegate))
//        }
//    }
//
//    func remove(_ delegate:TAPCentralDelegate) -> Void {
//        self.removeNullReferences()
//        self.delegates = self.delegates.filter({ $0.get() !== delegate })
//    }
//
//    func get() -> [TAPCentralDelegate] {
//        self.removeNullReferences()
//        return self.delegates.filter({ $0.isAlive()}).map({ $0.get()!})
//    }
//}
//
//extension TAPCentralDelegatesController : TAPCentralDelegate {
//    func tapDisconnected(withIdentifier identifier: String) {
//        self.get().forEach({
//            $0.tapDisconnected?(identifier: identifier)
//        })
//    }
//
//    func tapConnected(withIdentifier identifier: String, name: String, fw:Int) {
//        self.get().forEach({
//            $0.tapConnected?(identifier: identifier, name: name, fw:fw)
//        })
//    }
//
//    func tapFailedToConnect(withIdentifier identifier: String, name: String) {
//        self.get().forEach({
//            $0.tapFailedToConnect?(withIdentifier: identifier, name: name)
//        })
//    }
//
//    func tapped(identifier: String, combination: UInt8) {
//        self.get().forEach({
//            $0.tapped?(identifier: identifier, combination: combination)
//        })
//    }
//
//    func centralBluetoothState(poweredOn: Bool) {
//        self.get().forEach({
//            $0.centralBluetoothState?(poweredOn: poweredOn)
//        })
//    }
//
//    func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse:Bool) {
//        self.get().forEach({
//            $0.moused?(identifier: identifier, velocityX: velocityX, velocityY: velocityY, isMouse: isMouse)
//        })
//    }
//
//    func rawSensorDataReceived(identifier: String, data: RawSensorData) {
//        self.get().forEach({
//            $0.rawSensorDataReceived?(identifier: identifier, data: data)
//        })
//    }
//
//    func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool) {
//        self.get().forEach({
//            $0.tapChangedAirGesturesState?(identifier: identifier, isInAirGesturesState: isInAirGesturesState)
//        })
//    }
//
//    func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
//        self.get().forEach({
//            $0.tapAirGestured?(identifier: identifier, gesture: gesture)
//        })
//    }
//
//
//}
