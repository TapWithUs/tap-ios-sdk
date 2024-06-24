//
//  TAPHandleValidator.swift
//  TAPKit
//
//  Created by Shahar Biran on 12/01/2023.
//  Copyright © 2023 Shahar Biran. All rights reserved.
//

import Foundation
import CoreBluetooth

public
protocol TAPHandleValidator : AnyObject {
    func validate(_ handle:TAPHandle) -> Bool
}

open
class TAPHandleDefaultValidator : TAPHandleValidator{
    
    public init() {
        
    }
    
    open
    func validate(_ handle: TAPHandle) -> Bool {
       return true
    }
}


