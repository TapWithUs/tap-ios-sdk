//
//  ViewController.swift
//  TAPKit-Example
//
//  Created by Shahar Biran on 08/04/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import UIKit
import TAPKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Any class that wish to get taps related callbacks, must add itself as a delegate:
        TAPKit.sharedKit.addDelegate(self)

        // You can enable/disable logs for specific events, or all events
        // TAPKitLogEvent.error, TAPKitLogEvent.fatal, TAPKitLogEvent.info, TAPKitLogEvent.warning
        // For example, to enable only errors logs:
        // TAPKit.log.enable(event: .error)
        TAPKit.log.disable(event: .warning)
        TAPKit.log.enableAllEvents()
        
        // start should be called typically in the main screen, after the delegate was being set earlier.
        TAPKit.sharedKit.start()
        
        // At any point of your app, you may get the connected taps:
        // result is a dictionary format of [identifier:name]
        // let taps = TAPKit.sharedKit.getConnectedTaps()
        
        
        // Tap Input mode:
        // TAPInputMode.controller - allows receiving the "tapped" func callback in TAPKitDelegate with the fingers combination without any post-processing.
        // TAPInputMode.text - "tapped" func in TAPKitDelegate will not be called, the TAP device will be acted as a plain bluetooth keyboard.
        // If you wish for a TAP device to enter text as part of your app, you'll need to set the mode to TAPInputMode.text, and when you want to receive tap combination data,
        // you'll need to set the mode to TAPInputMode.controller
        // Setting text mode:
        // TAPKit.sharedKit.setTAPInputMode(TAPInputMode.text, forIdentifiers: [tapidentifiers])
        // tapidentifiers : array of identifiers of tap devices to set the mode to text. if nil - all taps devices connected to the iOS device will be set to text.
        // Same for settings the mode to controller:
        // TAPKit.sharedKit.setTAPInputMode(TAPInputMode.controller, forIdentifiers: [tapidentifiers])
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        TAPKit.sharedKit.removeDelegate(self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController : TAPKitDelegate {
    
    func centralBluetoothState(poweredOn: Bool) {
        // Do something if the bluetooth state is on or off.
    }
    
    func tapped(identifier: String, combination: UInt8) {
        // Called when a user tap, only when the TAP device is in controller mode.
        print("TAP \(identifier) tapped combination: \(combination)")
        
        // Combination is a 8-bit unsigned number, between 1 and 31.
        // It's binary form represents the fingers that are tapped.
        // The LSB is thumb finger, the MSB (bit number 5) is the pinky finger.
        // For example: if combination equls 3 - it's binary form is 00101,
        // Which means that the thumb and the middle fingers are tapped.
        // For your convenience, you can convert the binary format into fingers boolean array, while:
        // fingers[0] indicates if the thumb is being tapped.
        // fingers[1] indicates if the index finger is being tapped.
        // fingers[2] indicates if the middle finger is being tapped.
        // fingers[3] indicates if the ring finger is being tapped.
        // fingers[4] indicates if the pinky finger is being tapped.
        
        let fingers = TAPCombination.toFingers(combination)
        
        // For printing :
        var fingersString = ""
        for i in 0..<fingers.count {
            if fingers[i] {
                fingersString.append(TAPCombination.fingerName(i) + " ")
            }
        }
        print("---combination fingers : \(fingersString)")
    }
    
    func tapDisconnected(withIdentifier identifier: String) {
        // TAP device disconnected
        print("TAP \(identifier) disconnected.")
    }
    
    func tapConnected(withIdentifier identifier: String, name: String) {
        // TAP device connected
        // We recomend that you'll keep track of the taps' identifier, if you're developing a multiplayer game and you need to keep track of all the players,
        // As multiple taps can be connected to the same iOS device.
        print("TAP \(identifier), \(name) connected!")
    }
    
    func tapFailedToConnect(withIdentifier identifier: String, name: String) {
        // TAP device failed to connect
        print("TAP \(identifier), \(name) failed to connect!")
    }
}



