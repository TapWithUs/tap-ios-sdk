//
//  TAPKit.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

public class TAPKit : NSObject {
    @objc public static let sharedKit = TAPKit()
    
    @objc public static let log = TAPKitLog.sharedLog
    private var delegatesController : DelegatesController<TAPKitDelegate>
    private var central : TAPCentral!
    private var inputModeController : TAPInputModeController!
    private var airGestureController : TAPAirGestureController!
    private var parsers : [CBUUID : [((String, CBUUID, Data)->Void)]] // CharacteristicUUID : (TapIdentifierUUID, CharacteristicUUID, Data)
    
    private override init() {
        self.parsers = [CBUUID : [((String, CBUUID, Data)->Void)]]()
        self.delegatesController = DelegatesController<TAPKitDelegate>()
        self.airGestureController = TAPAirGestureController()
        super.init()
        self.central = TAPCentral(handleInit: self.withTapHandleInit(), delegate: self)
        self.inputModeController = TAPInputModeController(interval: 10.0, delegate: self)
        self.setupObservers()
        self.setupParsers()
    }
    
    private func setupParsers() -> Void {
            
    }
                           
    private func addParser(_ characteristic:CBUUID, parser: @escaping ((Data)->Void)) {
        if let v = self.parsers[characteristic] {
            v.append(parser)
        }
    }
    
    private func setupObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }

    
    private func withTapHandleInit() -> TAPHandleInit {
        return TAPHandleInit(characteristics: [TAPHandleInitCharacteristic(uuid: TAPCBUUID.characteristic__HW)])
    }
    
    private func interpretCharacteristicValue(identifier:String, characteristic:CBUUID, value:Data) -> Void {
        
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appDidBecomeActive notification")
        self.inputModeController.pause(andSetMode: .text())
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appWillResignActive notification")
        self.inputModeController.resume()
    }
    
    private func parseCharacteristicValue(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let p = self.parsers[characteristic] {
            p.forEach({ parser in
                parser(identifier, characteristic, data)
            })
        }
    }
}

extension TAPKit {
    // Parsers
    private func tapDataParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let first = DataConverter.toUInt8(data: data, index: 0) {
            if self.airGestureController.isInState(uuid: identifier) {
                if let gesture = TAPAirGestureHelper.tapToAirGesture(first) {
                    self.delegatesController.run(action: { d in
                        d.tapAirGestured?(identifier: identifier, gesture: gesture)
                    })
                }
            } else {
                self.delegatesController.run(action: { d in
                    d.tapped?(identifier: identifier, combination: first)
                })
            }
        }
    }
    
    private func tapMouseParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let first = DataConverter.toUInt8(data: data, index: 0) {
            if first == 0 {
                if let vX = DataConverter.toInt16(data: data, index: 1), let vY = DataConverter.toInt16(data: data, index: 3), let mouse = DataConverter.toUInt8(data: data, index: 9) {
                    self.delegatesController.run(action: { d in
                        d.moused?(identifier: identifier, velocityX: vX, velocityY: vY, isMouse: mouse==1)
                    })
                }
            }
        }
        
    }
    
    private func tapRawSensorParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        let mode = self.inputModeController.get(identifier: identifier)
        if mode.type == TAPInputMode.kRawSensor {
            if let sensitivity = mode.sensitivity {
                RawSensorDataParser.parseWhole(data: data, sensitivity: sensitivity, onMessageReceived: { rawSensorData in
                    self.delegatesController.run(action: { d in
                        d.rawSensorDataReceived?(identifier: identifier, data: rawSensorData)
                    })
                })
            }
        }
    }
    
    private func tapAirGestureParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let first = DataConverter.toUInt8(data: data, index: 0) {
            if first == 20 {
                if let second = DataConverter.toUInt8(data: data, index: 1) {
                    self.airGestureController.setInState(uuid: identifier, inState: second == 1)
                    self.delegatesController.run(action: { d in
                        d.tapChangedAirGesturesState?(identifier: identifier, isInAirGesturesState: second == 1)
                    })
                }
            } else {
                if let gesture = TAPAirGesture(rawValue: Int(first)) {
                    self.delegatesController.run(action:  { d in
                        d.tapAirGestured?(identifier: identifier, gesture: gesture)
                    })
                }
            }
        }
    }
    
//    private func deviceInformationParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
//        switch characteristic {
//        case TAPCBUUID.characteristic__HW : VersionNumber.data2Int(data: data)
//        }
//    }
}


extension TAPKit : TAPCentralDelegate {
    func appDidBecomeActive() -> Void {
        self.inputModeController.start()
    }
    
    func appWillResignActive() -> Void {
        self.inputModeController.pause(andSetMode: .text())
    }
    
    func tapConnected(identifier uuid:String) -> Void {
        self.inputModeController.add(uuid)
    }
    
    func tapDisconnected(identifier uuid:String) -> Void {
        self.inputModeController.remove(uuid)
    }
    
    func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data) {
        self.parseCharacteristicValue(uuid, characteristic, value)
    }
}

extension TAPKit : TAPInputModeControllerDelegate {
    func TAPInputModeUpdate(modes: [String : TAPInputMode]) {
        modes.forEach({ uuid, mode in
            if let data = mode.data() {
                self.central.write(identifier: uuid, characteristic: TAPCBUUID.characteristic__RX, value: data)
            }
        })
    }
}

extension TAPKit {
    // public interface
    
    @objc public func start() -> Void {
        self.inputModeController.reset()
        self.airGestureController.reset()
        self.central.start()
    }
    
    @objc public func addDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.delegatesController.add(delegate)
    }
    
    @objc public func removeDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.delegatesController.remove(delegate)
    }
    
    @objc public func setDefaultTAPInputMode(_ defaultMode:TAPInputMode, immediate:Bool) -> Void {
        self.inputModeController.set(defaultInputMode: defaultMode, immediate: immediate)
        
    }
    
    @objc public func setTAPInputMode(_ newMode:TAPInputMode, forIdentifiers identifiers : [String]? = nil) -> Void {
        self.inputModeController.set(inputMode: newMode,identifiers: identifiers)
    }
    
    @objc public func getConnectedTaps() -> [String : String] {
        return self.central.getConnectedTaps()
//        return self.kitCentral.getConnectedTaps()
    }
    
    @objc public func haptic(durations:Array<UInt16>, forIdentifiers identifiers:[String]? = nil) -> Void {
        if let data = TAPHaptic.toData(durations: durations) {
            if let identifiers = identifiers {
                identifiers.forEach( { uuid in
                    self.central.write(identifier: uuid, characteristic: TAPCBUUID.characteristic__UICommands, value: data)
                })
            } else {
                let taps = self.getConnectedTaps()
                taps.forEach({ uuid, _ in
                    self.central.write(identifier: uuid, characteristic: TAPCBUUID.characteristic__UICommands, value: data)
                })
            }
        }
    }
}
