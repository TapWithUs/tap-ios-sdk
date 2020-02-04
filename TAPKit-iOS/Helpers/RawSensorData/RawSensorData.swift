//
//  RawSensorData.swift
//  TAPKit
//
//  Created by Shahar Biran on 04/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class Point3 : NSObject {
    public var x : Int!
    public var y : Int!
    public var z : Int!
    
    public override init() {
        self.x = 0
        self.y = 0
        self.z = 0
        super.init()
    }
    
    public init(x:Int, y:Int, z:Int) {
        self.x = x
        self.y = y
        self.z = z
        super.init()
    }
    
    public init?(arr:[UInt8]) {
        guard arr.count == 6 else { return nil }
        self.x = Int(Int(arr[0])<<8 | Int(arr[1]))
        self.y = Int(Int(arr[2])<<8 | Int(arr[3]))
        self.z = Int(Int(arr[4])<<8 | Int(arr[5]))
        super.init()
    }
}

@objc public enum RawSensorDataType : Int {
    case None = 0
    case IMU = 1
    case Device = 2
    
}


@objc public class RawSensorData : NSObject {

    @objc public static let iIMU_GYRO = 0
    @objc public static let iIMU_ACCELEROMETER = 1
    @objc public static let iDEV_THUMB = 0
    @objc public static let iDEV_INDEX = 1
    @objc public static let iDEV_MIDDLE = 2
    @objc public static let iDEV_RING = 3
    @objc public static let iDEV_PINKY = 4
    
    public let timestamp : UInt32
    public let type : RawSensorDataType
    public var points : [Point3]
    
    public override init() {
        self.points = [Point3]()
        self.timestamp = 0
        self.type = .None
        super.init()
        
    }
    
    public init?(type:RawSensorDataType, timestamp:UInt32, arr:[UInt8]) {
        self.points = [Point3]()
        self.timestamp = timestamp
        self.type = type
        
        var range = Range.init(uncheckedBounds: (lower:0,upper:6))
        while (range.lowerBound < arr.count) {
            guard arr.indices.contains(range.upperBound-1) else { return nil }
            if let point = Point3(arr: Array(arr[range.lowerBound ..< range.upperBound])) {
                self.points.append(point)
            } else {
                return nil
            }
            range = Range.init(uncheckedBounds: (lower:range.lowerBound + 6, upper:range.upperBound + 6))
        }
        
        // Final double-check
        if self.type == .IMU {
            guard self.points.count == 2 else { return nil }
        } else if self.type == .Device {
            guard self.points.count == 5 else { return nil }
        } else {
            return nil
        }
        super.init()
    }
    
    public func makeString() -> String {
        var typeString = "None"
        if self.type == .IMU {
            typeString = "IMU"
        } else if self.type == .Device {
            typeString = "Device"
        }
        
        var pointsString = ""
        for i in 0..<self.points.count {
            let p = self.points[i]
            pointsString.append(" { x = \(p.x!), y = \(p.y!), z = \(p.z!) }")
            
        }
        
        return "Type = \(typeString), points =\(pointsString)"
    }
}
