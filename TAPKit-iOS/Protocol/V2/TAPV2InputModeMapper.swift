//
//  TAPV2InputModeMapper.swift
//  TAPKit
//

import Foundation

class TAPV2InputModeMapper {
    
    /// Builds the full V2 command sequence from scratch using both input mode and XR state.
    static func commands(for mode: TAPInputMode, xrState: TAPXRState?) -> [Data] {
        switch mode.type {
        case TAPInputMode.kText:
            return textModeCommands()
        case TAPInputMode.kRawSensor:
            return rawSensorModeCommands(mode: mode)
        case TAPInputMode.kV2Debug:
            return v2DebugModeCommands(mode: mode)
        case TAPInputMode.kTapHold:
            return tapHoldModeCommands()
        default:
            return controllerModeCommands(xrState: xrState)
        }
    }
    
    private static func defaultFeatureCommands() -> [Data] {
        return [
            TAPV2Encoder.encodeSetFeature(feature: .modelDetection, enable: true),
            TAPV2Encoder.encodeSetFeature(feature: .imuMotionData, enable: true),
            TAPV2Encoder.encodeSetFeature(feature: .rawIMUData, enable: false),
        ]
    }
    
    private static func textModeCommands() -> [Data] {
        return [
            TAPV2Encoder.encodeSetFeature(feature: .modelDetection, enable: false),
            TAPV2Encoder.encodeSetFeature(feature: .imuMotionData, enable: false),
            TAPV2Encoder.encodeSetFeature(feature: .rawIMUData, enable: false),
        ]
    }
    
    private static func rawSensorModeCommands(mode: TAPInputMode) -> [Data] {
        var commands = [
            TAPV2Encoder.encodeSetFeature(feature: .rawIMUData, enable: true),
            TAPV2Encoder.encodeSetFeature(feature: .modelDetection, enable: false),
            TAPV2Encoder.encodeSetFeature(feature: .imuMotionData, enable: false),
        ]
        if let sensitivity = mode.sensitivity {
            commands.append(TAPV2Encoder.encodeSetIMUSensitivity(
                gyro: mapGyroSensitivity(sensitivity.imuGyro),
                xl: mapXLSensitivity(sensitivity.imuAccelerometer)
            ))
        }
        return commands
    }
    
    private static func v2DebugModeCommands(mode: TAPInputMode) -> [Data] {
        var commands = [
            TAPV2Encoder.encodeSetFeature(feature: .rawIMUData, enable: true),
            TAPV2Encoder.encodeSetFeature(feature: .modelDetection, enable: true),
            TAPV2Encoder.encodeSetFeature(feature: .imuMotionData, enable: true),
            TAPV2Encoder.encodeSetVisionSensorModel(.airGesture),
            TAPV2Encoder.encodeSetVisionSensorOpMode(.stream),
        ]
        let sensitivity = mode.sensitivity ?? TAPRawSensorSensitivity()
        commands.append(TAPV2Encoder.encodeSetIMUSensitivity(
            gyro: mapGyroSensitivity(sensitivity.imuGyro),
            xl: mapXLSensitivity(sensitivity.imuAccelerometer)
        ))
        return commands
    }
    
    private static func tapHoldModeCommands() -> [Data] {
        var commands = defaultFeatureCommands()
        commands.append(TAPV2Encoder.encodeSetVisionSensorModel(.tapping))
        commands.append(TAPV2Encoder.encodeSetVisionSensorOpMode(.stream))
        return commands
    }
    
    private static func controllerModeCommands(xrState: TAPXRState?) -> [Data] {
        var commands = defaultFeatureCommands()
        
        guard let xrState = xrState, xrState.type != TAPXRState.kDontSend else {
            return commands
        }
        
        switch xrState.type {
        case TAPXRState.kAirMouse:
            commands.append(TAPV2Encoder.encodeSetVisionSensorModel(.airGesture))
            commands.append(TAPV2Encoder.encodeSetVisionSensorOpMode(.stream))
        case TAPXRState.kTapping:
            commands.append(TAPV2Encoder.encodeSetVisionSensorModel(.tapping))
            commands.append(TAPV2Encoder.encodeSetVisionSensorOpMode(.trigger))
        default:
            break
        }
        
        return commands
    }
    
    private static func mapGyroSensitivity(_ value: UInt8) -> UInt8 {
        return min(max(value, 0), 5)
    }
    
    private static func mapXLSensitivity(_ value: UInt8) -> UInt8 {
        return min(max(value, 0), 4)
    }
}
