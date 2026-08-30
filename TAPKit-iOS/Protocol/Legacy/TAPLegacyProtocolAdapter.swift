//
//  TAPLegacyProtocolAdapter.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

class TAPLegacyProtocolAdapter: TAPProtocolAdapter {
    let protocolVersion: TAPDeviceProtocol = .legacy
    
    func characteristicInstructions() -> [CBUUID: TAPHandleConfigCharacteristic] {
        var instructions = [CBUUID: TAPHandleConfigCharacteristic]()
        instructions[TAPCBUUID.characteristic__TAPData] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__TAPData,
            notify: true
        )
        instructions[TAPCBUUID.characteristic__MouseData] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__MouseData,
            notify: true
        )
        instructions[TAPCBUUID.characteristic__AirGestures] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__AirGestures,
            notify: true
        )
        instructions[TAPCBUUID.characteristic__UICommands] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__UICommands
        )
        instructions[TAPCBUUID.characteristic__RX] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__RX
        )
        instructions[TAPCBUUID.characteristic__TX] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__TX,
            notify: true
        )
        instructions[TAPCBUUID.characteristic__HW] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__HW,
            readOnDiscover: true,
            storeLastReadValue: true
        )
        instructions[TAPCBUUID.characteristic__FW] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__FW,
            readOnDiscover: true,
            storeLastReadValue: true
        )
        instructions[TAPCBUUID.characteristic__BatteryLevel] = TAPHandleConfigCharacteristic(
            uuid: TAPCBUUID.characteristic__BatteryLevel,
            readOnDiscover: true,
            storeLastReadValue: true
        )
        return instructions
    }
    
    func parseNotification(_ data: Data) -> [TAPProtocolParsedMessage] {
        return []
    }
    
    func encodeInputMode(_ mode: TAPInputMode, xrState: TAPXRState?) -> [TAPProtocolWrite] {
        guard let modeData = mode.data() else { return [] }
        return [TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__RX, data: modeData)]
    }
    
    func encodeXRState(_ state: TAPXRState, inputMode: TAPInputMode?) -> [TAPProtocolWrite] {
        guard let stateData = state.data() else { return [] }
        return [TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__RX, data: stateData)]
    }
    
    func encodeHaptic(durations: [UInt16]) -> [TAPProtocolWrite] {
        guard let data = TAPHaptic.toData(durations: durations) else { return [] }
        return [TAPProtocolWrite(characteristic: TAPCBUUID.characteristic__UICommands, data: data)]
    }
    
    func encodeKeepalive() -> [TAPProtocolWrite] {
        return []
    }
    
    func supports(_ feature: TAPDeviceFeature) -> Bool {
        switch feature {
        case .battery, .hardwareVersion, .firmwareVersion:
            return true
        case .serialNumber:
            return false
        }
    }
}
