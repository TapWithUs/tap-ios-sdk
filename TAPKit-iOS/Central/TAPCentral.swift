//
//  TAPCentral.swift
//  TAPKit-Example
//
//  Created by Shahar Biran on 09/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth


class TAPCentral : NSObject {

    
    private var centralManager : CBCentralManager!
    
    private var pending : Set<CBPeripheral>!
    private var taps : Set<TAPHandle>!
    private var started : Bool!
    private var isBluetoothOn : Bool!
    private var appActive : Bool = true
    private var handleConfig : TAPHandleConfig!
    private weak var delegate : TAPCentralDelegate?
    private var connectionTimer : Timer?
    
    
    convenience init(handleInit:TAPHandleConfig, delegate:TAPCentralDelegate?) {
        self.init()
        
        self.delegate = delegate
        self.handleConfig = handleInit
        self.isBluetoothOn = false
        self.pending = Set<CBPeripheral>()
        self.taps = Set<TAPHandle>()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.started = false
        self.centralManagerDidUpdateState(self.centralManager)
    }
    
    
    private func bluetoothIsOff() -> Void {
        if (self.isBluetoothOn) {
            
            TAPKit.log.event(.info, message: "Bluetooth poweredOff")
            self.isBluetoothOn = false
            self.pending.removeAll()
            self.taps.removeAll()
            self.stopConnectionTimer()
        }
    }
    
    private func bluetoothIsOn() -> Void {
        if (!self.isBluetoothOn) {
            TAPKit.log.event(.info, message: "Bluetooth poweredOn")
            self.isBluetoothOn = true
            if (self.started) {
                self.start()
            }
        }
    }
    
    private func isPending(_ peripheral:CBPeripheral) -> Bool {
        return self.pending.contains(peripheral)
    }
    
    private func isConnected(_ peripheral:CBPeripheral) -> Bool {
        return self.taps.contains(where: { $0.identifier == peripheral.identifier })
    }
    
    private func isNewPeripheral(_ peripheral:CBPeripheral) -> Bool {
        return !self.isPending(peripheral) && !self.isConnected(peripheral)
    }
    
    
    private func tapIndex(_ peripheral:CBPeripheral) -> Set<TAPHandle>.Index? {
        return self.taps.index(where: { $0.identifier == peripheral.identifier})
    }
    
    private func getTapHandle(_ identifier:String) -> TAPHandle? {
        return self.taps.filter({ handle in handle.identifierString == identifier}).first
    }
    
    private func stopConnectionTimer() -> Void {
        self.connectionTimer?.invalidate()
        TAPKit.log.event(.info, message: "connection timer stopped")
    }
    
    private func startConnectionTimer() -> Void {
        self.stopConnectionTimer()
        self.connectionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(connectionTimerTick(timer:)), userInfo: nil, repeats: true)
        TAPKit.log.event(.info, message: "connection timer started")
        self.connectionTimerTick(timer: nil)
    }
    
    @objc func connectionTimerTick(timer:Timer?) -> Void {
        
        let connectedPeripherals = self.centralManager.retrieveConnectedPeripherals(withServices: [TAPCBUUID.service__TAP])
        for peripheral in connectedPeripherals {
            if (self.isNewPeripheral(peripheral)) {
                self.pending.insert(peripheral)
                TAPKit.log.event(.info, message: "connecting to a new tap \(peripheral.identifier.uuidString), \(String.init(describing: peripheral.name))")
                self.centralManager.connect(peripheral, options: nil)
                
            }
        }
    }
    
    func getConnectedTaps() -> [String : String] {
        var res = [String:String]()
        self.taps.forEach({
            if $0.isReady {
                res[$0.identifier.uuidString] = $0.name
            }
            
        })
        return res
    }
    
    
    
    func read(identifier:String, characteristic:CBUUID) -> Void {
        if let handle = self.getTapHandle(identifier) {
            handle.read(characteristic)
        }
    }
    
    func write(identifier:String, characteristic:CBUUID, value:Data) -> Void {
        if let handle = self.getTapHandle(identifier) {
            handle.write(characteristic, value: value)
        }
    }
}

extension TAPCentral : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
            case .poweredOn : self.bluetoothIsOn()
            default : self.bluetoothIsOff()
        }
    
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.pending.remove(peripheral)
        TAPKit.log.event(.info, message: "central manager connected to \(peripheral.identifier), initializing tap...")
        let tap = TAPHandle(peripheral: peripheral, handleConfig: self.handleConfig, delegate: self)
        self.taps.insert(tap)
        tap.makeReady()
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            self.taps.remove(at: index)
        }
        TAPKit.log.event(.error, message: "central manager failed connecting to \(peripheral.identifier)")
        
//        self.delegatesController.tapFailedToConnect(withIdentifier: peripheral.identifier.uuidString, name: peripheral.name != nil ? peripheral.name! : "")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            TAPKit.log.event(.info, message: "disconnected \(peripheral.identifier)")
            self.delegate?.tapDisconnected?(identifier: peripheral.identifier.uuidString)
//            self.delegatesController.tapDisconnected(withIdentifier: self.taps[index].identifier.uuidString)
            self.taps.remove(at: index)
        }
    }
}

extension TAPCentral : TAPHandleDelegate {
    func TAPHandleIsReady(_ handle: TAPHandle) {
        self.delegate?.tapConnected?(identifier: handle.identifierString)
    }
    
    func TAPHandleDidUpdateCharacteristicValue(_ handle: TAPHandle, characteristic: CBUUID, value: Data) {
        self.delegate?.tapDidReadCharacteristicValue?(identifier: handle.identifierString, characteristic: characteristic, value: value)
    }
}

extension TAPCentral {
    // Public
    
    func start() -> Void {
        self.pending.removeAll()
        self.taps.removeAll()
        self.started = true
        if (self.isBluetoothOn) {
            self.startConnectionTimer()
//            self.startModeTimer()
        }
    }
}
