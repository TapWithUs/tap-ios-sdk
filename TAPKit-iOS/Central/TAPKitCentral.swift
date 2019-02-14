//
//  TAPKitCentral.swift
//  TAPKit-iOS
//
//  Created by Shahar Biran on 21/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

class TAPKitCentral : NSObject {
    
    private var centralManager : CBCentralManager!
    private var pending : Set<CBPeripheral>!
    private var taps : Set<TAPDevice>!
    private var started : Bool!
    private var isBluetoothOn : Bool!
    
    private var delegatesController : TAPKitDelegatesController!
    private var connectionTimer : Timer?
    private var modeTimer : Timer?
    private var defaultInputMode : String!
    private var appActive : Bool = true
    
    override init() {
        super.init()
        self.defaultInputMode = ""
        self.delegatesController = TAPKitDelegatesController()
        self.isBluetoothOn = false
        self.pending = Set<CBPeripheral>()
        self.taps = Set<TAPDevice>()
        self.setupObservers()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.started = false
        self.centralManagerDidUpdateState(self.centralManager)
    }
    
    private func setupObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        self.appActive = true
        TAPKit.log.event(.info, message: "appDidBecomeActive notification")
        self.taps.forEach({
            $0.enableMode()
        })
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        self.appActive = false
        TAPKit.log.event(.info, message: "appWillResignActive notification")
        self.taps.forEach({
            $0.disableMode()
        })
    }
    
    @objc func appWillTerminate(notification:NSNotification) -> Void {
        TAPKit.log.event(.info, message: "appWillTerminate notification")
        self.taps.forEach({
            $0.disableMode()
        })
    }
    
    
    deinit {
        self.stopConnectionTimer()
        self.stopModeTimer()
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
    
    private func startModeTimer() -> Void {
        self.stopModeTimer()
        self.modeTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(modeTimerTick(timer:)), userInfo: nil, repeats: true)
        TAPKit.log.event(.info, message: "mode timer started")
        self.modeTimerTick(timer: nil)
    }
    
    private func stopModeTimer() -> Void {
        self.modeTimer?.invalidate()
        TAPKit.log.event(.info, message: "mode timer stopped")
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
    
    private func tapIndex(_ peripheral:CBPeripheral) -> Set<TAPDevice>.Index? {
        return self.taps.index(where: { $0.identifier == peripheral.identifier})
    }
    
    private func isNewPeripheral(_ peripheral:CBPeripheral) -> Bool {
        return !self.isPending(peripheral) && !self.isConnected(peripheral)
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
    
    @objc func modeTimerTick(timer:Timer?) -> Void {
        self.taps.forEach({ $0.writeMode()})
    }
}

extension TAPKitCentral : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn : self.bluetoothIsOn()
        default : self.bluetoothIsOff()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.pending.remove(peripheral)
        TAPKit.log.event(.info, message: "central manager connected to \(peripheral.identifier), initializing tap...")
        let tap = TAPDevice(peripheral: peripheral, delegate: self)
        self.taps.insert(tap)
        tap.makeReady()
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            self.taps.remove(at: index)
        }
        TAPKit.log.event(.error, message: "central manager failed connecting to \(peripheral.identifier)")
        self.delegatesController.tapFailedToConnect(withIdentifier: peripheral.identifier.uuidString, name: peripheral.name != nil ? peripheral.name! : "")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.pending.remove(peripheral)
        if let index = self.tapIndex(peripheral) {
            TAPKit.log.event(.info, message: "disconnected \(peripheral.identifier)")
            self.delegatesController.tapDisconnected(withIdentifier: self.taps[index].identifier.uuidString)
            self.taps.remove(at: index)
        }
    }
}

extension TAPKitCentral : TAPDeviceDelegate {
    func TAPIsReady(identifier: String, name: String) {
        if let index = self.taps.index(where: { $0.identifier.uuidString == identifier }) {
            if self.appActive {
                self.taps[index].setNewMode(self.defaultInputMode)
                self.taps[index].writeMode()
            }
        }
        self.delegatesController.tapConnected(withIdentifier: identifier, name: name)
    }
    
    func TAPtapped(identifier: String, combination: UInt8) {
        self.delegatesController.tapped(identifier: identifier, combination: combination)
    }
    
    func TAPFailed(identifier: String, name: String) {
        self.delegatesController.tapFailedToConnect(withIdentifier: identifier, name: name)
        if let index = self.taps.index(where: { $0.identifier.uuidString == identifier}) {
            self.taps.remove(at: index)
        }
    }
    
    func TAPMoused(identifier: String, vX: Int16, vY: Int16) {
        self.delegatesController.moused(identifier: identifier, velocityX: vX, velocityY: vY)
    }
    
}

extension TAPKitCentral {
    // Public
    func start() -> Void {
        self.pending.removeAll()
        self.taps.removeAll()
        self.started = true
        if (self.isBluetoothOn) {
            self.startConnectionTimer()
            self.startModeTimer()
        }
    }
    
    func add(delegate:TAPKitDelegate) -> Void {
        self.delegatesController.add(delegate)
    }
    
    func remove(delegate:TAPKitDelegate) -> Void {
        self.delegatesController.remove(delegate)
    }
    
    func setDefaultInputMode(_ mode:String, immediate:Bool) -> Void {
        self.defaultInputMode = mode
        if immediate {
            self.taps.forEach({
                $0.setNewMode(mode)
            })
        }
    }
    
    func setTAPInputMode(_ newMode:String, forIdentifiers identifiers : [String]?) -> Void {
        if let ids = identifiers {
            ids.forEach({ identifier in
                if let index = self.taps.index(where: { tapdevice in
                    tapdevice.identifier.uuidString == identifier
                }) {
                    self.taps[index].setNewMode(newMode)
                }
            })
        } else {
            self.taps.forEach({
                $0.setNewMode(newMode)
            })
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
    
    func getTAPInputMode(forTapIdentifier identifier:String) -> String? {
        if let index = self.taps.index(where: { $0.identifier.uuidString == identifier }) {
            return self.taps[index].mode
        }
        return nil
    }
    
    func vibrate(identifier:UUID? = nil, durations:Array<UInt16>) -> Void {
        if let iden = identifier {
            if let tap = self.taps.filter({ $0.identifier == iden}).first {
                tap.vibrate(durations: durations)
            }
        } else {
            self.taps.forEach({
                $0.vibrate(durations:durations)
            })
        }

    }
    
    func vibrate(identifier:UUID? = nil, durationMS:UInt16) -> Void {
        if let iden = identifier {
            if let tap = self.taps.filter({ $0.identifier == iden}).first {
                tap.vibrate(withDuration: durationMS)
            }
        } else {
            self.taps.forEach({
                $0.vibrate(withDuration: durationMS)
            })
        }
    }
}

