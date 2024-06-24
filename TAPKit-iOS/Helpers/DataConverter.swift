//
//  DataConverter.swift
//  TAPKit
//
//  Created by Shahar Biran on 13/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

public
class DataConverter {
    
    public
    static func toUInt8(data:Data?, index:Int) -> UInt8? {
        if let data = data {
            let bytes : [UInt8] = [UInt8](data)
            guard index >= 0 && index < bytes.count else { return nil }
            return bytes[index]
        } else {
            return nil
        }
        
    }
    
    public
    static func toInt16(data:Data, index:Int) -> Int16? {
        let bytes : [UInt8] = [UInt8](data)
        guard index >= 0 && index < bytes.count-1 else { return nil }
        return (Int16)(bytes[index+1]) << 8 | (Int16)(bytes[index])
    }
    
    public
    static func toString(_ data:Data?) -> String? {
        if let data = data {
            return String(data: data, encoding: String.Encoding.utf8)
        } else {
            return nil
        }
        
        
    }
}


