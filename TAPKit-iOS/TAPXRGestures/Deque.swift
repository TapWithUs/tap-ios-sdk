//
//  Deque.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 27/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

class Deque<T> {
    
    private var items : [T]
    private let len : Int
    
    init(len:Int) {
        self.items = [T]()
        self.len = len
    }
    
    func add(_ item:T) -> Void {
        self.items.append(item)
        if self.items.count > self.len {
            self.items.removeSubrange(0..<self.items.count - self.len)
        }
    }
    
    func all() -> [T] {
        return self.items
    }
}
