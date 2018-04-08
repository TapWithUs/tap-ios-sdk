//
//  TAPKit.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public class TAPKit : NSObject {
    @objc public static let sharedKit = TAPKit()
    
    @objc public static let log = TAPKitLog.sharedLog
    
    private var kitCentral : TAPKitCentral!
    
    private override init() {
        super.init()
        self.kitCentral = TAPKitCentral()
    }
}

extension TAPKit {
    // public interface
    
    
    
    @objc public func start() -> Void {
        self.kitCentral.start()
    }
    
    @objc public func addDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.kitCentral.add(delegate: delegate)
    }
    
    @objc public func removeDelegate(_ delegate:TAPKitDelegate) -> Void {
        self.kitCentral.remove(delegate: delegate)
    }
    
    @objc public func setTAPInputMode(_ newMode:String, forIdentifiers identifiers : [String]?) -> Void {
        self.kitCentral.setTAPInputMode(newMode, forIdentifiers: identifiers)
    }
    
    @objc public func getConnectedTaps() -> [String : String] {
        return self.kitCentral.getConnectedTaps()
    }
    
    @objc public func getTAPInputMode(forTapIdentifier identifier:String) -> String? {
        return self.kitCentral.getTAPInputMode(forTapIdentifier:identifier)
    }
}
