//
//  TAPProtocolDetector.swift
//  TAPKit
//

import Foundation
import CoreBluetooth

public enum TAPProtocolDetector {
    public static func detect(handle: TAPHandle) -> TAPProtocolAdapter {
        if handle.hasCharacteristic(TAPCBUUID.characteristic__V2Read)
            && handle.hasCharacteristic(TAPCBUUID.characteristic__V2Write) {
            TAPKit.log.event(.info, message: "Detected TAP v2 protocol for \(handle.identifierString)")
            return TAPV2ProtocolAdapter()
        }
        TAPKit.log.event(.info, message: "Detected TAP legacy protocol for \(handle.identifierString)")
        return TAPLegacyProtocolAdapter()
    }
}
