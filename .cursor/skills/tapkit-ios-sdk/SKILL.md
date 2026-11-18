---
name: tapkit-ios-sdk
description: >-
  Integrate and use TAPKit, the TAP iOS SDK, to receive input from TAP
  Bluetooth devices (Tap Strap, TapXR, TapBand): finger-tap combinations,
  air-mouse movement, air gestures, raw sensor streams, haptics, and
  TapXR / TapBand device configuration. Use when writing iOS/Swift/Objective-C
  code against TAPKit, implementing TAPKitDelegate, setting TAPInputMode or
  TAPXRState, decoding tap combinations, or working with TAP devices in this
  repository.
---

# Using TAPKit (TAP iOS SDK)

TAPKit is a Swift framework (Objective-C compatible) for receiving input from TAP wearable devices over BLE. This skill is the quick reference for agents working **in this repository**. The full API documentation lives in [README.md](../../../README.md) and a complete working integration is in `TAPKit-Example/ViewController.swift`.

App-building skills (getting started, tapping, air gestures, motion, raw sensors, knob, D-Pad) live in `plugins/tapkit-ios-sdk/skills/` and are what [`install-skills.sh`](../../../install-skills.sh) copies into other projects. The connect order those skills teach: add the framework and `NSBluetoothAlwaysUsageDescription`, pair in Settings, `addDelegate`, `setDefaultTAPInputMode` (and `setDefaultTAPXRState` for TapXR and TapBand), then `start()`.

## Core concepts

- **Singleton**: all APIs go through `TAPKit.sharedKit`. Call `start()` once when the app's main screen appears.
- **Delegates**: implement `TAPKitDelegate` (all methods optional, multiple delegates supported). Add with `addDelegate(_:)`, remove in `viewWillDisappear`/deinit.
- **No scan UI**: the SDK only connects to TAP devices already paired in iOS Settings → Bluetooth.
- **Device identifiers**: every callback carries an `identifier` (stable UUID string). Commands take `forIdentifiers: [String]?` — pass `nil` to target all connected devices.
- **Devices**: Tap Strap / Tap Strap 2, TapXR, and TapBand. TapXR (current developer firmware) and TapBand share the **same BLE API** and the full gesture set (taps, thumb swipes, pinches with hold, fist with hold). TapBand is coming soon, not for sale: https://www.tapwithus.com/tapband-waitlist/ — never call it unsupported. TAPKit selects the BLE adapter per device. Commands whose types start with `TAPV2` are ignored on Tap Strap (getters complete with `nil`).
- **No package manager**: there is no `Package.swift` or podspec. Build the **TAPKit** scheme and embed `TAPKit.framework`.

## Minimal integration

Required `Info.plist` entry: `NSBluetoothAlwaysUsageDescription`.

```swift
import TAPKit

class MyViewController: UIViewController, TAPKitDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        TAPKit.sharedKit.addDelegate(self)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.airMouse(), applyImmediate: true) // TapXR / TapBand
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
| Debug: all streams at once (TapXR / TapBand) | `TAPInputMode.v2Debug()` |

For TapXR and TapBand there is a separate axis, `TAPXRState`: `.userControl()` (user toggles on device), `.airMouse()`, `.tapping()`, or `.dontSend()`. Set via `setTAPXRState(_:forIdentifiers:)` / `setDefaultTAPXRState(_:applyImmediate:)`.

## Key delegate callbacks

| Callback | Meaning |
|----------|---------|
| `tapConnected(withIdentifier:name:)` / `tapDisconnected` / `tapFailedToConnect` | Connection lifecycle |
| `tapped(identifier:combination:multitap:)` | Finger tap; `combination` is a 5-bit bitmask (bit 0 = thumb … bit 4 = pinky, values 1–31) |
| `moused(identifier:velocityX:velocityY:isMouse:)` | Air-mouse movement; `isMouse == false` means idle packet |
| `tapAirGestured` (Tap Strap) / `tapXRAirGestured` (iOS processed layer: pinch/drag/swipe/fist) | Air gestures; prefer `tapXRAirGestured` for TapXR and TapBand |
| `rawSensorDataReceived(identifier:data:)` | Raw sensor stream (in rawSensor/`v2Debug()` modes) |
| `tapDidReadBatteryLevel` / `tapDidReadHardwareVersion` / `tapDidReadFirmwareVersion` / `tapDidReadSerialNumber` | Device info (versions are `MMmmbb` integers, e.g. `30200` = 3.2.0) |
| `tapHoldStarted` / `tapHoldEnded` | Long press (Tap Hold mode only) |
| `tapChangedStandbyState(identifier:isInStandby:)` | Standby transitions (TapXR and TapBand) |

## Decoding tap combinations

```swift
let fingers = TAPCombination.toFingers(combination)        // [Bool] thumb→pinky
let combo = TAPCombination.fromFingers(t, i, m, r, p)      // build a bitmask
let names = TAPCombination.combinationSpeakableString(for: combination)
```

Example: `combination == 5` (binary `00101`) = thumb + middle.

## Raw detections vs processed air gestures

The sensor sends class indexes 100–114 (idle, swipes, pinches, holds, fist). Every Tap SDK receives that stream. iOS TAPKit post-processes it (200 ms cooldown, hold latching) into `TAPXRAirGesture` edges on `tapXRAirGestured`. `TAPXRAirGesture.None` is `0`; do not switch on 100–114 in that callback. Full table: `plugins/tapkit-ios-sdk/skills/tapkit-air-gestures/SKILL.md`.

```swift
func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture) {
    switch gesture {
    case .ClickIndex: select()
    case .DragIndex: beginHold()
    case .Drop: endHold()
    case .SwipeLeft: goBack()
    case .FistBegin: hide()
    case .FistEnd: show()
    default: break
    }
}
```

## Common commands

```swift
TAPKit.sharedKit.getConnectedTaps()                          // [identifier: name]
TAPKit.sharedKit.vibrate(durations: [500, 100, 500], forIdentifiers: nil) // ms on/pause pairs
TAPKit.sharedKit.readBatteryLevel(forIdentifiers: nil)       // result via delegate
```

## Device configuration (TapXR and TapBand)

Fine-grained control matching tap-python-sdk `TapSDK2`. Getters take an optional `timeout:` (default 2 s) and complete on the main queue with `nil` on timeout or on Tap Strap.

```swift
TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: [uuid])
TAPKit.sharedKit.getFeature(.modelDetection, forIdentifier: uuid) { enabled in ... }
TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: [uuid])
TAPKit.sharedKit.setIMUSensitivity(.dps250, accelerometer: .g2, forIdentifiers: [uuid])
TAPKit.sharedKit.setStandbyState(true, forIdentifiers: [uuid])
```

Features (`TAPV2DeviceFeature`): `.rawIMUData`, `.modelDetection`, `.imuMotionData`, `.triggerDetections` (reserved), `.standbyGestureDetection`.

Note: `setTAPInputMode` also writes these features under the hood, so a later mode change can overwrite direct feature writes.

## Pitfalls

- The TAP device must be paired in iOS Settings first; the SDK does not scan or pair.
- In `text()` mode, `tapped`/`moused` callbacks do NOT fire (device behaves as a keyboard).
- `moused` velocities need app-side scaling for sensitivity.
- By default the SDK switches devices to text mode when the app backgrounds; set `TAPKit.sharedKit.sendModeInBackground = true` to keep modes active.
- Sensitivity wire codes are 1-based, matching tap-python-sdk: finger `.g2`…`.g16` = 1…4, gyro `.dps125`…`.dps2000` = 1…5, IMU accelerometer `.g2`…`.g16` = 1…4. Default `TAPRawSensorSensitivity()` sends `[1, 1, 1]`. Pass `TAPIMUGyroSensitivity` / `TAPIMUAcclSensitivity` / `TAPFingerAcclSensitivity`, not raw integers.
- `get*` read-back APIs are Swift-only (completion handlers with optionals); the `set*` APIs are exposed to Objective-C.
- Suppress SDK logs with `TAPKit.log.disableAllEvents()`; enable per level with `TAPKit.log.enable(event: .error)`.

## Repository layout

| Path | Purpose |
|------|---------|
| `TAPKit-iOS/` | SDK source (framework target **TAPKit**) |
| `TAPKit-iOS/TAPKit/TAPKit.swift` | Main public API surface |
| `TAPKit-iOS/Protocol/` | BLE protocol adapters |
| `TAPKit-Example/` | Sample app; `ViewController.swift` is the canonical integration example |
| `plugins/tapkit-ios-sdk/skills/` | Installable app-building skills (`install-skills.sh`) |
| `AGENTS.md` | Short guide for coding agents. The installer strips the contributing section when copying it into an app. |
| `TAPKitUnityBridge/` | Objective-C/C++ bridge for Unity |

Build the **TAPKit** scheme in `TAPKit.xcodeproj` to produce `TAPKit.framework`; do not commit the built framework.

## Full reference

- Complete API docs, enum values (`TAPAirGesture`, `TAPXRAirGesture`), raw sensor details, and the tap-python-sdk mapping table: [README.md](../../../README.md)
- Working example of delegates, modes, XR state, haptics: `TAPKit-Example/ViewController.swift`
