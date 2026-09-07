---
name: tapkit-ios-sdk
description: >-
  Integrate and use TAPKit, the TAP iOS SDK, to receive input from TAP
  Bluetooth devices (Tap Strap, TapXR, TapBand): finger-tap combinations,
  air-mouse movement, air gestures, raw sensor streams, haptics, and V2 device
  configuration. Use when writing iOS/Swift/Objective-C code against TAPKit,
  implementing TAPKitDelegate, setting TAPInputMode or TAPXRState, decoding
  tap combinations, or working with TAP devices in this repository.
---

# Using TAPKit (TAP iOS SDK)

TAPKit is a Swift framework (Objective-C compatible) for receiving input from TAP wearable devices over BLE. This skill is the quick reference; the full API documentation lives in [README.md](../../../README.md) and a complete working integration is in `TAPKit-Example/TAPKit-Example/ViewController.swift`.

## Core concepts

- **Singleton**: all APIs go through `TAPKit.sharedKit`. Call `start()` once when the app's main screen appears.
- **Delegates**: implement `TAPKitDelegate` (all methods optional, multiple delegates supported). Add with `addDelegate(_:)`, remove in `viewWillDisappear`/deinit.
- **No scan UI**: the SDK only connects to TAP devices already paired in iOS Settings → Bluetooth.
- **Device identifiers**: every callback carries an `identifier` (stable UUID string). Commands take `forIdentifiers: [String]?` — pass `nil` to target all connected devices.
- **Two BLE protocols**: legacy (v1: Tap Strap 1/2, older TapXR) and V2 "framed" (TapBand, newer TapXR). TAPKit auto-detects per device; the same delegate callbacks and mode APIs work on both. APIs marked "V2 devices" are ignored on legacy hardware (getters complete with `nil`).

## Minimal integration

Required `Info.plist` entry: `NSBluetoothAlwaysUsageDescription`.

```swift
import TAPKit

class MyViewController: UIViewController, TAPKitDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        TAPKit.sharedKit.addDelegate(self)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.airMouse(), applyImmediate: true) // TapXR only
        TAPKit.sharedKit.start()
    }

    func tapConnected(withIdentifier identifier: String, name: String) { }

    func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
        let fingers = TAPCombination.toFingers(combination)
        // fingers[0]=thumb ... fingers[4]=pinky
    }
}
```

## Choosing an input mode

Set per device with `setTAPInputMode(_:forIdentifiers:)` or as the default for new connections with `setDefaultTAPInputMode(_:immediate:)`.

| Goal | Mode |
|------|------|
| Receive tap combinations + mouse in the app (default) | `TAPInputMode.controller()` |
| Let device act as a system Bluetooth keyboard (no SDK callbacks) | `TAPInputMode.text()` |
| Controller + system mouse cursor (AssistiveTouch) | `TAPInputMode.controllerWithMouseHID()` |
| Distinguish tap vs. long press | `TAPInputMode.tapHold()` → `tapHoldStarted`/`tapHoldEnded` |
| Stream raw accelerometer/IMU data | `TAPInputMode.rawSensor(sensitivity:)` → `rawSensorDataReceived` |
| V2 debug: all streams at once | `TAPInputMode.v2Debug()` |

For TapXR devices there is a separate axis, `TAPXRState`: `.userControl()` (user toggles on device), `.airMouse()`, `.tapping()`, or `.dontSend()`. Set via `setTAPXRState(_:forIdentifiers:)` / `setDefaultTAPXRState(_:applyImmediate:)`.

## Key delegate callbacks

| Callback | Meaning |
|----------|---------|
| `tapConnected(withIdentifier:name:)` / `tapDisconnected` / `tapFailedToConnect` | Connection lifecycle |
| `tapped(identifier:combination:multitap:)` | Finger tap; `combination` is a 5-bit bitmask (bit 0 = thumb … bit 4 = pinky, values 1–31) |
| `moused(identifier:velocityX:velocityY:isMouse:)` | Air-mouse movement; `isMouse == false` means idle packet |
| `tapAirGestured` (legacy) / `tapXRAirGestured` (TapXR spatial: pinch/drag/swipe/fist) | Air gestures; prefer `tapXRAirGestured` for new TapXR code |
| `rawSensorDataReceived(identifier:data:)` | Raw sensor stream (in rawSensor/v2Debug modes) |
| `tapDidReadBatteryLevel` / `tapDidReadHardwareVersion` / `tapDidReadFirmwareVersion` / `tapDidReadSerialNumber` | Device info (versions are `MMmmbb` integers, e.g. `30200` = 3.2.0) |
| `tapHoldStarted` / `tapHoldEnded` | Long press (Tap Hold mode only) |
| `tapChangedStandbyState(identifier:isInStandby:)` | Standby transitions (V2 devices) |

## Decoding tap combinations

```swift
let fingers = TAPCombination.toFingers(combination)        // [Bool] thumb→pinky
let combo = TAPCombination.fromFingers(t, i, m, r, p)      // build a bitmask
let names = TAPCombination.combinationSpeakableString(for: combination)
```

Example: `combination == 5` (binary `00101`) = thumb + middle.

## Common commands

```swift
TAPKit.sharedKit.getConnectedTaps()                          // [identifier: name]
TAPKit.sharedKit.vibrate(durations: [500, 100, 500], forIdentifiers: nil) // ms on/pause pairs
TAPKit.sharedKit.readBatteryLevel(forIdentifiers: nil)       // result via delegate
```

## V2 device configuration (V2 devices only)

Fine-grained control matching tap-python-sdk `TapSDK2`. Getters take an optional `timeout:` (default 2 s) and complete on the main queue with `nil` on timeout or on legacy devices.

```swift
TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: [uuid])
TAPKit.sharedKit.getFeature(.modelDetection, forIdentifier: uuid) { enabled in ... }
TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: [uuid])      // TapXR
TAPKit.sharedKit.setIMUSensitivity(gyro: 2, accelerometer: 1, forIdentifiers: [uuid])
TAPKit.sharedKit.setStandbyState(true, forIdentifiers: [uuid])
```

Features (`TAPV2DeviceFeature`): `.rawIMUData`, `.modelDetection`, `.imuMotionData`, `.triggerDetections` (reserved), `.standbyGestureDetection`.

Note: `setTAPInputMode` also writes these features under the hood, so a later mode change can overwrite direct feature writes.

## Pitfalls

- The TAP device must be paired in iOS Settings first; the SDK does not scan or pair.
- In `text()` mode, `tapped`/`moused` callbacks do NOT fire (device behaves as a keyboard).
- `moused` velocities need app-side scaling for sensitivity.
- By default the SDK switches devices to text mode when the app backgrounds; set `TAPKit.sharedKit.sendModeInBackground = true` to keep modes active.
- Raw sensor sensitivity ranges: `deviceAccelerometer` 1–4, `imuGyro` 1–4, `imuAccelerometer` 1–5.
- V2 `get*` read-back APIs are Swift-only (completion handlers with optionals); the `set*` APIs are exposed to Objective-C.
- Suppress SDK logs with `TAPKit.log.disableAllEvents()`; enable per level with `TAPKit.log.enable(event: .error)`.

## Repository layout

| Path | Purpose |
|------|---------|
| `TAPKit-iOS/` | SDK source (framework target **TAPKit**) |
| `TAPKit-iOS/TAPKit/TAPKit.swift` | Main public API surface |
| `TAPKit-iOS/Protocol/` | Legacy (v1) and V2 protocol adapters |
| `TAPKit-Example/` | Sample app; `ViewController.swift` is the canonical integration example |
| `TAPKitUnityBridge/` | Objective-C/C++ bridge for Unity |

Build the **TAPKit** scheme in `TAPKit.xcodeproj` to produce `TAPKit.framework`; do not commit the built framework.

## Full reference

- Complete API docs, enum values (`TAPAirGesture`, `TAPXRAirGesture`), raw sensor details, and the tap-python-sdk mapping table: [README.md](../../../README.md)
- Working example of delegates, modes, XR state, haptics: `TAPKit-Example/TAPKit-Example/ViewController.swift`
