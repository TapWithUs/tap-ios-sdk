//
//  Queue.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class Queue<T> {
    private var items : [T]
    
    init() {
        items = [T]()
    }
    
    func put(_ item:T) -> Void {
        self.items.append(item)
    }
    
    func get() -> T? {
        guard self.items.count > 0 else { return nil }
        return self.items.removeFirst()
    }
    
    func peek() -> T? {
        return self.items.first
    }
}
