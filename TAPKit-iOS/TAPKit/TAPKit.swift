//
//  TAPKit.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth



open class TAPKit : NSObject {
    
    @objc public static let sharedKit = TAPKit.instance()
    private static var _instance : TAPKit? = nil
    
    @objc public static let log = TAPKitLog.sharedLog
    private var delegatesController : DelegatesController<TAPKitDelegate>
    private var central : TAPCentral!
    private var inputModeController : TAPInputModeController!
    private var airGestureController : TAPAirGestureController!
    private var tapxrStateController : TAPXRStateController!
    private var parsers : [CBUUID : [((String, CBUUID, Data)->Void)]] // CharacteristicUUID : (TapIdentifierUUID, CharacteristicUUID, Data)
    private var didWriteParsers : [CBUUID : [((String, CBUUID, Data?)->Void)]]
    private var modesEnabled : Bool
    
    open class func instance() -> TAPKit {
        if TAPKit._instance == nil {
            TAPKit._instance = TAPKit()
        }
        return TAPKit._instance!
    }
    
    public
    override init() {
        self.modesEnabled = true
        self.parsers = [CBUUID : [((String, CBUUID, Data)->Void)]]()
        self.didWriteParsers = [CBUUID : [((String, CBUUID, Data?)->Void)]]()
        self.delegatesController = DelegatesController<TAPKitDelegate>()
        self.airGestureController = TAPAirGestureController()
        self.tapxrStateController = TAPXRStateController()
        super.init()
        self.central = TAPCentral(handleInit: self.getHandleConfig(), handleValidator: self.getHandleValidator(), delegate: self)
        self.inputModeController = TAPInputModeController(interval: 10.0, delegate: self)
        self.tapxrStateController.delegate = self
        self.setupObservers()
        self.setupParsers()

    }
    
    
    
    open
    func getHandleValidator() -> TAPHandleValidator {
        return TAPHandleDefaultValidator()
    }
    
    open
    func setupParsers() -> Void {
        self.addParser(TAPCBUUID.characteristic__TAPData, parser: self.tapDataParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__MouseData, parser: self.tapMouseParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__TX, parser: self.tapRawSensorParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__AirGestures, parser: self.tapAirGestureParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__HW, parser: self.tapDeviceInformationParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__FW, parser: self.tapDeviceInformationParser(identifier:characteristic:data:))
    }
                           
    public func addParser(_ characteristic:CBUUID, parser: @escaping ((String, CBUUID, Data)->Void), replaceExistsing:Bool = false) {
        if self.parsers[characteristic] == nil {
            self.parsers[characteristic] = [((String, CBUUID, Data)->Void)]()
        }
        if let _ = self.parsers[characteristic] {
            if (replaceExistsing) {
                self.parsers[characteristic]?.removeAll()
            }
            self.parsers[characteristic]?.append(parser)
        }
    }
    
    public func addDidWriteParser(_ characteristic:CBUUID, parser: @escaping ((String, CBUUID, Data?)->Void), replaceExisiting:Bool = false) {
        if self.didWriteParsers[characteristic] == nil {
            self.didWriteParsers[characteristic] = [((String, CBUUID, Data?)->Void)]()
        }
        if let _ = self.didWriteParsers[characteristic] {
            if (replaceExisiting) {
                self.didWriteParsers[characteristic]?.removeAll()
            }
            self.didWriteParsers[characteristic]?.append(parser)
        }
    }
    
    
    
    private func setupObservers() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }

    
    open
    func getHandleConfig() -> TAPHandleConfig {
        let c = TAPHandleConfig()
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__TAPData, notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__MouseData, notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__AirGestures, notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__UICommands))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__RX))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__TX,notify: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__HW, readOnDiscover: true, storeLastReadValue: true))
        c.add(TAPHandleConfigCharacteristic(uuid: TAPCBUUID.characteristic__FW, readOnDiscover: true, storeLastReadValue: true))
        return c
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appDidBecomeActive notification")
        self.inputModeController.resume()
        self.tapxrStateController.resume()
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        
        TAPKit.log.event(.info, message: "appWillResignActive notification")
        self.inputModeController.pause(andSetMode: .text())
        self.tapxrStateController.pause(andSetState: .userControl())
        
    }
    
    private func parseCharacteristicValue(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        
        if let p = self.parsers[characteristic] {
            p.forEach({ parser in
                parser(identifier, characteristic, data)
            })
        }
    }
    
    private func parseDidWriteValue(identifier:String, characteristic:CBUUID, value:Data?) -> Void {
        if let p = self.didWriteParsers[characteristic] {
            p.forEach({ parser in
                parser(identifier, characteristic, value)
            })
        }
    }
    
    public func getStoredValue(identifier:String, characteristic:CBUUID) -> Data? {
        return self.central.getStoredValue(identifier: identifier, characteristic: characteristic)
    }
    
    public func actionWithIdentifiers(action:((String)->Void), identifiers:[String]?) {
        if let identifiers = identifiers {
            identifiers.forEach({ identifier in
                action(identifier)
            })
        } else {
            let taps = self.getConnectedTaps()
            taps.forEach({ uuid, _ in
                action(uuid)
            })
        }
    }
    
    public func read(identifier:String, characteristic:CBUUID) -> Void {
        self.central.read(identifier: identifier, characteristic: characteristic)
    }
    
    public func write(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        self.central.write(identifier: identifier, characteristic: characteristic, value: data)
    }
    
    public func isTapInAirGestureState(_ identifier:String) -> Bool {
        return self.airGestureController.isInState(uuid: identifier)
    }
    
    public func refreshModes() -> Void {
        self.inputModeController.refresh()
    }
    
    public func writeState(identifier:String) -> Void {
        if let state = self.tapxrStateController.get(identifier: identifier) {
            if let data = state.data() {
                self.central.write(identifier: identifier, characteristic: TAPCBUUID.characteristic__RX, value: data)
            }
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
                
                var keyboardState : (shiftState:UInt8, switchState:UInt8, multitap:UInt8)? = nil
                if let byte = DataConverter.toUInt8(data: data, index: 3) {
//                    let mTapDecoded = min(mTap+1,3)
                    keyboardState = (shiftState: byte & 0b00000011, switchState: (byte >> 2) & 0b00000011, multitap:  min(((byte >> 4) & 0b00000011)+1,3))
                }
                self.delegatesController.run(action: { d in
                    d.tapped?(identifier: identifier, combination: first, multitap: keyboardState?.multitap ?? 1)
                    d.tapped?(identifier: identifier, combination: first, multitap: keyboardState?.multitap ?? 1)
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
        if let mode = self.inputModeController.get(identifier: identifier) {
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
                    if hw >= 40000 {
                        self.tapxrStateController.add(identifier: identifier)
                    }
                    
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
    
    func tapConnected(identifier uuid:String, name:String) -> Void {
        TAPKit.log.event(.info, message: "tap \(uuid) connected and ready")
        self.inputModeController.add(uuid)
        self.delegatesController.run(action: { d in
            d.tapConnected?(withIdentifier: uuid, name: name)
        })
    }
    
    func tapDisconnected(identifier uuid:String) -> Void {
        self.inputModeController.remove(uuid)
        self.delegatesController.run(action: { d in
            d.tapDisconnected?(withIdentifier: uuid)
        })
    }
    
    func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data) {
        self.parseCharacteristicValue(identifier:uuid, characteristic:characteristic, data:value)
    }
    
    func tapDidWriteCharacteristicValue(identifier uuid: String, characteristic: CBUUID, value: Data?) {
        self.parseDidWriteValue(identifier: uuid, characteristic: characteristic, value: value)
    }
    
    
//    func tapDidWriteCharacteristicValue(identifier uuid: String, characteristic: CBUUID) {
//        self.parseDidWriteValue(identifier: uuid, characteristic: characteristic)
//    }
}
extension TAPKit : TAPXRStateControllerDelegate {
    func tapxrStateControllerUpdate(states: [String : TAPXRState]) {
        guard self.modesEnabled else { return }
        states.forEach({ uuid, state in
            if let data = state.data() {
                self.central.write(identifier: uuid, characteristic: TAPCBUUID.characteristic__RX, value: data)
            }
        })
    }
    
    
}

extension TAPKit : TAPInputModeControllerDelegate {
    open func TAPInputModeUpdate(modes: [String : TAPInputMode]) {
        guard self.modesEnabled else { return }
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
        self.inputModeController.start()
        self.tapxrStateController.start()
        self.airGestureController.reset()
        self.central.start()
        
        
    }
    
    @objc public func resume() -> Void {
        if !self.central.started {
            self.start()
        }
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
    
    @objc public func getTAPInputMode(identifier:String) -> TAPInputMode? {
        return self.inputModeController.get(identifier: identifier)
    }
    
    @objc public func getConnectedTaps() -> [String : String] {
        return self.central.getConnectedTaps()
//        return self.kitCentral.getConnectedTaps()
    }
    
    @objc public func vibrate(durations:Array<UInt16>, forIdentifiers identifiers:[String]? = nil) -> Void {
        if let data = TAPHaptic.toData(durations: durations) {
            self.actionWithIdentifiers(action: { uuid in
                self.central.write(identifier: uuid, characteristic: TAPCBUUID.characteristic__UICommands, value: data)
            }, identifiers: identifiers)
        }
    }
    
    @objc public func readHardwareVersion(forIdentifiers identifiers:[String]? = nil) -> Void {
        
        self.actionWithIdentifiers(action: { uuid in
            
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__HW)
        }, identifiers: identifiers)
    }
    
    @objc public func readFirmwareVersion(forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__FW)
        }, identifiers: identifiers)
    }
    
    @objc public func enableModes() -> Void {
        self.modesEnabled = true

    }
    
    @objc public func disableModes() -> Void {
        self.modesEnabled = false
    }
    
    @objc public func setTAPXRState(_ state:TAPXRState, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            self.tapxrStateController.set(state: state, for: uuid)
        }, identifiers: identifiers)
        
    }
    
    @objc public func setDefaultTAPXRState(_ state:TAPXRState, applyImmediate:Bool) -> Void {
        self.tapxrStateController.setDefault(state: state, applyImmediate: applyImmediate)
    }
}
