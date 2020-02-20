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

    @IBOutlet weak var mouse: UIImageView!
    private var devCount = 0
    private var imuCount = 0;
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        // ---------------
        // TAPInputMode.controller()
        //      allows receiving the "tapped" and "moused" funcs callback in TAPKitDelegate with the fingers combination without any post-processing.
        //
        // TAPInputMode.text()
        //      "tapped" and "moused" funcs in TAPKitDelegate will not be called, the TAP device will be acted as a plain bluetooth keyboard.
        //
        // TAPInputMode.controllerWithMouseHID() -
        //      Same as controller mode but allows the user to use the mouse also as a regular mouse input.
        //      Starting iOS 13, Apple added Assitive Touch feature. (Can be toggled within accessibility settings on iPhone).
        //      This adds a cursor to the screen that can be navigated using TAP device.
        //
        // TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity(deviceAccelerometer: Int, imuGyro: Int, imuAccelerometer: Int))
        //      Sends sensor (Gyro and Accelerometers) data . callback function: rawSensorDataReceived. read the readme.md for more information about this mode.
        //
        // If you wish for a TAP device to enter text as part of your app, you'll need to set the mode to TAPInputMode.text(), and when you want to receive tap combination data,
        // you'll need to set the mode to TAPInputMode.controller()
        // Setting text mode:
        // TAPKit.sharedKit.setTAPInputMode(TAPInputMode.text(), forIdentifiers: [tapidentifiers])
        // tapidentifiers : array of identifiers of tap devices to set the mode to text. if nil - all taps devices connected to the iOS device will be set to text.
        // Same for settings the mode to controller:
        // TAPKit.sharedKit.setTAPInputMode(TAPInputMode.controller(), forIdentifiers: [tapIdentifiers])
        //      When [tapIdentifiers] is null or missing - the mode will be applied to ALL connected TAPs.
        //
        // Setting the default TAPInputMode for new TAPs that will be connected. (can be applied to current connected TAPs):
        // TAPKit.sharedKit.setDefaultTAPInputMode(TAPInputMode..., immediate: true/false)
        //      "immediate" - When true, this mode will be applied to all currently connected TAPs.
        
        
        // Air Gestures
        // ------------
        // TAP v2.0 devices adds Air Gestures features.
        // These Air Gestures will be triggered in:
        //      func tapAirGestured(identifier: String, gesture: TAPAirGesture)
        // Please refer to the enum TAPAirGesture to see the available gestures.
        // Works in "controller" and "controllerWithMouseHID" modes.
        // Another related callback event is:
        //      func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool)
        //          This event will be triggered when the TAP entering or leaving Air Gesture State.
        
        TAPKit.sharedKit.setTAPInputMode(TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity(deviceAccelerometer: Int, imuGyro: Int, imuAccelerometer: Int)))
        // Send Haptic/Vibration to TAP devices.
        // To make the TAP vibrate, to your specified array of durations, call:
        // TAPKit.sharedKit.vibrate(durations: [hapticDuration, pauseDuration, hapticDuration, pauseDuration, ...], forIdentifiers: [tapIdentifiers])
        //      durations: An array of durations in the format of haptic, pause, haptic, pause ... You can specify up to 18 elements in this array. The rest will be ignored.
        //                 Each array element is defined in milliseconds.
        //      When [tapIdentifiers] is null or missing - the mode will be applied to ALL connected TAPs.
        //      Example:
        //          TAPKit.sharedKit.vibrate(durations: [500,100,500])
        //          Will send two 500 milliseconds haptics with a 100 milliseconds pause in the middle.

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
    
    func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse: Bool) {
        
        // Added isMouse parameter:
        // A boolean that determines if the TAP is really using the mouse (true) or is it a dummy mouse movement (false)
        
        // Getting an event for when the Tap is using the mouse, called only when the Tap is in controller mode.
        // Since iOS doesn't support mouse - You can implement it in your app using the parameters of this function.
        // velocityX : get the amount of movement for X-axis.
        // velocityY : get the amount of movement for Y-axis.
        // Important:
        //   You may want to multiply/divide velocityX and velocityY by a constant number to your liking, in order to enhance the mouse movement to match your expectation in your app.
        //   So, basically, by multiplying/dividing the velocityX and velocityY by a constant you can implement a "mouse sensitivity" feature that will be used in your app.
        //   For example: if you have an object responding to mouse object, like written below, then muliplying the velocityX and velocityY by 2 will make the object move
        //   twice as fast.
        
        // Example: Moving the mouse image :
        if (isMouse) {
            let newPoint = CGPoint(x: self.mouse.frame.origin.x + CGFloat(velocityX), y: self.mouse.frame.origin.y + CGFloat(velocityY))
            var dx : CGFloat = 0
            var dy : CGFloat = 0
            if self.view.frame.contains(CGPoint(x: 0, y: newPoint.y)) {
                dy = CGFloat(velocityY)
            }
            if self.view.frame.contains(CGPoint(x: newPoint.x, y: 0)) {
                dx = CGFloat(velocityX)
            }
            mouse.frame = mouse.frame.offsetBy(dx: dx, dy: dy)
        }
    }
    
    func rawSensorDataReceived(identifier: String, data: RawSensorData) {
        
        //RawSensorData Object has a timestamp, type and an array points(x,y,z).
        if (data.type == .Device) {
            // Fingers accelerometer.
            // Each point in array represents the accelerometer value of a finger (thumb, index, middle, ring, pinky).
            if let thumb = data.getPoint(for: RawSensorData.iDEV_THUMB) {
                print("Thumb accelerometer value: (\(thumb.x),\(thumb.y),\(thumb.z))")
            }
            // Etc... use indexes: RawSensorData.iDEV_THUMB, RawSensorData.iDEV_INDEX, RawSensorData.iDEV_MIDDLE, RawSensorData.iDEV_RING, RawSensorData.iDEV_PINKY
        } else if (data.type == .IMU) {
            // Refers to an additional accelerometer on the Thumb sensor and a Gyro (placed on the thumb unit as well).
            if let gyro = data.getPoint(for: RawSensorData.iIMU_GYRO) {
                print("IMU Gyro value: (\(gyro.x),\(gyro.y),\(gyro.z)")
            }
            // Etc... use indexes: RawSensorData.iIMU_GYRO, RawSensorData.iIMU_ACCELEROMETER
        }
        // -------------------------------------------------
        // -- Please refer readme.md for more information --
        // -------------------------------------------------
    }
    
    func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
        switch (gesture) {
        case .OneFingerDown : print("Air Gestured: One Finger Down")
        case .OneFingerLeft : print("Air Gestured: One Finger Left")
        case .OneFingerUp : print("Air Gestured: One Finger Up")
        case .OnefingerRight : print("Air Gestured: One Finger Right")
        case .TwoFingersDown : print("Air Gestured: Two Fingers Down")
        case .TwoFingersLeft : print("Air Gestured: Two Fingers Left")
        case .TwoFingersUp : print("Air Gestured: Two Fingers Up")
        case .TwoFingersRight : print("Air Gestured: Two Fingers Right")
        case .IndexToThumbTouch : print("Air Gestured: Index finger tapping the Thumb")
        case .MiddleToThumbTouch : print("Air Gestured: Middle finger tapping the Thumb")
        }
    }
    
    func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool) {
        print("Tap is in Air Gesture State: \(isInAirGesturesState)")
    }
    
    
}



