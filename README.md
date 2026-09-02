# TAP iOS SDK

Native iOS framework for receiving input from TAP devices over Bluetooth. TAP events are delivered as finger combinations, mouse movement, air gestures, spatial TapXR gestures, raw sensor streams, and more.

Written in Swift with Objective-C interoperability. The Xcode project also includes **TAPKit-Example** (sample app) and **TAPKitUnityBridge** (Unity wrapper).

## Requirements

- iOS 11.2+ (framework target); iOS 15.6+ recommended for the example app
- Xcode with Swift support
- Bluetooth enabled on the host device
- TAP device paired with the iOS device in **Settings → Bluetooth** (the SDK connects to already-paired peripherals; it does not run its own scan UI)

Add to your app's `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to TAP devices.</string>
```

## Integration

1. Clone this repository and open `TAPKit.xcodeproj`.
2. Build the **TAPKit** scheme to produce `TAPKit.framework`.
3. Embed `TAPKit.framework` in your app (Embed & Sign).
4. Import in Swift:

```swift
import TAPKit
```

For Objective-C, import the generated header:

```objc
#import <TAPKit/TAPKit-Swift.h>
```

## Quick start

```swift
class MyViewController: UIViewController, TAPKitDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        TAPKit.log.disableAllEvents()          // optional
        TAPKit.sharedKit.addDelegate(self)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.airMouse(), applyImmediate: true)  // TapXR only
        TAPKit.sharedKit.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TAPKit.sharedKit.removeDelegate(self)
    }

    func tapConnected(withIdentifier identifier: String, name: String) {
        print("Connected: \(name) (\(identifier))")
    }

    func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
        let fingers = TAPCombination.toFingers(combination)
        print("Tap from \(identifier): \(fingers), multitap: \(multitap)")
    }
}
```

Call `start()` once (typically when your main screen appears). Add one or more `TAPKitDelegate` implementations before or after `start()`.

---

## Protocol versions: legacy (v1) and V2

TAP firmware speaks one of two BLE protocols, and TAPKit detects which one per device when it connects — no configuration needed:

| | Legacy (v1) — "classic" | V2 — "framed" |
|---|---|---|
| Hardware | Tap Strap, Tap Strap 2, TapXR | TapBand, TapXR (newer firmware) |
| BLE layout | Separate notify characteristics per event type; input-mode commands over NUS | One framed read/write characteristic pair; all events and commands as framed messages |
| Extras | HID keyboard/mouse modes | Device features, vision sensor control, standby, serial number, keepalive |

Everything in this SDK works the same on both protocols: the same delegate callbacks fire and the same `TAPInputMode` / `TAPXRState` calls apply (TAPKit translates them to the right protocol under the hood). The only V2-specific parts are the APIs marked **(V2 devices)** — see [V2 device configuration](#v2-device-configuration-v2-devices) — which are ignored on legacy devices.

This split matches the [tap-python-sdk](https://github.com/TapWithUs/tap-python-sdk) documentation, where the same protocols are called v1 (`TapSDK`) and v2 (`TapSDK2`).

---

## TAPKitDelegate

All delegate methods are **optional**. Multiple delegates are supported.

```swift
@objc public protocol TAPKitDelegate : class {
    @objc optional func tapConnected(withIdentifier identifier: String, name: String)
    @objc optional func tapDisconnected(withIdentifier identifier: String)
    @objc optional func tapFailedToConnect(withIdentifier identifier: String, name: String)

    @objc optional func tapped(identifier: String, combination: UInt8, multitap: UInt8)
    @objc optional func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse: Bool)
    @objc optional func rawSensorDataReceived(identifier: String, data: RawSensorData)

    @objc optional func tapChangedAirGesturesState(identifier: String, isInAirGesturesState: Bool)
    @objc optional func tapAirGestured(identifier: String, gesture: TAPAirGesture)
    @objc optional func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture)

    @objc optional func tapDidReadHardwareVersion(identifier: String, hw: Int)
    @objc optional func tapDidReadFirmwareVersion(identifier: String, fw: Int)
    @objc optional func tapDidReadBatteryLevel(identifier: String, batteryLevel: Int)

    @objc optional func tapHoldStarted(identifier: String, combination: UInt8)
    @objc optional func tapHoldEnded(identifier: String, combination: UInt8)

    @objc optional func tapDidChangeOrientation(roll: Int, pitch: Int, yaw: Int)

    @objc optional func tapChangedStandbyState(identifier: String, isInStandby: Bool)
    @objc optional func tapDidReadSerialNumber(identifier: String, serialNumber: String)
}
```

### Connection

| Callback | Description |
|----------|-------------|
| `tapConnected(withIdentifier:name:)` | A TAP device is connected and ready. `identifier` is the stable UUID string used in all other callbacks. |
| `tapDisconnected(withIdentifier:)` | Device disconnected. |
| `tapFailedToConnect(withIdentifier:name:)` | Connection attempt failed. |

### Taps and mouse

| Callback | Description |
|----------|-------------|
| `tapped(identifier:combination:multitap:)` | Finger tap event. `combination` is a 5-bit bitmask (thumb = bit 0 … pinky = bit 4). `multitap` is keyboard multitap state when applicable (1–3). |
| `moused(identifier:velocityX:velocityY:isMouse:)` | Air-mouse movement. Scale velocities for sensitivity. `isMouse == true` means real movement; `false` means idle/zero packet. |
| `tapHoldStarted` / `tapHoldEnded` | Long-press begin/end when device is in **Tap Hold** input mode. Single taps in that mode still arrive via `tapped`. |

### Air gestures

| Callback | Description |
|----------|-------------|
| `tapChangedAirGesturesState(identifier:isInAirGesturesState:)` | Device entered or left air-gesture mode. |
| `tapAirGestured(identifier:gesture:)` | Legacy air gestures (Tap Strap 1.x / older firmware). See [TAPAirGesture](#tapairgesture-legacy). |
| `tapXRAirGestured(identifier:gesture:)` | Spatial TapXR gestures (pinch, drag, swipe, fist). See [TAPXRAirGesture](#tapxrairgesture-tapxr-spatial-control). |

### Device info

| Callback | Description |
|----------|-------------|
| `tapDidReadHardwareVersion(identifier:hw:)` | Hardware version as integer `MMmmbb` (major, minor, build). Example: `30200` → 3.2.0. |
| `tapDidReadFirmwareVersion(identifier:fw:)` | Same format as hardware version. |
| `tapDidReadBatteryLevel(identifier:batteryLevel:)` | Battery level 0–100. Trigger reads with `readBatteryLevel()`. |
| `tapDidChangeOrientation(roll:pitch:yaw:)` | IMU orientation from mouse data characteristic. |
| `tapDidReadSerialNumber(identifier:serialNumber:)` | Serial number (V2 devices). Read automatically on connect; trigger again with `readSerialNumber()`. |
| `tapChangedStandbyState(identifier:isInStandby:)` | Device entered or left standby (V2 devices). |

Version reads are triggered automatically on connect for supported devices. You can also call `readHardwareVersion()`, `readFirmwareVersion()`, and `readBatteryLevel()` explicitly.

---

## TAPKit API

### Lifecycle

```swift
TAPKit.sharedKit.start()                    // Start BLE central, mode sync, keepalive
TAPKit.sharedKit.resume()                   // Start if not already started
TAPKit.sharedKit.addDelegate(self)
TAPKit.sharedKit.removeDelegate(self)
```

### Connected devices

```swift
let taps: [String: String] = TAPKit.sharedKit.getConnectedTaps()
// Key = identifier (UUID string), value = display name
```

### Input modes

```swift
TAPKit.sharedKit.setTAPInputMode(TAPInputMode.text(), forIdentifiers: nil)
TAPKit.sharedKit.setDefaultTAPInputMode(TAPInputMode.controller(), immediate: true)
let mode = TAPKit.sharedKit.getTAPInputMode(identifier: uuid)
```

Pass `nil` for `forIdentifiers` to apply to all connected devices.

### TapXR state (TapXR devices)

```swift
TAPKit.sharedKit.setTAPXRState(TAPXRState.airMouse(), forIdentifiers: [uuid])
TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.userControl(), applyImmediate: true)
```

### Haptics

```swift
TAPKit.sharedKit.vibrate(durations: [500, 100, 500], forIdentifiers: nil)
```

`durations` alternates haptic-on and pause segments in **milliseconds** (up to 18 values used). Pass `nil` identifiers to vibrate all connected devices.

### Device reads

```swift
TAPKit.sharedKit.readBatteryLevel(forIdentifiers: nil)
TAPKit.sharedKit.readHardwareVersion(forIdentifiers: nil)
TAPKit.sharedKit.readFirmwareVersion(forIdentifiers: nil)
TAPKit.sharedKit.readSerialNumber(forIdentifiers: nil)          // V2 devices; result via tapDidReadSerialNumber
let serial = TAPKit.sharedKit.getSerialNumber(identifier: uuid) // stored value from on-connect read
```

### V2 device configuration (V2 devices)

Direct access to V2 protocol primitives, matching the [tap-python-sdk](https://github.com/TapWithUs/tap-python-sdk) `TapSDK2` API. These commands only apply to devices using the [V2 ("framed") protocol](#protocol-versions-legacy-v1-and-v2); on legacy (v1) devices they are ignored (a warning is logged) and getters complete with `nil`.

Note: input modes (`setTAPInputMode`) also write these features under the hood. Use the direct APIs when you need fine-grained control or read-back; a later mode change may overwrite direct feature writes.

#### Device features

```swift
TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: [uuid])

TAPKit.sharedKit.getFeature(.modelDetection, forIdentifier: uuid) { enabled in
    print("modelDetection enabled: \(String(describing: enabled))")  // nil on timeout
}
```

`TAPV2DeviceFeature` values:

| Case | Value | Description |
|------|-------|-------------|
| `.rawIMUData` | 0 | Stream raw IMU packets (delivered via `rawSensorDataReceived`). |
| `.modelDetection` | 1 | On-device tap / air-gesture model detection (`tapped`, `tapXRAirGestured`). |
| `.imuMotionData` | 2 | IMU motion stream (`moused`, `tapDidChangeOrientation`). |
| `.triggerDetections` | 3 | Trigger detections (reserved; not implemented in current firmware). |
| `.standbyGestureDetection` | 4 | Wake-gesture detection while the device is in standby. |

#### Vision sensor (TapXR)

```swift
TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: [uuid])   // .trigger / .streamOnTrigger / .stream
TAPKit.sharedKit.setVisionSensorModel(.airGesture, forIdentifiers: [uuid]) // .tapping / .airGesture

TAPKit.sharedKit.getVisionSensorOpMode(forIdentifier: uuid) { mode in ... }
TAPKit.sharedKit.getVisionSensorModel(forIdentifier: uuid) { model in ... }
```

#### IMU sensitivity

```swift
TAPKit.sharedKit.setIMUSensitivity(gyro: 2, accelerometer: 1, forIdentifiers: [uuid])  // gyro 0-5, accelerometer 0-4

TAPKit.sharedKit.getIMUSensitivity(forIdentifier: uuid) { sensitivity in
    if let s = sensitivity { print("gyro: \(s.gyro), accelerometer: \(s.accelerometer)") }
}
```

#### Standby

```swift
TAPKit.sharedKit.setStandbyState(true, forIdentifiers: [uuid])

TAPKit.sharedKit.getStandbyState(forIdentifier: uuid) { isInStandby in ... }
```

Unsolicited standby changes are delivered via the `tapChangedStandbyState(identifier:isInStandby:)` delegate callback.

All getters accept an optional `timeout:` parameter (default 2 seconds, `TAPKit.v2ConfigGetTimeout`); completions run on the main queue. If a second get of the same kind is issued to the same device before the first completes, the first completes with `nil`.

#### Objective-C visibility

The `set*` commands, `readSerialNumber()`, `getSerialNumber(identifier:)`, and the `TAPV2DeviceFeature` / `TAPV2VisionSensorOpMode` / `TAPV2VisionSensorModel` enums are exposed to Objective-C. The `get*` read-back functions use Swift completion handlers with optionals and are available from Swift only.

#### tap-python-sdk equivalents

For teams working across both SDKs, the mapping to [tap-python-sdk](https://github.com/TapWithUs/tap-python-sdk) `TapSDK2` is:

| TAPKit (iOS) | tap-python-sdk (`TapSDK2`) |
|--------------|----------------------------|
| `setFeature` / `getFeature` | `set_feature` / `get_feature` |
| `setVisionSensorOpMode` / `getVisionSensorOpMode` | `set_vision_sensor_op_mode` / `get_vision_sensor_op_mode` |
| `setVisionSensorModel` / `getVisionSensorModel` | `set_vision_sensor_model` / `get_vision_sensor_model` |
| `setIMUSensitivity` / `getIMUSensitivity` | `set_imu_sensitivity` / `get_imu_sensitivity` |
| `setStandbyState` / `getStandbyState` | `set_standby_state` / `get_standby_state` |
| `tapChangedStandbyState` delegate callback | `register_standby_state_events` |
| `getSerialNumber` / `tapDidReadSerialNumber` callback | `device_serial_number` |
| `vibrate(durations:)` | `send_vibration_sequence` / `set_haptic_pattern` |
| Automatic keepalive (built into `start()`) | `KeepAliveManager` |

Unlike the Python SDK (one instance per device), all TAPKit commands accept `forIdentifiers:` for multi-device targeting; pass `nil` to apply to all connected devices.

### Mode control

```swift
TAPKit.sharedKit.enableModes()              // Resume sending input/XR mode to devices
TAPKit.sharedKit.disableModes()             // Pause mode writes
TAPKit.sharedKit.refreshModes()             // Re-send current modes
```

### Background behavior

```swift
TAPKit.sharedKit.sendModeInBackground = false   // default: pause mode updates when app backgrounds
```

When `false`, the SDK switches devices to text mode and user-control XR state on background. When `true`, modes continue to be sent. V2 keepalive messages are sent automatically while the app is active.

### Advanced (BLE extension)

```swift
TAPKit.sharedKit.addParser(characteristicUUID, parser: { identifier, characteristic, data in ... })
TAPKit.sharedKit.addDidWriteParser(characteristicUUID, parser: { identifier, characteristic, value in ... })
TAPKit.sharedKit.read(identifier: uuid, characteristic: cbuuid)
TAPKit.sharedKit.write(identifier: uuid, characteristic: cbuuid, data: data)
TAPKit.sharedKit.getStoredValue(identifier: uuid, characteristic: cbuuid)
TAPKit.sharedKit.isTapInAirGestureState(uuid)
```

Subclass `TAPKit` and override `setupParsers()` or `getHandleConfig()` to customize discovery and parsing.

---

## TAPInputMode

| Factory | Description |
|---------|-------------|
| `TAPInputMode.controller()` | **Default.** Delivers `tapped` / `moused` callbacks with raw finger combinations. |
| `TAPInputMode.text()` | Device acts as a Bluetooth keyboard; SDK tap/mouse callbacks are not fired. |
| `TAPInputMode.controllerWithMouseHID()` | Controller mode plus system mouse HID (Assistive Touch cursor on iOS 13+). |
| `TAPInputMode.controllerWithFullHID()` | Full HID controller mode. |
| `TAPInputMode.tapHold()` | Distinguishes short tap vs. long press via `tapHoldStarted` / `tapHoldEnded`. |
| `TAPInputMode.rawSensor(sensitivity:)` | Streams accelerometer/IMU data via `rawSensorDataReceived`. |
| `TAPInputMode.v2Debug()` | V2 debug stream: enables all V2 features at once (raw IMU + model detection + IMU motion + air-gesture vision stream). Raw packets arrive via `rawSensorDataReceived`. |
| `TAPInputMode.v2Debug(sensitivity:)` | V2 debug with custom sensitivities. |

Newly connected devices receive the default mode set via `setDefaultTAPInputMode(_:immediate:)`.

---

## TAPXRState

Controls TapXR input state (separate from `TAPInputMode`):

| Factory | Description |
|---------|-------------|
| `TAPXRState.userControl()` | User switches between air-mouse and tapping on the device. |
| `TAPXRState.airMouse()` | Force air-mouse mode only. |
| `TAPXRState.tapping()` | Force tapping mode only. |
| `TAPXRState.dontSend()` | Do not send XR state commands. |

```swift
TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.userControl(), applyImmediate: true)
TAPKit.sharedKit.setTAPXRState(TAPXRState.airMouse(), forIdentifiers: ["device-uuid"])
```

`applyImmediate: true` applies the default to already-connected devices.

---

## TAPAirGesture (legacy)

Used with `tapAirGestured` for older Tap Strap air-gesture payloads:

```swift
@objc public enum TAPAirGesture : Int {
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
    // TapXR raw states (prefer tapXRAirGestured for new apps):
    case XRAirGestureNone = 100
    case XRAirGestureThumbIndex = 101
    case XRAirGestureThumbMiddle = 102
    case XRAirGestureThumbRing = 103
    case XRAirGestureThumbPinky = 104
    case XRAirGestureFist = 105
    case XRAirGestureSwipeLeft = 301
    case XRAirGestureSwipeTop = 302
    case XRAirGestureSwipeRight = 303
    case XRAirGestureSwipeBottom = 304
}
```

For new TapXR integrations, prefer **`tapXRAirGestured`** and `TAPXRAirGesture` instead of the XR cases above.

---

## TAPXRAirGesture (TapXR spatial control)

Delivered via `tapXRAirGestured`. The SDK post-processes V2 gesture streams and fuses mouse movement with pinch states for drag/click detection on legacy TapXR paths.

```swift
@objc public enum TAPXRAirGesture : Int {
    case None = 0
    case ClickIndex = 1
    case ClickMiddle = 2
    case ClickRing = 3
    case ClickPinky = 4
    case DragIndex = 5
    case DragMiddle = 6
    case DragRing = 7
    case DragPinky = 8
    case Drop = 9
    case PotentialDragOrClickIndex = 10
    case PotentialDragOrClickMiddle = 11
    case PotentialDragOrClickRing = 12
    case PotentialDragOrClickPinky = 13
    case FistBegin = 14
    case FistEnd = 15
    case SwipeLeft = 17
    case SwipeRight = 18
    case SwipeUp = 19
    case SwipeDown = 20
}
```

Use `gesture.descriptionString()` for debugging.

Spatial control features on TapXR may require authorization from Tap With Us for some firmware builds. [Contact Tap With Us](https://www.tapwithus.com/contact-us/) for access details.

---

## Finger combinations

`combination` in `tapped` is a bitmask from 1–31:

```swift
let fingers: [Bool] = TAPCombination.toFingers(combination)
// fingers[0] = thumb, [1] = index, [2] = middle, [3] = ring, [4] = pinky

let combo = TAPCombination.fromFingers(thumb, index, middle, ring, pinky)
let names = TAPCombination.combinationSpeakableString(for: combination)
```

Bit 0 (LSb) = thumb, bit 4 (MSb) = pinky. Example: `5` (binary `00101`) = thumb + middle.

---

## Raw sensor mode

Streams finger accelerometers and thumb IMU data at ~200 messages/minute.

```swift
let sensitivity = TAPRawSensorSensitivity(
    deviceAccelerometer: 2,
    imuGyro: 2,
    imuAccelerometer: 3
)
TAPKit.sharedKit.setTAPInputMode(TAPInputMode.rawSensor(sensitivity: sensitivity), forIdentifiers: nil)
```

Sensitivity ranges:
- `deviceAccelerometer`: 1–4 (finger accelerometers)
- `imuGyro`: 1–4 (thumb gyro)
- `imuAccelerometer`: 1–5 (thumb accelerometer)

Default sensitivities:

```swift
TAPKit.sharedKit.setTAPInputMode(
    TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity()),
    forIdentifiers: nil
)
```

On V2 devices, IMU sensitivity can also be changed on the fly without re-entering the mode using `setIMUSensitivity(gyro:accelerometer:forIdentifiers:)` — see [V2 device configuration](#v2-device-configuration-v2-devices).

### RawSensorData

```swift
func rawSensorDataReceived(identifier: String, data: RawSensorData) {
    switch data.type {
    case .Device:
        if let thumb = data.getPoint(for: RawSensorData.iDEV_THUMB) {
            print("Thumb accel: (\(thumb.x), \(thumb.y), \(thumb.z))")
        }
        // RawSensorData.iDEV_INDEX, iDEV_MIDDLE, iDEV_RING, iDEV_PINKY
    case .IMU:
        if let gyro = data.getPoint(for: RawSensorData.iIMU_GYRO) {
            print("Gyro: (\(gyro.x), \(gyro.y), \(gyro.z))")
        }
        // RawSensorData.iIMU_ACCELEROMETER
    default:
        break
    }
}
```

[Raw sensor mode documentation](https://tapwithus.atlassian.net/wiki/spaces/TD/pages/792002574/Tap+Strap+Raw+Sensors+Mode)

---

## Logging

```swift
TAPKit.log.enableAllEvents()
TAPKit.log.disableAllEvents()
TAPKit.log.enable(event: .error)
TAPKit.log.disable(event: .warning)
```

Log levels: `.warning`, `.error`, `.info`, `.fatal`.

---

## Project structure

| Target | Purpose |
|--------|---------|
| **TAPKit** | Main SDK framework (`TAPKit-iOS/`) |
| **TAPKit-Example** | Sample iOS app — see `ViewController.swift` for a full integration example |
| **TAPKitUnityBridge** | Objective-C/C++ bridge for Unity games |

Build `TAPKit.framework` from Xcode; do not commit the built framework (it is listed in `.gitignore`).

---

## Example app

Open `TAPKit.xcodeproj`, select the **TAPKit-Example** scheme, and run on a device with a paired TAP. `ViewController.swift` demonstrates delegates, input modes, XR state, haptics, air gestures, and mouse tracking.

---

## Support

Please use the GitHub **Issues** tab for bug reports and questions.
