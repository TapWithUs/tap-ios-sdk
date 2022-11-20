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
        self.central = TAPCentral(handleInit: self.getHandleConfig(), delegate: self)
        self.inputModeController = TAPInputModeController(interval: 10.0, delegate: self)
        self.setupObservers()
        self.setupParsers()
    }
    
    private func setupParsers() -> Void {
        self.addParser(TAPCBUUID.characteristic__TAPData, parser: self.tapDataParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__MouseData, parser: self.tapMouseParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__TX, parser: self.tapRawSensorParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__AirGestures, parser: self.tapAirGestureParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__HW, parser: self.tapDeviceInformationParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__FW, parser: self.tapDeviceInformationParser(identifier:characteristic:data:))
    }
                           
    private func addParser(_ characteristic:CBUUID, parser: @escaping ((String, CBUUID, Data)->Void)) {
        if self.parsers[characteristic] == nil {
            self.parsers[characteristic] = [((String, CBUUID, Data)->Void)]()
        }
        if let _ = self.parsers[characteristic] {
            self.parsers[characteristic]?.append(parser)
        }
    }
    
    private func setupObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }

    
    private func getHandleConfig() -> TAPHandleConfig {
        let c = TAPHandleConfig()
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__TAPData, notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__MouseData, notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__RX))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__TX))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__HW, readOnDiscover: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__FW, readOnDiscover: true))
        return c
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appDidBecomeActive notification")
        self.inputModeController.resume()
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appWillResignActive notification")
        self.inputModeController.pause(andSetMode: .text())
        
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
    
    private func tapDeviceInformationParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let str = DataConverter.toString(data) {
            switch characteristic {
            case TAPCBUUID.characteristic__HW :
                if let hw = VersionNumber.string2Int(str: str) {
                    self.delegatesController.run(action: { d in
                        d.tapDidReadHardwareVersion?(identifier: identifier, hw: hw)
                    })
                }
                break
            case TAPCBUUID.characteristic__FW :
                if let fw = VersionNumber.string2Int(str: str) {
                    self.delegatesController.run(action: { d in
                        d.tapDidReadFirmwareVersion?(identifier: identifier, fw: fw)
                    })
                }
                break
            default : break
            }
        }
    }
}


extension TAPKit : TAPCentralDelegate {
    func appDidBecomeActive() -> Void {
        self.inputModeController.start()
    }
    
    func appWillResignActive() -> Void {
        self.inputModeController.pause(andSetMode: .text())
    }
    
    func tapConnected(identifier uuid:String) -> Void {
        TAPKit.log.event(.info, message: "tap \(uuid) connected and ready")
        self.inputModeController.add(uuid)
    }
    
    func tapDisconnected(identifier uuid:String) -> Void {
        self.inputModeController.remove(uuid)
    }
    
    func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data) {
        
        self.parseCharacteristicValue(identifier:uuid, characteristic:characteristic, data:value)
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
        self.inputModeController.start()
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
    
    @objc public func vibrate(durations:Array<UInt16>, forIdentifiers identifiers:[String]? = nil) -> Void {
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
