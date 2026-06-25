//
//  TAPProtocolAdapter.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

public protocol TAPProtocolAdapter: AnyObject {
    var protocolVersion: TAPDeviceProtocol { get }
    
    func characteristicInstructions() -> [CBUUID: TAPHandleConfigCharacteristic]
    func parseNotification(_ data: Data) -> [TAPProtocolParsedMessage]
    func encodeInputMode(_ mode: TAPInputMode, xrState: TAPXRState?) -> [TAPProtocolWrite]
    func encodeXRState(_ state: TAPXRState, inputMode: TAPInputMode?) -> [TAPProtocolWrite]
    func encodeHaptic(durations: [UInt16]) -> [TAPProtocolWrite]
    func encodeKeepalive() -> [TAPProtocolWrite]
    func supports(_ feature: TAPDeviceFeature) -> Bool
}
