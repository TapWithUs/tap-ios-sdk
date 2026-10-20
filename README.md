# TAP iOS SDK

Native iOS framework for Tap Strap, Tap Strap 2, TapXR, and TapBand. TAPKit receives finger taps, air gestures, mouse movement, and raw sensor data, and it sends haptics and mode commands.

TapXR (current developer firmware) and TapBand share the **same BLE API** and the **full** gesture set: taps, thumb swipes up/down/left/right, thumb-to-finger pinches with hold, and fist with hold. TapBand is coming soon and is not for sale; join the [waitlist](https://www.tapwithus.com/tapband-waitlist/). Do not describe TapBand as unsupported or as a missing target. Do not invent a TapXR firmware version number.

Written in Swift with Objective-C interoperability. One entry point: `TAPKit.sharedKit`. The Xcode project also includes **TAPKit-Example** (sample app) and **TAPKitUnityBridge** (Unity wrapper).

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

This repository ships an Xcode framework. There is no `Package.swift` and no podspec. Swift Package Manager and CocoaPods are not how you add TAPKit.

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
        TAPKit.sharedKit.setDefaultTAPXRState(TAPXRState.airMouse(), applyImmediate: true)  // TapXR / TapBand
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

## Devices

Write one delegate. TAPKit selects the BLE adapter when the device connects.

| Device | Status | What you get |
|--------|--------|----------------|
| Tap Strap, Tap Strap 2 | Available | Finger taps, mouse, Tap Strap air gestures (`tapAirGestured`) |
| TapXR | Available. Current developer firmware reports the full gesture set. | Taps, thumb swipes, pinches with hold, fist with hold |
| TapBand | Coming soon. Same BLE API as TapXR. Not for sale. [Waitlist](https://www.tapwithus.com/tapband-waitlist/) | Same as TapXR |

TapXR and TapBand use one framed BLE API (one read/write characteristic pair). Tap Strap uses the classic layout (separate notify characteristics and NUS mode commands). TAPKit translates `TAPInputMode` and `TAPXRState` for both. Commands whose types start with `TAPV2` (`TAPV2DeviceFeature`, vision sensor, IMU sensitivity, standby, serial number) apply to TapXR and TapBand. On Tap Strap they are ignored and getters complete with `nil`.

## AI-assisted development

Install the TAPKit skills into a coding agent, then describe the iOS app you want. The skills know the real order: add the framework, pair in Settings, `addDelegate`, set the input mode, then `start()`. `start()` alone delivers no taps.

The installer writes into the **current folder**. Add `-g` to install for your user, so the skills are available in every project.

| Tool | This folder (default) | Every project (`-g`) |
|------|------------------------|----------------------|
| Claude Code | `.claude/skills/` | `claude plugin install … --scope user` |
| Codex | `.agents/skills/` | `codex plugin add …` |
| Cursor | `.cursor/skills/` + [`.cursor/rules/tapkit-ios-sdk.mdc`](.cursor/rules/tapkit-ios-sdk.mdc) | `~/.cursor/skills/` + `~/.cursor/rules/tapkit-ios-sdk.mdc` |
| Any agent that reads `AGENTS.md` | [`AGENTS.md`](AGENTS.md) | `~/.codex/AGENTS.md` |

From a clone of this repository:

```console
./install-skills.sh claude    # .claude/skills/
./install-skills.sh codex     # .agents/skills/
./install-skills.sh cursor    # .cursor/skills/ and .cursor/rules/
./install-skills.sh agents    # ./AGENTS.md
./install-skills.sh all       # all four, this folder
./install-skills.sh -g all    # all four, every project
```

Without a clone (uses the `master` branch; set `TAP_SDK_REF` to install from another branch):

```console
curl -sL https://raw.githubusercontent.com/TapWithUs/tap-ios-sdk/master/install-skills.sh | bash -s cursor
curl -sL https://raw.githubusercontent.com/TapWithUs/tap-ios-sdk/master/install-skills.sh | bash -s -- -g all
```

`-g claude` and `-g codex` need the `claude` and `codex` commands. The guide those files install is [`AGENTS.md`](AGENTS.md). Skill source lives in [`plugins/tapkit-ios-sdk/skills`](plugins/tapkit-ios-sdk/skills).

| Skill | Use for |
|-------|---------|
| `tapkit-getting-started` | add TAPKit, pairing, connect order, troubleshooting |
| `tapkit-tapping` | finger combinations, double taps, input modes, haptics |
| `tapkit-air-gestures` | raw firmware detections, iOS processed click/drag/swipe/fist, Tap Strap air gestures |
| `tapkit-motion` | pointer deltas, roll / pitch / yaw, AssistiveTouch |
| `tapkit-raw-sensors` | raw accelerometer and gyro, `TAPIMUGyroSensitivity` / `TAPIMUAcclSensitivity` |
| `tapkit-knob` | pinch-hold and twist to change a value |
| `tapkit-dpad` | swipe, select, hold to rotate or drag |
| `tapkit-build-an-app` | a complete iOS app, one interaction at a time |

Agents editing **this** repository also have `.cursor/skills/tapkit-ios-sdk/SKILL.md`. That file stays here; `install-skills.sh` does not copy it into app projects.

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

Every Tap SDK receives **raw** gesture detections from the sensor (class indexes 100–114). iOS TAPKit also exposes a **processed** layer. See [Raw detections and the iOS processed layer](#raw-detections-and-the-ios-processed-layer).

| Callback | Description |
|----------|-------------|
| `tapChangedAirGesturesState(identifier:isInAirGesturesState:)` | Device entered or left air-gesture mode (Tap Strap path). |
| `tapAirGestured(identifier:gesture:)` | Tap Strap air gestures. See [TAPAirGesture](#tapairgesture-tap-strap). |
| `tapXRAirGestured(identifier:gesture:)` | iOS processed edges (click, drag, drop, swipe, fist begin/end). See [TAPXRAirGesture](#tapxrairgesture-ios-processed-layer). |

### Device info

| Callback | Description |
|----------|-------------|
| `tapDidReadHardwareVersion(identifier:hw:)` | Hardware version as integer `MMmmbb` (major, minor, build). Example: `30200` → 3.2.0. |
| `tapDidReadFirmwareVersion(identifier:fw:)` | Same format as hardware version. |
| `tapDidReadBatteryLevel(identifier:batteryLevel:)` | Battery level 0–100. Trigger reads with `readBatteryLevel()`. |
| `tapDidChangeOrientation(roll:pitch:yaw:)` | IMU orientation from mouse data characteristic. |
| `tapDidReadSerialNumber(identifier:serialNumber:)` | Serial number (TapXR and TapBand). Read automatically on connect; trigger again with `readSerialNumber()`. |
| `tapChangedStandbyState(identifier:isInStandby:)` | Device entered or left standby (TapXR and TapBand). |

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

### TapXR state (TapXR and TapBand)

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
TAPKit.sharedKit.readSerialNumber(forIdentifiers: nil)          // TapXR / TapBand; result via tapDidReadSerialNumber
let serial = TAPKit.sharedKit.getSerialNumber(identifier: uuid) // stored value from on-connect read
```

### Device configuration (TapXR and TapBand)

Direct access to framed-protocol primitives, matching the [tap-python-sdk](https://github.com/TapWithUs/tap-python-sdk) `TapSDK2` API. These commands apply to TapXR and TapBand. On Tap Strap they are ignored (a warning is logged) and getters complete with `nil`.

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

#### Vision sensor (TapXR and TapBand)

```swift
TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: [uuid])   // .trigger / .streamOnTrigger / .stream
TAPKit.sharedKit.setVisionSensorModel(.airGesture, forIdentifiers: [uuid]) // .tapping / .airGesture

TAPKit.sharedKit.getVisionSensorOpMode(forIdentifier: uuid) { mode in ... }
TAPKit.sharedKit.getVisionSensorModel(forIdentifier: uuid) { model in ... }
```

#### IMU sensitivity

Use the named enums, not raw integers. Ranges match tap-python-sdk `ImuGyroSensitivity` and `ImuAcclSensitivity`. The enum raw value is the byte written to the device, and it is **1-based**: `.dps125` and `.g2` are sent as `1`.

| `TAPIMUGyroSensitivity` | Wire byte | `TAPIMUAcclSensitivity` | Wire byte |
|-------------------------|-----------|-------------------------|-----------|
| `.dps125` | 1 | `.g2` | 1 |
| `.dps250` | 2 | `.g4` | 2 |
| `.dps500` | 3 | `.g8` | 3 |
| `.dps1000` | 4 | `.g16` | 4 |
| `.dps2000` | 5 | | |

```swift
TAPKit.sharedKit.setIMUSensitivity(.dps250, accelerometer: .g2, forIdentifiers: [uuid])

TAPKit.sharedKit.getIMUSensitivity(forIdentifier: uuid) { (reading: TAPIMUSensitivity?) in
    if let reading = reading {
        print("gyro: \(reading.gyro) (\(reading.gyroWireValue)), xl: \(reading.accelerometer)")
    }
}
```

`setIMUSensitivity(gyro:accelerometer:forIdentifiers:)` still accepts `UInt8` wire codes and is deprecated. Prefer `TAPIMUGyroSensitivity` and `TAPIMUAcclSensitivity`. `getIMUSensitivity(forIdentifier:)` returns `TAPIMUSensitivity?`. The old `(gyro: UInt8, accelerometer: UInt8)?` completion is `getIMUSensitivity(wireValuesFor:timeout:completion:)`.

#### Standby

```swift
TAPKit.sharedKit.setStandbyState(true, forIdentifiers: [uuid])

TAPKit.sharedKit.getStandbyState(forIdentifier: uuid) { isInStandby in ... }
```

Unsolicited standby changes are delivered via the `tapChangedStandbyState(identifier:isInStandby:)` delegate callback.

All getters accept an optional `timeout:` parameter (default 2 seconds, `TAPKit.v2ConfigGetTimeout`); completions run on the main queue. If a second get of the same kind is issued to the same device before the first completes, the first completes with `nil`.

#### Objective-C visibility

The `set*` commands, `readSerialNumber()`, `getSerialNumber(identifier:)`, and the `TAPV2DeviceFeature` / `TAPV2VisionSensorOpMode` / `TAPV2VisionSensorModel` / `TAPIMUGyroSensitivity` / `TAPIMUAcclSensitivity` / `TAPFingerAcclSensitivity` enums are exposed to Objective-C. The `get*` read-back functions use Swift completion handlers with optionals and are available from Swift only.

#### tap-python-sdk equivalents

For teams working across both SDKs, the mapping to [tap-python-sdk](https://github.com/TapWithUs/tap-python-sdk) `TapSDK2` is:

| TAPKit (iOS) | tap-python-sdk (`TapSDK2`) |
|--------------|----------------------------|
| `setFeature` / `getFeature` | `set_feature` / `get_feature` |
| `setVisionSensorOpMode` / `getVisionSensorOpMode` | `set_vision_sensor_op_mode` / `get_vision_sensor_op_mode` |
| `setVisionSensorModel` / `getVisionSensorModel` | `set_vision_sensor_model` / `get_vision_sensor_model` |
| `setIMUSensitivity(.dps125, accelerometer: .g2)` / `getIMUSensitivity` | `set_imu_sensitivity(xl_sensitivity=ImuAcclSensitivity.G2, gyro_sensitivity=ImuGyroSensitivity.DPS125)` / `get_imu_sensitivity` |
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

When `false`, the SDK switches devices to text mode and user-control XR state on background. When `true`, modes continue to be sent. Keepalive messages for TapXR and TapBand are sent automatically while the app is active.

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
| `TAPInputMode.v2Debug()` | Debug stream on TapXR and TapBand: all `TAPV2DeviceFeature` flags plus the air-gesture vision stream. Raw packets arrive via `rawSensorDataReceived`. |
| `TAPInputMode.v2Debug(sensitivity:)` | Same debug stream with custom sensitivities. |

Newly connected devices receive the default mode set via `setDefaultTAPInputMode(_:immediate:)`.

---

## TAPXRState

Controls TapXR / TapBand input state (separate from `TAPInputMode`):

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

## Raw detections and the iOS processed layer

The sensor reports **raw** class indexes. Every Tap SDK receives that stream. Current TapXR developer firmware and TapBand report the full set: taps (via the tapping model), thumb swipes, thumb-to-finger pinches with hold, and fist with hold.

| Index | Label | Meaning |
|-------|-------|---------|
| 100 | `NONE` | idle |
| 101 | `LEFT` | thumb swipe left |
| 102 | `RIGHT` | thumb swipe right |
| 103 | `UP` | thumb swipe up |
| 104 | `DOWN` | thumb swipe down |
| 105 | `AB` | short pinch, thumb + index |
| 106 | `AC` | short pinch, thumb + middle |
| 107 | `AD` | short pinch, thumb + ring |
| 108 | `AE` | short pinch, thumb + pinky |
| 109 | `FIST` | fist |
| 110 | `AB_HOLD` | pinch held, thumb + index |
| 111 | `AC_HOLD` | pinch held, thumb + middle |
| 112 | `AD_HOLD` | pinch held, thumb + ring |
| 113 | `AE_HOLD` | pinch held, thumb + pinky |
| 114 | `FIST_HOLD` | fist held |

There is no `TAPKitDelegate` method for these integers. TAPKit consumes the stream, then emits processed edges.

```swift
// Firmware class indexes. Not TAPXRAirGesture.rawValue (None is 0, not 100).
func rawClassMeaning(_ classIndex: Int) -> String {
    switch classIndex {
    case 101: return "swipe left"
    case 105: return "pinch index"
    case 110: return "hold index"
    case 109: return "fist"
    case 114: return "fist hold"
    case 100: return "idle"
    default: return "unknown"
    }
}
```

**iOS processed layer.** TAPKit post-processes the stream (200 ms cooldown, hold latching, swipe debounce) and delivers `TAPXRAirGesture` on `tapXRAirGestured`. That is the app-facing air-gesture API on iOS.

---

## TAPAirGesture (Tap Strap)

Used with `tapAirGestured` for Tap Strap air-gesture payloads:

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
    // Older XR payload values. Not the firmware class table above,
    // and not TAPXRAirGesture. Prefer tapXRAirGestured for TapXR / TapBand:
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

```swift
func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
    switch gesture {
    case .OneFingerUp: moveUp()
    case .IndexToThumbTouch: select()
    default: break
    }
}
```

---

## TAPXRAirGesture (iOS processed layer)

Delivered via `tapXRAirGestured`. TAPKit post-processes the raw class stream (debounce and hold latching) and fuses mouse movement with pinch states for drag/click detection on some TapXR hardware paths.

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

```swift
func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture) {
    switch gesture {
    case .ClickIndex: select()
    case .DragIndex: beginGrab()
    case .Drop: endGrab()
    case .SwipeLeft: goBack()
    case .FistBegin: hideControls()
    case .FistEnd: showControls()
    default: break
    }
}
```

Use `gesture.descriptionString()` for debugging.

`PotentialDragOrClick*` (10–13) can appear on some TapXR hardware while TAPKit is still deciding click versus drag. Ignore it until a click, drag, or drop arrives. Current developer firmware goes through the processed converter, which emits click, drag, drop, swipe, and fist edges, not the potential cases.

Map from raw class (after post-process): `LEFT`→`SwipeLeft`, `AB`→`ClickIndex`, `AB_HOLD`→`DragIndex` (once), idle after a hold→`Drop` or `FistEnd`.

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
let sensitivity = TAPRawSensorSensitivity(finger: .g4, gyro: .dps250, accelerometer: .g8)
TAPKit.sharedKit.setTAPInputMode(TAPInputMode.rawSensor(sensitivity: sensitivity), forIdentifiers: nil)
```

That writes the same mode command as tap-python-sdk `InputModeRaw(finger_accl_sens=G4, imu_gyro_sens=DPS250, imu_accl_sens=G8)`: `[0x3, 0x0c, 0x00, 0x0a, 2, 2, 3]`.

The three integers are **1-based wire codes**, the same numbers Python's enums use:

| Argument | Enum | Wire codes | Default |
|----------|------|------------|---------|
| `deviceAccelerometer` | `TAPFingerAcclSensitivity` `.g2` `.g4` `.g8` `.g16` | 1–4 | `.g2` (1) |
| `imuGyro` | `TAPIMUGyroSensitivity` `.dps125` … `.dps2000` | 1–5 | `.dps125` (1) |
| `imuAccelerometer` | `TAPIMUAcclSensitivity` `.g2` `.g4` `.g8` `.g16` | 1–4 | `.g2` (1) |

`TAPRawSensorSensitivity()` therefore sends `[1, 1, 1]`, matching Python's `InputModeRaw()` default. Passing `0`, or the old default object, used to send `0`. `0` is now stored and sent as `1`. Integer codes that were already in range (`1...4` / `1...5`) are unchanged, including the scale factor applied when a sample is parsed. Values above the max used to fall back to `0`; they are now clamped to the max. Gyro and IMU-accelerometer scale factors at those indexes match Python. Finger factors stay the more precise values this SDK already used (`3.90625`, `7.8125`, `15.625`, `31.25` mg/LSB) rather than Python's rounded `3.91` / `7.81` / `15.62`.

```swift
TAPKit.sharedKit.setTAPInputMode(
    TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity()),
    forIdentifiers: nil
)
```

On TapXR and TapBand, IMU sensitivity can also be changed on the fly without re-entering the mode using `setIMUSensitivity(_:accelerometer:forIdentifiers:)` — see [Device configuration](#device-configuration-tapxr-and-tapband). Finger-accelerometer range is part of the classic raw-mode command only. The IMU sensitivity frame on TapXR and TapBand carries gyro and IMU accelerometer, same as Python's `set_imu_sensitivity`.

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
| **Agent skills** | [`plugins/tapkit-ios-sdk/skills`](plugins/tapkit-ios-sdk/skills), installed with [`install-skills.sh`](install-skills.sh). [`AGENTS.md`](AGENTS.md) is the short guide. |

Build `TAPKit.framework` from Xcode; do not commit the built framework (it is listed in `.gitignore`). There is no Swift Package and no CocoaPod in this repository.

---

## Example app

Open `TAPKit.xcodeproj`, select the **TAPKit-Example** scheme, and run on a device with a paired TAP. `ViewController.swift` demonstrates delegates, input modes, XR state, haptics, air gestures, and mouse tracking. The Knob / D-Pad screen (`GestureSampleViewController`) uses the processed `tapXRAirGestured` layer.

---

## Support

Please use the GitHub **Issues** tab for bug reports and questions.
