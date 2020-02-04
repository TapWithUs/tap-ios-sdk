//
//  RawSensorDataParserQueue.swift
//  TAPKit
//
//  Created by Shahar Biran on 04/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

class RawSensorDataParser {
    
    private static var dq = DispatchQueue(label: "RawSensorDataParserQueue")

    public static func parseWhole(data:Data, onMessageReceived:(@escaping (RawSensorData)->Void)) -> Void {
        let array = [UInt8](data)

        var metaRange = Range(uncheckedBounds: (lower:0,upper:4))
        var timestamp : UInt32 = 1
        while (metaRange.upperBound < array.count && timestamp > 0) {
            var meta : UInt32 = 0
            var add = 0
            memcpy(&meta, Array(array[metaRange.lowerBound..<metaRange.upperBound]), metaRange.upperBound - metaRange.lowerBound)
            if meta > 0 {
                let packet_type = meta & UInt32(0x80000000);
                timestamp = meta & UInt32(0x7fffffff);
                var type : RawSensorDataType = .None
                var messageRange = Range(uncheckedBounds: (lower:0, upper:0))
                
                if packet_type == 0 {
                    messageRange = Range(uncheckedBounds: (lower:metaRange.upperBound, upper:metaRange.upperBound + 12))
                    type = .IMU
                    add = 12
                } else if packet_type == 1 {
                    messageRange = Range(uncheckedBounds: (lower:metaRange.upperBound, upper:metaRange.upperBound + 30))
                    add = 30
                    type = .Device
                } else {
                    return
                }
                if type != .None {
                    RawSensorDataParser.dq.sync {
                        RawSensorDataParser.parseSingle(type: type, timestamp: timestamp, arr: Array(array[messageRange.lowerBound..<messageRange.upperBound]), onMessageReceived: onMessageReceived)
                    }
                }
                if timestamp == 0 {
                    return
                }
                if add == 0 {
                    return
                }
            }
            metaRange = Range(uncheckedBounds: (lower: metaRange.lowerBound + add, upper:metaRange.upperBound + add))
        }
        
    }
    
    private static func parseSingle(type:RawSensorDataType, timestamp:UInt32, arr:[UInt8], onMessageReceived:((RawSensorData) -> Void)) -> Void {
        if let data = RawSensorData(type: type, timestamp: timestamp, arr: arr) {
            onMessageReceived(data)
        }
    }
    
}
