# TAP iOS SDK

## Updates 
July 2024 - Added **TAPXR Gestures** (See below).
    
## What Is This ?

TAP iOS SDK allows you to build a a native iOS app that can receive input from TAP devices,
In a way that each tap is being interpreted as an array or fingers that are tapped, or a binary combination integer (explanation follows), Thus allowing the TAP device to act as a controller for your app!

## Integration

Download the SDK open-source code from github, and compile it to create TAPKit.framework.
The SDK is written in swift but supports objective-c integration as well.

Importing TAPKit into your source code:
```swift
    import TAPKit
```

## Implementing TAPKitDelegate

TAPKit uses delegates to call the neccessary functions, and supports multiple delegates.

To add a delegate, you must implement TAPKitDelegate protocol.
Functions available (all optional) in TAPKitDelegate:

```swift
    @objc public protocol TAPKitDelegate : class {
        @objc optional func tapConnected(withIdentifier identifier:String, name:String)
        @objc optional func tapDisconnected(withIdentifier identifier:String)
        @objc optional func tapFailedToConnect(withIdentifier identifier:String, name:String)
        @objc optional func tapped(identifier:String, combination:UInt8)
        @objc optional func moused(identifier:String, velocityX:Int16, velocityY:Int16, isMouse:Bool)
		@objc optional func rawSensorDataReceived(identifier:String, data:RawSensorData)
		@objc optional func tapChangedAirGesturesState(identifier:String, isInAirGesturesState:Bool)
		@objc optional func tapAirGestured(identifier:String, gesture:TAPAirGesture)
        @objc optional func tapDidReadHardwareVersion(identifier:String, hw:Int)
        @objc optional func tapDidReadFirmwareVersion(identifier:String, fw:Int)
    }
```
### Deprecated:
	@objc optional func centralBluetoothState(poweredOn:Bool) -> Void

### centralBluetoothState(poweredOn:Bool)

Called whenever bluetooth state is changed. You can use this function to alert the user for example.


### tapConnected(withIdentifier identifier: String, name: String)

Called when a TAP device is connected to the iOS device, sending the TAP identifier and it's display name.
Each TAP device has an identifier (a unique string) to allow you to keep track of all the taps that are connected
(if for example you're developing a multiplayer game, you need to keep track of the players).
This identifier is used in the rest of the TAPKitDelegate functions.
* TAPKit does NOT scan for TAP devices, therefor the use must pair the devices to the iOS device first.


### tapDisconnected(withIdentifier identifier: String)

Called when a TAP device is disconnected from the iOS device, sending the TAP identifier.


### tapFailedToConnect(withIdentifier identifier: String, name: String)

Called when a TAP device failed to connect, sending the TAP identifier and it's display name.


### tapped(identifier: String, combination: UInt8)

This is where magic will happen.
This function will tell you which TAP was being tapped (identifier:String), and which fingers are tapped (combination:UInt8)
Combination is a 8-bit unsigned number, between 1 and 31.
It's binary form represents the fingers that are tapped.
The LSb (bit 0) is thumb finger, the MSb (bit 4) is the pinky finger.
For example: if combination equls 5 - it's binary form is 10100, which means that the thumb and the middle fingers are tapped.
For your convenience, you can convert the binary format into fingers boolean array (explanation follows)

### moused(identifier:String, velocityX:Int16, velocityY:Int16, isMouse:Bool)

This function will be called when the user is using the TAP as a mouse.
velocityX and velocityY are the velocities of the mouse movement. These values can be multiplied by a constant to simulate "mouse sensitivity" option.
isMouse is a boolean that determine if the movement is real (true) or falsely detected by the TAP (false).

### tapAirGestured(identifier: String, gesture: TAPAirGesture)

TAP v2.0 Adds Air Gesture features. These Air Gestures events are triggered in this func. 
Available Air Gestures receieved in this callback:

```swift
enum TAPAirGesture : Int {
    case OneFingerUp = 2
    case TwoFingersUp = 3
    case OneFingerDown = 4
    case TwoFingersDown = 5
    case OneFingerLeft = 6
    case TwoFingersLeft = 7
    case OnefingerRight = 8
    case TwoFingersRight = 9
    case IndexToThumbTouch = 10
    case MiddleToThumbTouch = 11
}
```

### tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool)

this function is called when a TAP is entering or leaving Air Gesture State.

### rawSensorDataReceived(identifier: String, data: RawSensorData)

this function is called in a 200 calls per minute rate, and it's purpose is to stream the Sensors (Gyro and Accelerometers) values. More or that later....

### tapDidReadHardwareVersion(identifier:String, hw:Int)

This function is called when the TAP is connected and the Hardware version was read from the device.
The format is Integer: MMmmbb
MM for major, mm for minor, bb for build. 
Example: 30200 Translates into hardware: 3.2 (30200 -> 03 02 00 -> 3.2)

### tapDidReadFirmwareVersion(identifier:String, fw:Int)

Same as Hardware version, but for Firmware version. 
Same format, See above: **tapDidReadHardwareVersion**


## Adding a TAPKitDelegate :

If your class implements TAPKitDelegate, you can tell TAPKit to add the class as a delegate, thus allowing your class to receive the above callbacks. To do so:

```swift
    TAPKit.sharedKit.addDelegate(self)
```

After you added your class as a delegate, you need to call the "start" function.
The "start" function should be called once, usually in the main screen where you need the tapConnected callback.

```swift
    TAPKit.sharedKit.start()
```

## Removing a TAPKitDelegate

If you no longer need the callbacks, you can remove your class as a TAPKitDelegate:

```swift
    TAPKit.sharedKit.removeDelegate(self)
```

## Converting a binary combination to fingers array

As said before, the tapped combination is an unsigned 8-bit integer. to convert it to array of booleans:

```swift
    let fingers = TAPCombination.toFingers(combination)
```

While:
fingers[0] indicates if the thumb is being tapped.
fingers[1] indicates if the index finger is being tapped.
fingers[2] indicates if the middle finger is being tapped.
fingers[3] indicates if the ring finger is being tapped.
fingers[4] indicates if the pinky finger is being tapped.


## Get the connected TAPS

If you wish at any point in your app, as long as TAPKit has been started, you can receive a dictionary of connected taps.

```swift
    let taps = TAPKit.sharedKit.getConnectedTaps()
```
While the result is a dictionary where the key is the tap identifier, and the value is it's display name.


## TAPInputMode

Each TAP has a mode in which it works as.
Four modes available: 
CONTROLLER MODE (Default) 
    allows receiving the "tapped" and "moused" func callbacks in TAPKitDelegate with the fingers combination without any post-processing.
    
TEXT MODE 
    the TAP device will behave as a plain bluetooth keyboard, "tapped" and "moused" funcs in TAPKitDelegate will not be called.
CONTROLLER MODE WITH MOUSE HiD 
    Same as controller mode but allows the user to use the mouse also as a regular mouse input.
    Starting iOS 13, Apple added Assitive Touch feature. (Can be toggled within accessibility settings on iPhone).
    This adds a cursor to the screen that can be navigated using TAP device. 

RAW SENSOR DATA MODE
    This will stream the sensors (Gyro and Accelerometer) values. More or that later ...



When a TAP device is connected it is by default set to controller mode.

If you wish for a TAP to act as a bluetooth keyboard and allow the user to enter text input in your app, you can set the mode:

```swift
    TAPKit.sharedKit.setTAPInputMode(TAPInputMode.text(), forIdentifiers: [String])
```

The first parameter is the mode. You can use any of these modes: TAPInputMode.controller, TAPInputMode.text
the second parameter is an array of identifiers of TAP devices that you want to change the mode. You can pass nil if you want ALL the TAP devices to change their mode.

Just don't forget to switch back to controller mode after the user has entered the text :

```swift
TAPKit.sharedKit.setTAPInputMode(TAPInputMode.controller(), forIdentifiers: [String])
```

### Setting the Default TAPInputMode

If you wish - You can change the default TAPInputMode so new connected devices will be set to this mode, with an option to apply this mode to current connected devices (the immediate parameter).

```swift
TAPKit.sharedKit.setDefaultTAPInputMode(TAPInputMode..., immediate: bool)
```

# TAPXR Gestures (July 2024)

Added support to read the hand state while in AirMouse mode, for the TapXR device.

## TAPAirGesture

Added 3 states for the enum TAPAirGesture:

```swift
@objc public enum TAPAirGesture : Int {
    .
    .
    .
    case XRAirGestureNone = 100
    case XRAirGestureThumbIndex = 101
    case XRAirGestureThumbMiddle = 102
}
```

XRAirGestureNone: The hand is in resting state.
XRAirGestureThumbIndex : the thumb is touching the index finger.
XRAirGestureThumbMiddle : the thumb is touching the middle finger. 

These states will be sent continously multiple times per second.

The best practice is the take the most common one out of the last 3 events received to allow margin for errors.

This will allow you to combine these states and the mouse-move event into "Drag and Drop" Gesture for example.

##TAPXRState

In addition to TAPInputMode, the new TAPXR has input states.

You can force TAPXR to switch to input state as follows:

AIRMOUSE - The TAPXR will operate in AIRMOUSE mode ONLY.
TAPPING - The TAPXR will operate in TAPPING mode only.
USERCONTROL - The user will freely switch states as wished.

Examples:

```swift
TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.userControl(), applyImmediate: true)
TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.tapping(), applyImmediate: true)
TAPKit.sharedKit.setTAPXRState(TAPXRState.airMouse(), forIdentifiers: ["identifier..."])
```

You can change the state of individual connected device or devices by calling setTAPXRState(.., forIdentifiers: []) which accepts an array of identifiers to apply the new state to.

While calling setDefaultTAPXRState, it'll set the default state that will be applied to newly connected devices. 
If you wish to apply this state to already-connected devices, call with "applyImmediate": true.

## Vibrations/Haptic

Send Haptic/Vibration to TAP devices.
To make the TAP vibrate, to your specified array of durations, call:
```swift 
TAPKit.sharedKit.vibrate(durations: [hapticDuration, pauseDuration, hapticDuration, pauseDuration, ...], forIdentifiers: [String])
```
durations: An array of durations in the format of haptic, pause, haptic, pause ... You can specify up to 18 elements in this array. The rest will be ignored.
Each array element is defined in milliseconds.
When [tapIdentifiers] is null or missing - all connected Taps will vibrate.
Example:
```swift
TAPKit.sharedKit.vibrate(durations: [500,100,500])
```
Will send two 500 milliseconds haptics with a 100 milliseconds pause in the middle.

## RAW SENSOR MODE

In raw sensors mode, the TAP continuously sends raw data from the following sensors:
    1. Five 3-axis accelerometers on each finger ring.
    2. IMU (3-axis accelerometer + gyro) located on the thumb (**for TAP Strap 2 only**).
        
### To put a TAP into Raw Sensor Mode:
```swift

TAPKit.sharedKit.setTAPInputMode(TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity(deviceAccelerometer: Int, imuGyro: Int, imuAccelerometer: Int)))
```

When puting TAP in Raw Sensor Mode, the sensitivities of the values can be defined by the developer.
    deviceAccelerometer refers to the sensitivities of the fingers' accelerometers. Range: 1 to 4.
    imuGyro refers to the gyro sensitivity on the thumb's sensor. Range: 1 to 4.
    imuAccelerometer refers to the accelerometer sensitivity on the thumb's sensor. Range: 1 to 5.

Using the default sensitivities:
```swift
TAPKit.sharedKit.setTAPInputMode(TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity()))
```
### Stream callback:

```swift
func rawSensorDataReceived(identifier: String, data: RawSensorData)
```
RawSensorData Object has a timestamp, type and an array points(x,y,z).
type is RawSensorDataType enum:
```swift
enum RawSensorDataType : Int {
    case None = 0
    case IMU = 1
    case Device = 2
}
```
IMU is the Gyro and Accelerometer sensors in the thumb unit.
Device is the Accelerometers sensors for each finger (Thumb, Index, Middle, Ring, Pinky).

### Getting the points from RawSensorData stream:

```swift
 func rawSensorDataReceived(identifier: String, data: RawSensorData) {
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
```

[For more information about raw sensor mode click here](https://tapwithus.atlassian.net/wiki/spaces/TD/pages/792002574/Tap+Strap+Raw+Sensors+Mode)

## Logging

TAPKit has a log, which logs all the events that happens. This can be useful for debugging, or should be attached when reporting a bug :)

There are 4 types of events:

```swift
    @objc public enum TAPKitLogEvent : Int {
        case warning = 0
        case error = 1
        case info = 2
        case fatal = 3
    }
```

To enable logging of all the events:

```swift
    TAPKit.log.enableAllEvents()
```

To disable logging of all the events:

```swift
    TAPKit.log.disableAllEvents()
```

To enable a specific event, errors for example:

```swift
    TAPKit.log.enable(event: .error)
```

And to disable a spcific event, warnings for example:

```swift
    TAPKit.log.disable(event: .warning)
```

## Example APP

The xcode project contains an example app where you can see how to use the features of TAPKit.

## Support

Please refer to the issues tab! :)


# Have fun!





