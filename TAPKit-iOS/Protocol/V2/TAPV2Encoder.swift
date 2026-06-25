//
//  TAPV2Encoder.swift
//  TAPKit
//
//  Port of tap-python-sdk encoder.py
//

import Foundation

enum TAPV2OutCommandType: UInt8 {
    case setFeature = 0
    case peripheralCommand = 1
    case keepaliveCommand = 2
    case standbyStateCommand = 3
}

enum TAPV2OutSubCommandType1: UInt8 {
    case peripheralTypeVisionSensor = 0
    case peripheralTypeIMU = 1
    case peripheralTypeHaptic = 2
    case standbyStateGet = 3
    case standbyStateSet = 4
}

enum TAPV2OutSubCommandType2: UInt8 {
    case setVisualSensorOpMode = 0
    case setVisualSensorModel = 1
    case setIMUSensitivity = 2
    case setHapticPattern = 3
}

enum TAPV2DeviceFeature: UInt8 {
    case rawIMUData = 0
    case modelDetection = 1
    case imuMotionData = 2
}

enum TAPV2VisionSensorOpMode: UInt8 {
    case trigger = 0
    case streamOnTrigger = 1
    case stream = 2
}

enum TAPV2VisionSensorModel: UInt8 {
    case tapping = 0
    case airGesture = 1
}

class TAPV2Encoder {
    private static let metadataSize = 4
    private static let payloadFeatureNumberIndex = 0
    private static let payloadFeatureValueIndex = 1
    
    static func encodeMessage(cmd: UInt8, subcmd1: UInt8, subcmd2: UInt8, subcmd3: UInt8, payload: [UInt8]) -> Data {
        var msg = [UInt8](repeating: 0, count: metadataSize + payload.count)
        msg[0] = cmd
        msg[1] = subcmd1
        msg[2] = subcmd2
        msg[3] = subcmd3
        for (index, byte) in payload.enumerated() {
            msg[metadataSize + index] = byte
        }
        return Data(msg)
    }
    
    static func encodeSetFeature(feature: TAPV2DeviceFeature, enable: Bool) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.setFeature.rawValue,
            subcmd1: 0,
            subcmd2: 0,
            subcmd3: 0,
            payload: [feature.rawValue, enable ? 1 : 0]
        )
    }
    
    static func encodeSetVisionSensorOpMode(_ mode: TAPV2VisionSensorOpMode) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setVisualSensorOpMode.rawValue,
            subcmd3: 0,
            payload: [mode.rawValue]
        )
    }
    
    static func encodeSetVisionSensorModel(_ model: TAPV2VisionSensorModel) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setVisualSensorModel.rawValue,
            subcmd3: 0,
            payload: [model.rawValue]
        )
    }
    
    static func encodeSetIMUSensitivity(gyro: UInt8, xl: UInt8) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeIMU.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setIMUSensitivity.rawValue,
            subcmd3: 0,
            payload: [gyro, xl]
        )
    }
    
    static func encodeSetHapticPattern(_ sequence: [UInt8]) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeHaptic.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setHapticPattern.rawValue,
            subcmd3: 0,
            payload: sequence
        )
    }
    
    static func encodeKeepaliveMessage() -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.keepaliveCommand.rawValue,
            subcmd1: 0,
            subcmd2: 0,
            subcmd3: 0,
            payload: []
        )
    }
    
    static func encodeStandbyStateSet(_ standby: Bool) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.standbyStateCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.standbyStateSet.rawValue,
            subcmd2: 0,
            subcmd3: 0,
            payload: [standby ? 1 : 0]
        )
    }
}
