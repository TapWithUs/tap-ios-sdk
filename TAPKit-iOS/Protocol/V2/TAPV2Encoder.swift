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

/// Sub-command 1 values for feature commands (cmd = setFeature).
enum TAPV2FeatureSubCommand: UInt8 {
    case set = 0
    case get = 1
}

enum TAPV2OutSubCommandType2: UInt8 {
    case setVisualSensorOpMode = 0
    case setVisualSensorModel = 1
    case setIMUSensitivity = 2
    case setHapticPattern = 3
    case getVisualSensorOpMode = 10
    case getVisualSensorModel = 11
    case getIMUSensitivity = 12
}

/// Device features togglable on V2 devices (parity with tap-python-sdk DeviceFeatures).
@objc public enum TAPV2DeviceFeature: Int {
    case rawIMUData = 0
    case modelDetection = 1
    case imuMotionData = 2
    case triggerDetections = 3
    case standbyGestureDetection = 4
}

/// Vision sensor operation modes (parity with tap-python-sdk VisionSensorOpModes).
@objc public enum TAPV2VisionSensorOpMode: Int {
    case trigger = 0
    case streamOnTrigger = 1
    case stream = 2
}

/// Vision sensor detection models (parity with tap-python-sdk ModelTypes).
@objc public enum TAPV2VisionSensorModel: Int {
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
            subcmd1: TAPV2FeatureSubCommand.set.rawValue,
            subcmd2: 0,
            subcmd3: 0,
            payload: [UInt8(feature.rawValue), enable ? 1 : 0]
        )
    }
    
    static func encodeGetFeature(feature: TAPV2DeviceFeature) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.setFeature.rawValue,
            subcmd1: TAPV2FeatureSubCommand.get.rawValue,
            subcmd2: 0,
            subcmd3: 0,
            payload: [UInt8(feature.rawValue)]
        )
    }
    
    static func encodeSetVisionSensorOpMode(_ mode: TAPV2VisionSensorOpMode) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setVisualSensorOpMode.rawValue,
            subcmd3: 0,
            payload: [UInt8(mode.rawValue)]
        )
    }
    
    static func encodeGetVisionSensorOpMode() -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.getVisualSensorOpMode.rawValue,
            subcmd3: 0,
            payload: []
        )
    }
    
    static func encodeSetVisionSensorModel(_ model: TAPV2VisionSensorModel) -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.setVisualSensorModel.rawValue,
            subcmd3: 0,
            payload: [UInt8(model.rawValue)]
        )
    }
    
    static func encodeGetVisionSensorModel() -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeVisionSensor.rawValue,
            subcmd2: TAPV2OutSubCommandType2.getVisualSensorModel.rawValue,
            subcmd3: 0,
            payload: []
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
    
    static func encodeGetIMUSensitivity() -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.peripheralCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.peripheralTypeIMU.rawValue,
            subcmd2: TAPV2OutSubCommandType2.getIMUSensitivity.rawValue,
            subcmd3: 0,
            payload: []
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
    
    static func encodeStandbyStateGet() -> Data {
        return encodeMessage(
            cmd: TAPV2OutCommandType.standbyStateCommand.rawValue,
            subcmd1: TAPV2OutSubCommandType1.standbyStateGet.rawValue,
            subcmd2: 0,
            subcmd3: 0,
            payload: []
        )
    }
}
