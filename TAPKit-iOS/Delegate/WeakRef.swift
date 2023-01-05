//
//  WeakRef.swift
//  TAPKit
//
//  Created by Shahar Biran on 10/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

public
class WeakRef<T> where T: AnyObject {
    
    private weak var ref: T?
    
    init(_ ref: T?) {
        self.ref = ref
    }
    
    func get() -> T? {
        return self.ref
    }
    
    func isAlive() -> Bool {
        return self.ref != nil
    }
}
