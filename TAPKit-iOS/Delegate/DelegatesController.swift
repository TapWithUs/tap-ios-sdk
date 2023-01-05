//
//  DelegatesController.swift
//  TAPKit
//
//  Created by Shahar Biran on 13/11/2022.
//  Copyright © 2022 Shahar Biran. All rights reserved.
//

import Foundation

public
class DelegatesController<T> where T:AnyObject  {
    private var delegates : [WeakRef<T>]
    
    public
    init() {
        self.delegates = [WeakRef<T>]()
    }
    
    
    private func removeDeadReferences() -> Void {
        self.delegates = self.delegates.filter({ $0.isAlive() })
    }
    
    public
    func add(_ delegate:T) -> Void {
        self.removeDeadReferences()
        if (!self.delegates.contains(where: { $0.get() === delegate })) {
            self.delegates.append(WeakRef<T>(delegate))
        }
    }
    
    public
    func remove(_ delegate:T) -> Void {
        self.removeDeadReferences()
        self.delegates = self.delegates.filter({ $0.get() !== delegate })
    }
    
    public
    func run(action:((T)->Void)) {
        self.delegates.forEach( { delegate in
            if (delegate.isAlive()) {
                action(delegate.get()!)
            }
        })
    }
    
    
}
