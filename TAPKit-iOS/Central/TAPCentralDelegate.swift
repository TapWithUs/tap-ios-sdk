//
//  TAPCentralDelegate.swift
//  TAPKit
//
//  Created by Shahar Biran on 09/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc protocol TAPCentralDelegate {
    @objc optional func tapConnected(identifier uuid:String, name:String) -> Void
    @objc optional func tapDisconnected(identifier uuid:String) -> Void
    @objc optional func tapFailedToConnect(identifier uuid:String) -> Void
    @objc optional func tapDidReadCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data)
    @objc optional func tapDidWriteCharacteristicValue(identifier uuid:String, characteristic:CBUUID, value:Data?)
}

