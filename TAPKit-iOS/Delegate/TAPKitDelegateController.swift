//
//  TAPKitDelegatesController.swift
//  TAPKit
//
//  Created by Shahar Biran on 25/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

@objc public protocol TAPKitDelegate : class {
    @objc optional func tapConnected(withIdentifier identifier:String, name:String)
    @objc optional func tapDisconnected(withIdentifier identifier:String)
    @objc optional func tapFailedToConnect(withIdentifier identifier:String, name:String)
    @objc optional func tapped(identifier:String, combination:UInt8, multitap:UInt8)
    @objc optional func moused(identifier:String, velocityX:Int16, velocityY:Int16, isMouse:Bool)
    @objc optional func rawSensorDataReceived(identifier:String, data:RawSensorData)
    @objc optional func tapChangedAirGesturesState(identifier:String, isInAirGesturesState:Bool)
    @objc optional func tapAirGestured(identifier:String, gesture:TAPAirGesture)
    @objc optional func tapDidReadHardwareVersion(identifier:String, hw:Int)
    @objc optional func tapDidReadFirmwareVersion(identifier:String, fw:Int)
    @objc optional func tapDidReadBatteryLevel(identifier:String, batteryLevel:Int)
    @objc optional func tapHoldStarted(identifier:String, combination:UInt8)
    @objc optional func tapHoldEnded(identifier:String, combination:UInt8)
    @objc optional func tapDidChangeOrientation(roll:Int, pitch:Int, yaw:Int)
    @objc optional func tapXRAirGestured(identifier:String, gesture:TAPXRAirGesture)
}
