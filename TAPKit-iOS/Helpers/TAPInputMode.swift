//
//  TAPMode.swift
//  TAPKit
//
//  Created by Shahar Biran on 26/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class TAPRawSensorSensitivity : NSObject {
    
    @objc public var accelerometer : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kAccelerometer] ?? TAPRawSensorSensitivity.range.default
        } set {
            params[TAPRawSensorSensitivity.kAccelerometer] = normalizeSensitivityValue(newValue)
        }
    }
    
    @objc public var gyro : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kGyro] ?? TAPRawSensorSensitivity.range.default
        } set {
            params[TAPRawSensorSensitivity.kGyro] = normalizeSensitivityValue(newValue)
        }
    }
    
    
    @objc public var imu : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kIMU] ?? TAPRawSensorSensitivity.range.default
        } set {
            params[TAPRawSensorSensitivity.kIMU] = normalizeSensitivityValue(newValue)
        }
    }
    
    private static let kAccelerometer : String = "accelerometer"
    private static let kGyro : String = "gyro"
    private static let kIMU : String = "imu"
    
    private var params : [String:UInt8]!
    
    static let order : [String] = [TAPRawSensorSensitivity.kAccelerometer, TAPRawSensorSensitivity.kGyro, TAPRawSensorSensitivity.kIMU]
    
    static let range = (default:UInt8(0), low:UInt8(1), high:UInt8(4))

    public override init() {
        self.params = [String:UInt8]()
        
        super.init()
        self.params[TAPRawSensorSensitivity.kAccelerometer] = TAPRawSensorSensitivity.range.default
        self.params[TAPRawSensorSensitivity.kGyro] = TAPRawSensorSensitivity.range.default
        self.params[TAPRawSensorSensitivity.kIMU] = TAPRawSensorSensitivity.range.default
    }
    
    public init(accelerometer:UInt8? = nil, gyro:UInt8? = nil, imu:UInt8? = nil) {
        self.params = [String:UInt8]()
        
        super.init()
        self.params[TAPRawSensorSensitivity.kAccelerometer] = accelerometer != nil ? normalizeSensitivityValue(accelerometer!) : TAPRawSensorSensitivity.range.default
        self.params[TAPRawSensorSensitivity.kGyro] =  gyro != nil ? normalizeSensitivityValue(gyro!) : TAPRawSensorSensitivity.range.default
        self.params[TAPRawSensorSensitivity.kIMU] = imu  != nil ? normalizeSensitivityValue(imu!) : TAPRawSensorSensitivity.range.default
    }
    
    public static func title(rawSensorSensitivity:TAPRawSensorSensitivity?) -> String {
        var string = ""
        
        if let sens = rawSensorSensitivity {
            for i in 0..<TAPRawSensorSensitivity.order.count {
                let key = TAPRawSensorSensitivity.order[i]
                if string != "" {
                    string.append("; ")
                }
                if let value = sens.params[key] {
                    string.append("\(key):\(sens.normalizeSensitivityValue(value))")
                } else {
                    string.append("\(key):\(TAPRawSensorSensitivity.range.default)")
                }
            }
        } else {
            return title(rawSensorSensitivity: TAPRawSensorSensitivity())
        }
        return string
    }
    
    private func normalizeSensitivityValue(_ value:UInt8) -> UInt8 {
        return value <= TAPRawSensorSensitivity.range.high ? (value >= TAPRawSensorSensitivity.range.low ? value : TAPRawSensorSensitivity.range.default) : TAPRawSensorSensitivity.range.default
    }
    
    public func bytes() -> [UInt8] {
        var result = [UInt8]()
        for i in 0..<TAPRawSensorSensitivity.order.count {
            let key = TAPRawSensorSensitivity.order[i]
            if let value = self.params[key] {
                result.append(normalizeSensitivityValue(value))
            } else {
                result.append(TAPRawSensorSensitivity.range.default)
            }
        }
        return result
    }
}

@objc public class TAPInputMode : NSObject {

    @objc public static let kController : String = "Controller"
    @objc public static let kText : String = "Text"
    @objc public static let kRawSensor : String = "RawSensor"
    
    private static let modeByte : [String:UInt8] = [TAPInputMode.kController : 0x1, TAPInputMode.kText : 0x0, TAPInputMode.kRawSensor : 0xa]
    
    public var sensitivity : TAPRawSensorSensitivity?
    public let type:String
    
    private init(type:String, sensitivity:TAPRawSensorSensitivity? = nil) {
        self.type = type
        self.sensitivity = sensitivity
        super.init()
    }
    
    static func modeWhenDisabled() -> TAPInputMode {
        return TAPInputMode(type: kText)
    }
    
    static func defaultMode() -> TAPInputMode {
        return TAPInputMode(type: kController)
    }
    
    @objc public static func controller() -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kController)
    }
    
    @objc public static func text() -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kText)
    }
    
    @objc public static func rawSensor(sensitivity:TAPRawSensorSensitivity) -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kRawSensor, sensitivity: sensitivity)
    }

    func data() -> Data? {
        guard let modeValue = TAPInputMode.modeByte[self.type] else {
            return nil
        }
        
        var sensitivityArray = [UInt8]()
        
        if self.type == TAPInputMode.kRawSensor {
            if let sens = self.sensitivity {
                sensitivityArray = sens.bytes()
            } else {
                return nil
            }
        }
        let bytes : [UInt8] = [0x3,0xc,0x0,modeValue] + sensitivityArray
        let d = Data.init(bytes: bytes)
        return d
    }
    
    func title() -> String {
        if self.type != TAPInputMode.kRawSensor {
            return self.type
        } else {
            return "Raw Sensor Mode (with) Sensitivities: \(TAPRawSensorSensitivity.title(rawSensorSensitivity: self.sensitivity))"
        }
    }
}
