//
//  TAPV2ProtocolAdapter.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

class TAPV2ProtocolAdapter: TAPProtocolAdapter {
    let protocolVersion: TAPDeviceProtocol = .v2
    
    func characteristicInstructions() -> [CBUUID: TAPHandleConfigCharacteristic] {
        var instructions = [CBUUID: TAPHandleConfigCharacteristic]()
        instructions[TAPCBUUID.characteristic__V2Read] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__V2Read,
            notify: true
        )
        instructions[TAPCBUUID.characteristic__V2Write] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__V2Write
        )
        instructions[TAPCBUUID.characteristic__SerialNumber] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__SerialNumber,
            readOnDiscover: true,
            storeLastReadValue: true
        )
        return instructions
    }
    
    func parseNotification(_ data: Data) -> [TAPProtocolParsedMessage] {
        guard let message = TAPV2Parser.parseIncomingMessage(data) else { return [] }
        return TAPV2Parser.mapToLegacyMessages(message)
    }
    
    func encodeInputMode(_ mode: TAPInputMode, xrState: TAPXRState?) -> [TAPProtocolWrite] {
        return TAPV2InputModeMapper.commands(for: mode, xrState: xrState).map {
            TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__V2Write, data: $0)
        }
    }
    
    func encodeXRState(_ state: TAPXRState, inputMode: TAPInputMode?) -> [TAPProtocolWrite] {
        guard state.type != TAPXRState.kDontSend else { return [] }
        let mode = inputMode ?? TAPInputMode.controller()
        return TAPV2InputModeMapper.commands(for: mode, xrState: state).map {
            TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__V2Write, data: $0)
        }
    }
    
    func encodeHaptic(durations: [UInt16]) -> [TAPProtocolWrite] {
        guard !durations.isEmpty else { return [] }
        var sequence = [UInt8](repeating: 0, count: 18 /*min(18, durations.count)*/)
        for index in 0..<min(sequence.count,durations.count) {
            let scaled = Int(durations[index] / 10)
            sequence[index] = UInt8(max(0, min(255, scaled)))
        }
        let hapticPayload: [UInt8] = [0x0, 0x2] + sequence
        let encoded = TAPV2Encoder.encodeSetHapticPattern(hapticPayload)
        return [TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__V2Write, data: encoded)]
    }
    
    func encodeKeepalive() -> [TAPProtocolWrite] {
        return [TAPProtocolWrite(
            characteristic: TAPCBUUID.characteristic__V2Write,
            data: TAPV2Encoder.encodeKeepaliveMessage()
        )]
    }
    
    func supports(_ feature: TAPDeviceFeature) -> Bool {
        switch feature {
        case .battery, .hardwareVersion, .firmwareVersion:
            return true
        case .serialNumber:
            return true
        }
    }
}
