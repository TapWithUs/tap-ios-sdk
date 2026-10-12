//
//  TAPRawSensorSensitivity.swift
//  TAPKit
//
//  Created by Shahar Biran on 05/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

/// Finger-accelerometer range. Raw values are the 1-based bytes tap-python-sdk
/// sends (`FingerAcclSensitivity`: G2=1 ... G16=4). 0 is not a device setting.
@objc public enum TAPFingerAcclSensitivity: Int {
    case g2 = 1
    case g4 = 2
    case g8 = 3
    case g16 = 4

    /// Clamps an integer wire code into 1...4. 0 and anything below 1 become `.g2`.
    public static func normalizingWireValue(_ value: UInt8) -> UInt8 {
        let low = UInt8(TAPFingerAcclSensitivity.g2.rawValue)
        let high = UInt8(TAPFingerAcclSensitivity.g16.rawValue)
        if value < low {
            return low
        }
        if value > high {
            return high
        }
        return value
    }
}

/// Thumb-IMU gyroscope range. Raw values match tap-python-sdk `ImuGyroSensitivity`
/// (DPS125=1 ... DPS2000=5) and are what V2 `set_imu_sensitivity` writes.
@objc public enum TAPIMUGyroSensitivity: Int {
    case dps125 = 1
    case dps250 = 2
    case dps500 = 3
    case dps1000 = 4
    case dps2000 = 5

    /// Clamps an integer wire code into 1...5. 0 and anything below 1 become `.dps125`.
    public static func normalizingWireValue(_ value: UInt8) -> UInt8 {
        let low = UInt8(TAPIMUGyroSensitivity.dps125.rawValue)
        let high = UInt8(TAPIMUGyroSensitivity.dps2000.rawValue)
        if value < low {
            return low
        }
        if value > high {
            return high
        }
        return value
    }
}

/// Thumb-IMU accelerometer range. Raw values match tap-python-sdk `ImuAcclSensitivity`
/// (G2=1 ... G16=4).
@objc public enum TAPIMUAcclSensitivity: Int {
    case g2 = 1
    case g4 = 2
    case g8 = 3
    case g16 = 4

    /// Clamps an integer wire code into 1...4. 0 and anything below 1 become `.g2`.
    public static func normalizingWireValue(_ value: UInt8) -> UInt8 {
        let low = UInt8(TAPIMUAcclSensitivity.g2.rawValue)
        let high = UInt8(TAPIMUAcclSensitivity.g16.rawValue)
        if value < low {
            return low
        }
        if value > high {
            return high
        }
        return value
    }
}

/// Gyro and accelerometer ranges read back from a V2 device.
/// `gyroWireValue` / `accelerometerWireValue` are the same 1-based bytes Python returns.
public struct TAPIMUSensitivity {
    public let gyro: TAPIMUGyroSensitivity
    public let accelerometer: TAPIMUAcclSensitivity

    public var gyroWireValue: UInt8 {
        return UInt8(gyro.rawValue)
    }

    public var accelerometerWireValue: UInt8 {
        return UInt8(accelerometer.rawValue)
    }

    public init(gyro: TAPIMUGyroSensitivity, accelerometer: TAPIMUAcclSensitivity) {
        self.gyro = gyro
        self.accelerometer = accelerometer
    }

    public init?(gyroWireValue: UInt8, accelerometerWireValue: UInt8) {
        guard let gyro = TAPIMUGyroSensitivity(rawValue: Int(gyroWireValue)),
              let accelerometer = TAPIMUAcclSensitivity(rawValue: Int(accelerometerWireValue)) else {
            return nil
        }
        self.gyro = gyro
        self.accelerometer = accelerometer
    }
}

@objc public class TAPRawSensorSensitivity : NSObject {

    /// Scale applied to raw LSB counts. Index 0 is unused.
    /// Index == the 1-based wire value (same as the Python enum value).
    /// Finger and IMU accelerometer: mg/LSB. Gyro: mdps/LSB.
    /// Indexes 1+ keep the factors this SDK already used for those wire values.
    private static let sensitivityFactors : [String : [Double]] = [
        TAPRawSensorSensitivity.kDeviceAccelerometer : [0, 3.90625, 7.8125, 15.625, 31.25],
        TAPRawSensorSensitivity.kIMUAccelerometer : [0, 0.061, 0.122, 0.244, 0.488],
        TAPRawSensorSensitivity.kIMUGyro : [0, 4.375, 8.75, 17.5, 35, 70]
    ]

    /// 1-based finger-accelerometer code. 0 is stored as 1 (`.g2`).
    @objc public var deviceAccelerometer : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kDeviceAccelerometer] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kDeviceAccelerometer]!.default
        } set {
            params[TAPRawSensorSensitivity.kDeviceAccelerometer] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kDeviceAccelerometer)
        }
    }

    /// 1-based gyro code (`TAPIMUGyroSensitivity` raw value). 0 is stored as 1 (`.dps125`).
    @objc public var imuGyro : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kIMUGyro] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUGyro]!.default
        } set {
            params[TAPRawSensorSensitivity.kIMUGyro] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kIMUGyro)
        }
    }

    /// 1-based IMU-accelerometer code. 0 is stored as 1 (`.g2`).
    @objc public var imuAccelerometer : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kIMUAccelerometer] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUAccelerometer]!.default
        } set {
            params[TAPRawSensorSensitivity.kIMUAccelerometer] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kIMUAccelerometer)
        }
    }

    public static let kDeviceAccelerometer : String = "DeviceAccelerometer"
    public static let kIMUGyro : String = "IMUGyro"
    public static let kIMUAccelerometer : String = "IMUAccelerometer"

    private var params : [String:UInt8]!

    static let order : [String] = [TAPRawSensorSensitivity.kDeviceAccelerometer, TAPRawSensorSensitivity.kIMUGyro, TAPRawSensorSensitivity.kIMUAccelerometer]

    static let range : [String:(default:UInt8, low:UInt8, high:UInt8)] = [
        TAPRawSensorSensitivity.kDeviceAccelerometer: (
            default: TAPFingerAcclSensitivity.normalizingWireValue(0),
            low: TAPFingerAcclSensitivity.normalizingWireValue(0),
            high: UInt8(TAPFingerAcclSensitivity.g16.rawValue)
        ),
        TAPRawSensorSensitivity.kIMUAccelerometer: (
            default: TAPIMUAcclSensitivity.normalizingWireValue(0),
            low: TAPIMUAcclSensitivity.normalizingWireValue(0),
            high: UInt8(TAPIMUAcclSensitivity.g16.rawValue)
        ),
        TAPRawSensorSensitivity.kIMUGyro: (
            default: TAPIMUGyroSensitivity.normalizingWireValue(0),
            low: TAPIMUGyroSensitivity.normalizingWireValue(0),
            high: UInt8(TAPIMUGyroSensitivity.dps2000.rawValue)
        )
    ]

    /// Defaults match tap-python-sdk `InputModeRaw()`: finger G2, gyro DPS125, IMU accelerometer G2.
    /// The mode command bytes are `[1, 1, 1]`.
    @objc public override init() {
        self.params = [String:UInt8]()

        super.init()
        self.params[TAPRawSensorSensitivity.kDeviceAccelerometer] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kDeviceAccelerometer]!.default
        self.params[TAPRawSensorSensitivity.kIMUGyro] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUGyro]!.default
        self.params[TAPRawSensorSensitivity.kIMUAccelerometer] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUAccelerometer]!.default
    }

    /// `deviceAccelerometer`, `imuGyro`, and `imuAccelerometer` are 1-based wire codes
    /// (the same numbers as `TAPFingerAcclSensitivity` / `TAPIMUGyroSensitivity` / `TAPIMUAcclSensitivity`).
    /// 0 is not sent; it is stored as 1. Values above the max are clamped to the max.
    @objc public init(deviceAccelerometer:Int, imuGyro:Int, imuAccelerometer:Int) {
        self.params = [String:UInt8]()

        super.init()
        self.params[TAPRawSensorSensitivity.kDeviceAccelerometer] = normalizeSensitivityValue(UInt8(deviceAccelerometer), type: TAPRawSensorSensitivity.kDeviceAccelerometer)
        self.params[TAPRawSensorSensitivity.kIMUGyro] = normalizeSensitivityValue(UInt8(imuGyro), type: TAPRawSensorSensitivity.kIMUGyro)
        self.params[TAPRawSensorSensitivity.kIMUAccelerometer] = normalizeSensitivityValue(UInt8(imuAccelerometer), type: TAPRawSensorSensitivity.kIMUAccelerometer)
    }

    @objc public convenience init(finger: TAPFingerAcclSensitivity, gyro: TAPIMUGyroSensitivity, accelerometer: TAPIMUAcclSensitivity) {
        self.init(deviceAccelerometer: finger.rawValue, imuGyro: gyro.rawValue, imuAccelerometer: accelerometer.rawValue)
    }

    public static func title(rawSensorSensitivity:TAPRawSensorSensitivity?) -> String {
        var string = ""

        if let sens = rawSensorSensitivity {
            for i in 0..<TAPRawSensorSensitivity.order.count {
                let key = TAPRawSensorSensitivity.order[i]
                if let value = sens.params[key] {
                    string.append("\(key):\(sens.normalizeSensitivityValue(value, type:key)) ")
                } else {
                    string.append("\(key):\(TAPRawSensorSensitivity.range[key]!.default) ")
                }
            }
        } else {
            return title(rawSensorSensitivity: TAPRawSensorSensitivity())
        }
        return string
    }

    private func normalizeSensitivityValue(_ value:UInt8, type:String) -> UInt8 {
        if type == TAPRawSensorSensitivity.kDeviceAccelerometer {
            return TAPFingerAcclSensitivity.normalizingWireValue(value)
        }
        if type == TAPRawSensorSensitivity.kIMUGyro {
            return TAPIMUGyroSensitivity.normalizingWireValue(value)
        }
        if type == TAPRawSensorSensitivity.kIMUAccelerometer {
            return TAPIMUAcclSensitivity.normalizingWireValue(value)
        }
        return 1
    }

    /// `[finger, gyro, imuAccelerometer]`, each a 1-based wire code. Default is `[1, 1, 1]`.
    public func bytes() -> [UInt8] {
        var result = [UInt8]()
        for i in 0..<TAPRawSensorSensitivity.order.count {
            let key = TAPRawSensorSensitivity.order[i]
            if let value = self.params[key] {
                result.append(normalizeSensitivityValue(value, type:key))
            } else {
                result.append(TAPRawSensorSensitivity.range[key]!.default)
            }
        }
        return result
    }

    public func sensitivityFactor(for param:String ) -> Double? {
        if let factorArray = TAPRawSensorSensitivity.sensitivityFactors[param],
            let factorIndex = self.params[param] {
            if factorIndex == 0 {
                return nil
            }
            if factorArray.indices.contains(Int(factorIndex)) {
                return factorArray[Int(factorIndex)]
            }
        }
        return nil
    }

}
