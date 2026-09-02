//
//  TAPV2Parser.swift
//  TAPKit
//
//  Port of tap-python-sdk parsers.py
//

import Foundation

enum TAPV2IncCommandType: UInt8 {
    case imuData = 0
    case modelDetection = 1
    case standbyState = 2
    case configState = 3
}

enum TAPV2IncSubCommandType1: UInt8 {
    case imuMotionData = 0
    case imuRawData = 1
    case tapGesture = 2
    case airGesture = 3
}

/// Sub-command 1 values for incoming config-state responses (cmd = configState).
enum TAPV2IncConfigStateSubCommandType1: UInt8 {
    case feature = 0
    case visionOpMode = 1
    case visionModel = 2
    case imuSensitivity = 3
    case hapticPattern = 4
}

enum TAPV2IncomingMessageType {
    case imuMotion(Data)
    case imuRaw(Data)
    case tapGesture(Data)
    case airGesture(Data)
    case standbyState(Bool)
    case configFeature(featureNumber: UInt8, enabled: Bool)
    case configVisionOpMode(UInt8)
    case configVisionModel(UInt8)
    case configIMUSensitivity(gyro: UInt8, xl: UInt8)
    case configHapticPattern(Data)
}

class TAPV2Parser {
    /// Appended as the last byte on V2 air-gesture payloads mapped to legacy AirGestures.
    static let airGestureV2Marker: UInt8 = 0xFF
    
    private static let payloadStartIndex = 4
    private static let imuRawMessageTypeValue: UInt32 = 1 << 31
    
    static func isV2AirGesturePayload(_ data: Data) -> Bool {
        guard let last = data.last else { return false }
        return last == airGestureV2Marker
    }
    
    static func legacyAirGesturePayload(fromV2Payload payload: Data) -> Data {
        let gestureBytes = [UInt8](payload)
        var buffer = Data(count: 4)
        if gestureBytes.indices.contains(0) {
            buffer[0] = gestureBytes[0]
        }
        if gestureBytes.indices.contains(3) {
            buffer[3] = gestureBytes[3]
        } else if gestureBytes.indices.contains(1) {
            buffer[3] = gestureBytes[1]
        }
        buffer.append(airGestureV2Marker)
        return buffer
    }
    
    static func parseIncomingMessage(_ data: Data) -> TAPV2IncomingMessageType? {
        let bytes = [UInt8](data)
        guard bytes.count >= payloadStartIndex else { return nil }
        
        let cmdType = bytes[0]
        let subCmdType = bytes[1]
        let payload = Data(bytes[payloadStartIndex...])
        
        switch cmdType {
        case TAPV2IncCommandType.imuData.rawValue:
            switch subCmdType {
            case TAPV2IncSubCommandType1.imuMotionData.rawValue:
                return .imuMotion(payload)
            case TAPV2IncSubCommandType1.imuRawData.rawValue:
                return .imuRaw(payload)
            default:
                return nil
            }
        case TAPV2IncCommandType.modelDetection.rawValue:
            switch subCmdType {
            case TAPV2IncSubCommandType1.tapGesture.rawValue:
                return .tapGesture(payload)
            case TAPV2IncSubCommandType1.airGesture.rawValue:
                return .airGesture(payload)
            default:
                return nil
            }
        case TAPV2IncCommandType.standbyState.rawValue:
            let standbyBytes = [UInt8](payload)
            return .standbyState(standbyBytes.first == 1)
        case TAPV2IncCommandType.configState.rawValue:
            return parseConfigStateMessage(subCmdType: subCmdType, payload: payload)
        default:
            return nil
        }
    }
    
    private static func parseConfigStateMessage(subCmdType: UInt8, payload: Data) -> TAPV2IncomingMessageType? {
        let payloadBytes = [UInt8](payload)
        switch subCmdType {
        case TAPV2IncConfigStateSubCommandType1.feature.rawValue:
            guard payloadBytes.count >= 2 else { return nil }
            return .configFeature(featureNumber: payloadBytes[0], enabled: payloadBytes[1] == 1)
        case TAPV2IncConfigStateSubCommandType1.visionOpMode.rawValue:
            guard let first = payloadBytes.first else { return nil }
            return .configVisionOpMode(first)
        case TAPV2IncConfigStateSubCommandType1.visionModel.rawValue:
            guard let first = payloadBytes.first else { return nil }
            return .configVisionModel(first)
        case TAPV2IncConfigStateSubCommandType1.imuSensitivity.rawValue:
            guard payloadBytes.count >= 2 else { return nil }
            return .configIMUSensitivity(gyro: payloadBytes[0], xl: payloadBytes[1])
        case TAPV2IncConfigStateSubCommandType1.hapticPattern.rawValue:
            return .configHapticPattern(payload)
        default:
            return nil
        }
    }
    
    /// True for messages that are not mapped to legacy characteristics
    /// (standby + config-state responses); these are routed to TAPKit on the V2Read UUID.
    static func isConfigOrStandbyMessage(_ message: TAPV2IncomingMessageType) -> Bool {
        switch message {
        case .standbyState, .configFeature, .configVisionOpMode, .configVisionModel, .configIMUSensitivity, .configHapticPattern:
            return true
        default:
            return false
        }
    }
    
    static func mapToLegacyMessages(_ message: TAPV2IncomingMessageType) -> [TAPProtocolParsedMessage] {
        switch message {
        case .imuMotion(let payload):
            return [TAPProtocolParsedMessage(characteristic: TAPCBUUID.characteristic__MouseData, payload: payload)]
        case .imuRaw(let payload):
            return [TAPProtocolParsedMessage(characteristic: TAPCBUUID.characteristic__TX, payload: payload)]
        case .tapGesture(let payload):
            var buffer = Data(count: 4)
            let tapBytes = [UInt8](payload)
            if let first = tapBytes.first {
                buffer[0] = first
            }
            return [TAPProtocolParsedMessage(characteristic: TAPCBUUID.characteristic__TAPData, payload: buffer)]
        case .airGesture(let payload):
            return [TAPProtocolParsedMessage(
                characteristic: TAPCBUUID.characteristic__AirGestures,
                payload: legacyAirGesturePayload(fromV2Payload: payload)
            )]
        case .standbyState, .configFeature, .configVisionOpMode, .configVisionModel, .configIMUSensitivity, .configHapticPattern:
            return []
        }
    }
}

#if DEBUG
enum TAPV2CodecTests {
    static func runAll() {
        testSetFeatureEncoding()
        testTapGestureParsing()
        testKeepaliveEncoding()
    }
    
    static func testSetFeatureEncoding() {
        let encoded = TAPV2Encoder.encodeSetFeature(feature: .modelDetection, enable: true)
        assert(encoded[0] == TAPV2OutCommandType.setFeature.rawValue)
        assert(encoded[4] == UInt8(TAPV2DeviceFeature.modelDetection.rawValue))
        assert(encoded[5] == 1)
    }
    
    static func testTapGestureParsing() {
        let frame: [UInt8] = [1, 2, 0, 0, 5]
        let parsed = TAPV2Parser.parseIncomingMessage(Data(frame))
        guard case .tapGesture(let payload)? = parsed else {
            assertionFailure("Expected tap gesture")
            return
        }
        let mapped = TAPV2Parser.mapToLegacyMessages(.tapGesture(payload))
        assert(mapped.first?.characteristic == TAPCBUUID.characteristic__TAPData)
        assert(mapped.first?.payload[0] == 5)
    }
    
    static func testKeepaliveEncoding() {
        let encoded = TAPV2Encoder.encodeKeepaliveMessage()
        assert(encoded[0] == TAPV2OutCommandType.keepaliveCommand.rawValue)
        assert(encoded.count == 4)
    }
}
#endif
