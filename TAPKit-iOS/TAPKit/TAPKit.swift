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

    private let tapSwipe : TapSwipe
    
    @objc public static let log = TAPKitLog.sharedLog
    private var delegatesController : DelegatesController<TAPKitDelegate>
    private var central : TAPCentral!
    private var inputModeController : TAPInputModeController!
    private var airGestureController : TAPAirGestureController!
    private var tapxrStateController : TAPXRStateController!
    private var tapxrGesturesMain : [String : XRGesturesMain]
    private var parsers : [CBUUID : [((String, CBUUID, Data)->Void)]] // CharacteristicUUID : (TapIdentifierUUID, CharacteristicUUID, Data)
    private var didWriteParsers : [CBUUID : [((String, CBUUID, Data?)->Void)]]
    private var modesEnabled : Bool
    private var tapHoldController :TapHoldController
    private var gesturePost : GesturePostprocessor
    public var sendModeInBackground : Bool
    
    private var modesTimer : Timer?
    private var v2KeepaliveTimer : Timer?
    private static let v2KeepaliveInterval : TimeInterval = 20.0
    
    /// Default timeout for V2 config "get" requests (parity with tap-python-sdk DEFAULT_GET_TIMEOUT_SEC).
    public static let v2ConfigGetTimeout : TimeInterval = 2.0
    private var v2PendingRequests : [String : (Any?) -> Void]
    private var v2PendingRequestTimeouts : [String : DispatchWorkItem]
    
    open class func instance() -> TAPKit {
        if TAPKit._instance == nil {
            TAPKit._instance = TAPKit()
        }
        return TAPKit._instance!
    }
    
    
    public
    override init() {
        self.modesEnabled = true
        self.gesturePost = GesturePostprocessor(holdDebounce: true, aggregatedDoubles: false)
        self.tapSwipe = TapSwipe()
        self.parsers = [CBUUID : [((String, CBUUID, Data)->Void)]]()
        self.didWriteParsers = [CBUUID : [((String, CBUUID, Data?)->Void)]]()
        self.delegatesController = DelegatesController<TAPKitDelegate>()
        self.airGestureController = TAPAirGestureController()
        self.tapxrStateController = TAPXRStateController()
        self.sendModeInBackground = false
        self.tapHoldController = TapHoldController()
        self.tapxrGesturesMain = [String : XRGesturesMain]()
        self.v2PendingRequests = [String : (Any?) -> Void]()
        self.v2PendingRequestTimeouts = [String : DispatchWorkItem]()
        super.init()
        self.central = TAPCentral(handleInit: self.getHandleConfig(), handleValidator: self.getHandleValidator(), delegate: self)
        self.inputModeController = TAPInputModeController(interval: 10.0, delegate: self)
        self.tapxrStateController.delegate = self
        self.tapHoldController.delegate = self
        self.setupObservers()
        self.setupParsers()

    }
    
    
    
    open func getHandleValidator() -> TAPHandleValidator {
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
        self.addParser(TAPCBUUID.characteristic__BatteryLevel, parser: self.batteryLevelDataParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__V2Read, parser: self.tapV2ConfigParser(identifier:characteristic:data:))
        self.addParser(TAPCBUUID.characteristic__SerialNumber, parser: self.tapSerialNumberParser(identifier:characteristic:data:))
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
        return TAPHandleConfig.unionDiscoveryConfig()
    }
    
    @objc func appDidBecomeActive(notification:NSNotification) -> Void {
        TAPKit.log.event(.info, message: "appDidBecomeActive notification. sendModeInBackground = \(self.sendModeInBackground)")
        if (!self.sendModeInBackground) {
            self.inputModeController.resume()
            self.tapxrStateController.resume(withDelay: 3.0)
        }
        self.startV2KeepaliveTimer()
    }
    
    @objc func appWillResignActive(notification:NSNotification) -> Void {
        TAPKit.log.event(.info, message: "appWillResignActive notification. sendModeInBackground = \(self.sendModeInBackground)")
        self.stopV2KeepaliveTimer()
        if (!self.sendModeInBackground) {
            self.inputModeController.pause(andSetMode: .text())
            self.tapxrStateController.pause(andSetState: .userControl())
        }
    }
    
    private func ensureXRGesturesMain(identifier: String) {
        if self.tapxrGesturesMain[identifier] == nil {
            self.tapxrGesturesMain[identifier] = XRGesturesMain()
            self.tapxrGesturesMain[identifier]?.onXRAirGestured = { [weak self] gesture in
                self?.delegatesController.run(action: { d in
                    d.tapXRAirGestured?(identifier: identifier, gesture: gesture)
                })
            }
        }
    }
    
    private func xrGestured(identifier: String, gesture:Int) {
        self.ensureXRGesturesMain(identifier: identifier)
        self.tapxrGesturesMain[identifier]?.onGestureState(gesture: gesture)
    }
    
    private func parseCharacteristicValue(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        DispatchQueue.main.async {
            if let p = self.parsers[characteristic] {
                p.forEach({ parser in
                    parser(identifier, characteristic, data)
                })
            }
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
        guard let adapter = self.central.getProtocolAdapter(identifier) else { return }
        if let state = self.tapxrStateController.get(identifier: identifier) {
            self.central.writeThroughAdapter(identifier: identifier, writes: adapter.encodeXRState(state, inputMode: self.inputModeController.get(identifier: identifier)))
        }
    }
    
    func modeUpdate(identifier:String) {
        guard self.modesEnabled else { return }
        guard let adapter = self.central.getProtocolAdapter(identifier) else { return }
        let mode = self.inputModeController.get(identifier: identifier)
        let state = self.tapxrStateController.get(identifier: identifier)
        
        if adapter.protocolVersion == .v2 {
            if let mode = mode {
                self.central.writeThroughAdapter(
                    identifier: identifier,
                    writes: adapter.encodeInputMode(mode, xrState: state)
                )
            }
        } else {
            if let state = state {
                self.central.writeThroughAdapter(
                    identifier: identifier,
                    writes: adapter.encodeXRState(state, inputMode: mode)
                )
            }
            if let mode = mode {
                self.central.writeThroughAdapter(
                    identifier: identifier,
                    writes: adapter.encodeInputMode(mode, xrState: state)
                )
            }
        }
    }
    
    func modesUpdate() -> Void {
        guard self.modesEnabled else { return }
        self.getConnectedTaps().forEach({ identifier, _ in
            guard let adapter = self.central.getProtocolAdapter(identifier),
                  adapter.protocolVersion != .v2 else {
                return
            }
            self.modeUpdate(identifier: identifier)
        })
    }
    
    func sendV2Keepalive() -> Void {
        self.getConnectedTaps().forEach({ identifier, _ in
            if let adapter = self.central.getProtocolAdapter(identifier),
               adapter.protocolVersion == .v2 {
                self.central.writeThroughAdapter(identifier: identifier, writes: adapter.encodeKeepalive())
            }
        })
    }
    
    func startV2KeepaliveTimer() -> Void {
        guard self.central.started else { return }
        self.stopV2KeepaliveTimer()
        self.sendV2Keepalive()
        self.v2KeepaliveTimer = Timer.scheduledTimer(withTimeInterval: TAPKit.v2KeepaliveInterval, repeats: true, block: { _ in
            self.sendV2Keepalive()
        })
    }
    
    func stopV2KeepaliveTimer() -> Void {
        self.v2KeepaliveTimer?.invalidate()
        self.v2KeepaliveTimer = nil
    }
    
    func startModesTimer() -> Void {
        self.modesTimer?.invalidate()
        self.modesTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { t in
            self.modesUpdate()
        })
        
    }
    
    func stopModesTimer() -> Void {
        self.modesTimer?.invalidate()
    }
    
}

extension TAPKit {
    // Parsers
    
    private func batteryLevelDataParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let first = ([UInt8](data)).first {
            self.delegatesController.run(action: { d in
                d.tapDidReadBatteryLevel?(identifier: identifier, batteryLevel: Int(first))
            })
        }
    }
    
    private func tapDataParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let first = DataConverter.toUInt8(data: data, index: 0) {
            let use_tap_hold = (self.inputModeController.get(identifier: identifier) ?? .defaultMode()).type == TAPInputMode.kTapHold
            
            if (use_tap_hold) {
                self.tapHoldController.tapped(identifier: identifier, combination: first)
            } else {
                if self.airGestureController.isInState(uuid: identifier) {
                    if let gesture = TAPAirGestureHelper.tapToAirGesture(first) {
                        self.delegatesController.run(action: { d in
                            d.tapAirGestured?(identifier: identifier, gesture: gesture)
                        })
                    }
                } else {
                    
                    var keyboardState : (shiftState:UInt8, switchState:UInt8, multitap:UInt8)? = nil
                    if let byte = DataConverter.toUInt8(data: data, index: 3) {
                        keyboardState = (shiftState: byte & 0b00000011, switchState: (byte >> 2) & 0b00000011, multitap:  min(((byte >> 4) & 0b00000011)+1,3))
                    }
                    self.delegatesController.run(action: { d in
                        d.tapped?(identifier: identifier, combination: first, multitap: keyboardState?.multitap ?? 1)
                    })
                }
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
                    if mouse == 1 {
                        self.ensureXRGesturesMain(identifier: identifier)
                        self.tapxrGesturesMain[identifier]?.onMouse(vx: Int(vX), vy: Int(vY))
                    }
                }
                if let roll = DataConverter.toInt16(data: data, index: 10), let pitch = DataConverter.toInt16(data: data, index: 12), let yaw = DataConverter.toInt16(data: data, index: 14) {
                    self.delegatesController.run(action: {
                        d in d.tapDidChangeOrientation?(roll: Int(roll), pitch: Int(pitch), yaw: Int(yaw))
                    })
                }
            }
        }
    }
    
    private func tapRawSensorParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let mode = self.inputModeController.get(identifier: identifier) {
            if mode.type == TAPInputMode.kRawSensor || mode.type == TAPInputMode.kV2Debug {
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
        var didSwipe : Bool = false
        let isV2AirGesture = TAPV2Parser.isV2AirGesturePayload(data)

        if (isV2AirGesture) {
            if let first = DataConverter.toUInt8(data: data, index: 0) {
                let (post, previousPost) = self.gesturePost.call(Int(first))

                if let c = GesturePostprocessor.ToTapXRV2AirGesture(post),
                   let p = GesturePostprocessor.ToTapXRV2AirGesture(previousPost) {
                    let gestures = TAPXRV2AirGestureConverter.convert(current: c, previous: p)
                    gestures.forEach { gesture in
                        self.delegatesController.run(action: { d in
                            d.tapXRAirGestured?(identifier: identifier, gesture: gesture)
                        })
                    }
                }
                
            }
        } else {
            if let swipe = DataConverter.toUInt8(data: data, index: 3) {
                if swipe != 0 {
                    if self.tapSwipe.swipe(identifier: identifier) {
                        self.delegatesController.run(action: { d in
                            var g : TAPXRAirGesture? = nil
                            switch swipe {
                            case 1 :
                                g = .SwipeLeft
                            case 2 :
                                g = .SwipeRight
                            case 3 :
                                g = .SwipeUp
                            case 4:
                                g = .SwipeDown
                            default : break
                            }
                            if let g {
                                d.tapXRAirGestured?(identifier: identifier, gesture: g)
                            }
                        })
                        
                        didSwipe = true
                    }
                }
            }
            guard !didSwipe else { return }
                
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
                        if TAPAirGestureHelper.isXRGesture(gesture) {
                            self.xrGestured(identifier: identifier, gesture: gesture.rawValue)
                        } else {
                            self.delegatesController.run(action:  { d in
                                d.tapAirGestured?(identifier: identifier, gesture: gesture)
                            })
                        }
                    }
                }
            }

        }
    }
    
    private func tapV2ConfigParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        guard let message = TAPV2Parser.parseIncomingMessage(data) else { return }
        switch message {
        case .standbyState(let isInStandby):
            self.resolveV2Request(identifier: identifier, kind: "standbyState", value: isInStandby)
            self.delegatesController.run(action: { d in
                d.tapChangedStandbyState?(identifier: identifier, isInStandby: isInStandby)
            })
        case .configFeature(let featureNumber, let enabled):
            self.resolveV2Request(identifier: identifier, kind: "feature_\(featureNumber)", value: enabled)
        case .configVisionOpMode(let value):
            self.resolveV2Request(identifier: identifier, kind: "visionOpMode", value: value)
        case .configVisionModel(let value):
            self.resolveV2Request(identifier: identifier, kind: "visionModel", value: value)
        case .configIMUSensitivity(let gyro, let xl):
            self.resolveV2Request(identifier: identifier, kind: "imuSensitivity", value: (gyro, xl))
        default:
            break
        }
    }
    
    private func tapSerialNumberParser(identifier:String, characteristic:CBUUID, data:Data) -> Void {
        if let serialNumber = DataConverter.toString(data) {
            self.delegatesController.run(action: { d in
                d.tapDidReadSerialNumber?(identifier: identifier, serialNumber: serialNumber)
            })
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
    func tapConnected(identifier uuid:String, name:String) -> Void {
        TAPKit.log.event(.info, message: "tap \(uuid) connected and ready")
        if self.central.getProtocolAdapter(uuid)?.protocolVersion == .v2 {
            self.tapxrStateController.add(identifier: uuid)
        }
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
    
    func tapFailedToConnect(identifier uuid:String, name:String) -> Void {
        self.delegatesController.run(action: { d in
            d.tapFailedToConnect?(withIdentifier: uuid, name: name)
        })
    }
    
    func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data) {
        self.parseCharacteristicValue(identifier:uuid, characteristic:characteristic, data:value)
    }
    
    func tapDidWriteCharacteristicValue(identifier uuid: String, characteristic: CBUUID, value: Data?) {
        self.parseDidWriteValue(identifier: uuid, characteristic: characteristic, value: value)
    }
}
extension TAPKit : TAPXRStateControllerDelegate {
    func tapxrStateControllerUpdate(states: [String : TAPXRState]) {
        guard self.modesEnabled else { return }
        states.forEach({ uuid, state in
            self.modeUpdate(identifier: uuid)
        })
    }
}

extension TAPKit : TAPInputModeControllerDelegate {
    open func TAPInputModeUpdate(modes: [String : TAPInputMode]) {
        guard self.modesEnabled else { return }
        modes.forEach({ uuid, mode in
            self.modeUpdate(identifier: uuid)
        })
    }
}

extension TAPKit {
    // public interface
    
    @objc public func start() -> Void {
        self.inputModeController.start()
        self.tapxrStateController.start(withDelay: 3.0)
        self.airGestureController.reset()
        self.central.start()
        self.startModesTimer()
        self.startV2KeepaliveTimer()
        
        
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
    }
    
    @objc public func vibrate(durations:Array<UInt16>, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            if let adapter = self.central.getProtocolAdapter(uuid) {
                self.central.writeThroughAdapter(identifier: uuid, writes: adapter.encodeHaptic(durations: durations))
            }
        }, identifiers: identifiers)
    }
    
    @objc public func readBatteryLevel(forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            guard let adapter = self.central.getProtocolAdapter(uuid), adapter.supports(.battery) else { return }
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__BatteryLevel)
        }, identifiers: identifiers)
    }
    
    @objc public func readHardwareVersion(forIdentifiers identifiers:[String]? = nil) -> Void {
        
        self.actionWithIdentifiers(action: { uuid in
            guard let adapter = self.central.getProtocolAdapter(uuid), adapter.supports(.hardwareVersion) else { return }
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__HW)
        }, identifiers: identifiers)
    }
    
    @objc public func readFirmwareVersion(forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            guard let adapter = self.central.getProtocolAdapter(uuid), adapter.supports(.firmwareVersion) else { return }
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__FW)
        }, identifiers: identifiers)
    }
    
    @objc public func enableModes() -> Void {
        TAPKit.log.event(.info, message: "enableModes")
        self.modesEnabled = true
    }
    
    @objc public func disableModes() -> Void {
        TAPKit.log.event(.info, message: "disableModes")
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

extension TAPKit {
    // V2 config request/response plumbing (parity with tap-python-sdk TapSDK2 pending requests).
    // All access happens on the main queue: parsers are dispatched to main, and the
    // public get functions hop to main before registering.
    
    private func v2RequestKey(identifier:String, kind:String) -> String {
        return "\(identifier)|\(kind)"
    }
    
    fileprivate func registerV2Request(identifier:String, kind:String, timeout:TimeInterval, completion: @escaping (Any?) -> Void) {
        let key = self.v2RequestKey(identifier: identifier, kind: kind)
        if let previous = self.v2PendingRequests.removeValue(forKey: key) {
            self.v2PendingRequestTimeouts.removeValue(forKey: key)?.cancel()
            previous(nil)
        }
        self.v2PendingRequests[key] = completion
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let pending = self.v2PendingRequests.removeValue(forKey: key) {
                self.v2PendingRequestTimeouts.removeValue(forKey: key)
                TAPKit.log.event(.warning, message: "V2 config get (\(kind)) timed out for tap \(identifier)")
                pending(nil)
            }
        }
        self.v2PendingRequestTimeouts[key] = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
    }
    
    fileprivate func resolveV2Request(identifier:String, kind:String, value:Any?) {
        let key = self.v2RequestKey(identifier: identifier, kind: kind)
        guard let completion = self.v2PendingRequests.removeValue(forKey: key) else { return }
        self.v2PendingRequestTimeouts.removeValue(forKey: key)?.cancel()
        completion(value)
    }
    
    fileprivate func v2Adapter(for identifier:String) -> TAPProtocolAdapter? {
        guard let adapter = self.central.getProtocolAdapter(identifier), adapter.protocolVersion == .v2 else {
            TAPKit.log.event(.warning, message: "tap \(identifier) does not use the V2 protocol; V2 command ignored")
            return nil
        }
        return adapter
    }
    
    fileprivate func writeV2Command(identifier:String, data:Data) {
        guard self.v2Adapter(for: identifier) != nil else { return }
        self.central.write(identifier: identifier, characteristic: TAPCBUUID.characteristic__V2Write, value: data)
    }
    
    fileprivate func v2Get(identifier:String, kind:String, request:Data, timeout:TimeInterval, completion: @escaping (Any?) -> Void) {
        DispatchQueue.main.async {
            guard self.v2Adapter(for: identifier) != nil else {
                completion(nil)
                return
            }
            self.registerV2Request(identifier: identifier, kind: kind, timeout: timeout, completion: completion)
            self.central.write(identifier: identifier, characteristic: TAPCBUUID.characteristic__V2Write, value: request)
        }
    }
}

extension TAPKit {
    // Public interface: V2 device configuration (parity with tap-python-sdk TapSDK2).
    // These commands apply to V2 devices only; they are ignored (with a warning log)
    // for legacy devices.
    
    /// Enables or disables a single V2 device feature (raw IMU, model detection,
    /// IMU motion, trigger detections, standby gesture detection).
    @objc public func setFeature(_ feature:TAPV2DeviceFeature, enabled:Bool, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            self.writeV2Command(identifier: uuid, data: TAPV2Encoder.encodeSetFeature(feature: feature, enable: enabled))
        }, identifiers: identifiers)
    }
    
    /// Reads back the current enabled state of a V2 device feature.
    /// Calls completion with nil on timeout or if the device is not a V2 device.
    public func getFeature(_ feature:TAPV2DeviceFeature, forIdentifier identifier:String, timeout:TimeInterval = TAPKit.v2ConfigGetTimeout, completion: @escaping (Bool?) -> Void) {
        self.v2Get(identifier: identifier,
                   kind: "feature_\(feature.rawValue)",
                   request: TAPV2Encoder.encodeGetFeature(feature: feature),
                   timeout: timeout,
                   completion: { value in completion(value as? Bool) })
    }
    
    /// Sets the vision sensor operation mode (trigger / streamOnTrigger / stream).
    @objc public func setVisionSensorOpMode(_ mode:TAPV2VisionSensorOpMode, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            self.writeV2Command(identifier: uuid, data: TAPV2Encoder.encodeSetVisionSensorOpMode(mode))
        }, identifiers: identifiers)
    }
    
    /// Reads back the current vision sensor operation mode.
    public func getVisionSensorOpMode(forIdentifier identifier:String, timeout:TimeInterval = TAPKit.v2ConfigGetTimeout, completion: @escaping (TAPV2VisionSensorOpMode?) -> Void) {
        self.v2Get(identifier: identifier,
                   kind: "visionOpMode",
                   request: TAPV2Encoder.encodeGetVisionSensorOpMode(),
                   timeout: timeout,
                   completion: { value in
                        guard let raw = value as? UInt8 else { completion(nil); return }
                        completion(TAPV2VisionSensorOpMode(rawValue: Int(raw)))
                   })
    }
    
    /// Sets the vision sensor detection model (tapping / airGesture).
    @objc public func setVisionSensorModel(_ model:TAPV2VisionSensorModel, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            self.writeV2Command(identifier: uuid, data: TAPV2Encoder.encodeSetVisionSensorModel(model))
        }, identifiers: identifiers)
    }
    
    /// Reads back the current vision sensor detection model.
    public func getVisionSensorModel(forIdentifier identifier:String, timeout:TimeInterval = TAPKit.v2ConfigGetTimeout, completion: @escaping (TAPV2VisionSensorModel?) -> Void) {
        self.v2Get(identifier: identifier,
                   kind: "visionModel",
                   request: TAPV2Encoder.encodeGetVisionSensorModel(),
                   timeout: timeout,
                   completion: { value in
                        guard let raw = value as? UInt8 else { completion(nil); return }
                        completion(TAPV2VisionSensorModel(rawValue: Int(raw)))
                   })
    }
    
    /// Sets the IMU sensitivity directly (without changing the input mode).
    /// gyro range: 0-5, accelerometer range: 0-4 (see TAPRawSensorSensitivity).
    @objc public func setIMUSensitivity(gyro:UInt8, accelerometer:UInt8, forIdentifiers identifiers:[String]? = nil) -> Void {
        let clampedGyro = min(gyro, 5)
        let clampedXL = min(accelerometer, 4)
        self.actionWithIdentifiers(action: { uuid in
            self.writeV2Command(identifier: uuid, data: TAPV2Encoder.encodeSetIMUSensitivity(gyro: clampedGyro, xl: clampedXL))
        }, identifiers: identifiers)
    }
    
    /// Reads back the current IMU sensitivity as (gyro, accelerometer).
    public func getIMUSensitivity(forIdentifier identifier:String, timeout:TimeInterval = TAPKit.v2ConfigGetTimeout, completion: @escaping ((gyro:UInt8, accelerometer:UInt8)?) -> Void) {
        self.v2Get(identifier: identifier,
                   kind: "imuSensitivity",
                   request: TAPV2Encoder.encodeGetIMUSensitivity(),
                   timeout: timeout,
                   completion: { value in
                        guard let sensitivity = value as? (UInt8, UInt8) else { completion(nil); return }
                        completion((gyro: sensitivity.0, accelerometer: sensitivity.1))
                   })
    }
    
    /// Puts the device in or out of standby state.
    @objc public func setStandbyState(_ standby:Bool, forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            self.writeV2Command(identifier: uuid, data: TAPV2Encoder.encodeStandbyStateSet(standby))
        }, identifiers: identifiers)
    }
    
    /// Reads back the current standby state.
    /// Unsolicited standby changes are also delivered via the
    /// tapChangedStandbyState(identifier:isInStandby:) delegate callback.
    public func getStandbyState(forIdentifier identifier:String, timeout:TimeInterval = TAPKit.v2ConfigGetTimeout, completion: @escaping (Bool?) -> Void) {
        self.v2Get(identifier: identifier,
                   kind: "standbyState",
                   request: TAPV2Encoder.encodeStandbyStateGet(),
                   timeout: timeout,
                   completion: { value in completion(value as? Bool) })
    }
    
    /// Returns the serial number stored from the on-connect read (V2 devices), if available.
    @objc public func getSerialNumber(identifier:String) -> String? {
        guard let data = self.getStoredValue(identifier: identifier, characteristic: TAPCBUUID.characteristic__SerialNumber) else { return nil }
        return DataConverter.toString(data)
    }
    
    /// Triggers a serial number read; the result is delivered via the
    /// tapDidReadSerialNumber(identifier:serialNumber:) delegate callback.
    @objc public func readSerialNumber(forIdentifiers identifiers:[String]? = nil) -> Void {
        self.actionWithIdentifiers(action: { uuid in
            guard let adapter = self.central.getProtocolAdapter(uuid), adapter.supports(.serialNumber) else { return }
            self.read(identifier: uuid, characteristic: TAPCBUUID.characteristic__SerialNumber)
        }, identifiers: identifiers)
    }
}

extension TAPKit : TapHoldControllerDelegate {
    func tapHoldSingleTap(identifier: String, combination: UInt8) {
        self.delegatesController.run(action: { d in d.tapped?(identifier: identifier, combination: combination, multitap: 1)})
    }
    
    func tapHoldStarted(identifier: String, combination: UInt8) {
        self.delegatesController.run(action: { d in d.tapHoldStarted?(identifier: identifier, combination: combination)})
    }
    
    func tapHoldEnded(identifier: String, combination: UInt8) {
        self.delegatesController.run(action: { d in d.tapHoldEnded?(identifier: identifier, combination:  combination)})
    }
    
    
}
