# TAP iOS SDK

Connect order, every time: add TAPKit and `NSBluetoothAlwaysUsageDescription`, pair the Tap in Settings → Bluetooth, `addDelegate`, `setDefaultTAPInputMode` (and `setDefaultTAPXRState` for TapXR and TapBand), then `start()`. `start()` alone delivers no taps.

> Repo: https://github.com/TapWithUs/tap-ios-sdk
> Skills: https://github.com/TapWithUs/tap-ios-sdk/tree/master/plugins/tapkit-ios-sdk/skills
> API: `README.md` in this repository. Example: `TAPKit-Example/ViewController.swift`

Native iOS framework for Tap Strap, Tap Strap 2, TapXR, and TapBand. It receives taps, air gestures, mouse movement, and raw sensor data, and sends haptics and mode commands. Swift, with Objective-C interoperability. One entry point: `TAPKit.sharedKit`.

## Devices

Write one delegate. TAPKit selects the BLE adapter when the device connects.

- **Tap Strap / Tap Strap 2**: finger taps, mouse, Tap Strap air gestures (`tapAirGestured`).
- **TapXR**: current developer firmware reports the **full** gesture set: taps, thumb swipes up/down/left/right, thumb-to-finger pinches with hold, fist with hold. Same BLE API as TapBand.
- **TapBand**: coming soon. Same BLE API as TapXR. Not for sale. Waitlist: https://www.tapwithus.com/tapband-waitlist/

Do not describe TapBand as unsupported or as a missing target. Do not invent a TapXR firmware version number.

Commands whose types start with `TAPV2` (`TAPV2DeviceFeature`, vision sensor, IMU sensitivity, standby, serial number) apply to TapXR and TapBand. On Tap Strap they are ignored (getters complete with `nil`).

This repository has no `Package.swift` and no podspec. Build the **TAPKit** scheme and embed `TAPKit.framework` (Embed & Sign).

## Required order

```swift
import TAPKit

class TapController: TAPKitDelegate {
    func start() {
        TAPKit.sharedKit.addDelegate(self)                                          // 1. delegate
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)    // 2. input mode
        TAPKit.sharedKit.setDefaultTAPXRState(.tapping(), applyImmediate: true)    // 3. TapXR / TapBand
        TAPKit.sharedKit.start()                                                    // 4. BLE central
    }

    func tapConnected(withIdentifier identifier: String, name: String) { }

    func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
        let fingers = TAPCombination.toFingers(combination) // [0] thumb ... [4] pinky
    }
}
```

The Tap must already be paired in **Settings → Bluetooth**. Required `Info.plist` key: `NSBluetoothAlwaysUsageDescription`. If the deployment target is below iOS 13, also set `NSBluetoothPeripheralUsageDescription`.

## Delegate callbacks

All methods are optional. They run on the main queue. Keep them short; move heavy work off the main queue.

| Callback | Meaning |
|----------|---------|
| `tapConnected` / `tapDisconnected` / `tapFailedToConnect` | Connection lifecycle. `identifier` is the stable UUID string. |
| `tapped(identifier:combination:multitap:)` | Finger tap. `combination` is 1–31. `multitap` is 1–3 when the keyboard multitap state applies. |
| `moused(identifier:velocityX:velocityY:isMouse:)` | Air-mouse deltas. `isMouse == false` is an idle packet. |
| `tapDidChangeOrientation(roll:pitch:yaw:)` | Orientation in degrees. This callback has no device identifier. |
| `tapXRAirGestured(identifier:gesture:)` | iOS processed air-gesture layer (`TAPXRAirGesture`): per-finger click, drag, drop, swipe, fist begin/end. |
| `tapAirGestured(identifier:gesture:)` | Tap Strap air gestures (`TAPAirGesture`). |
| `rawSensorDataReceived(identifier:data:)` | Raw accelerometer / gyro sample, only in raw-sensor or `v2Debug()` mode. |
| `tapDidReadBatteryLevel` / `tapDidReadHardwareVersion` / `tapDidReadFirmwareVersion` / `tapDidReadSerialNumber` | Device info. Versions are `MMmmbb` integers (`30200` = 3.2.0). |
| `tapHoldStarted` / `tapHoldEnded` | Long press. Tap Hold mode only. |
| `tapChangedStandbyState(identifier:isInStandby:)` | Standby transitions. TapXR and TapBand. |

Tap bits: thumb = 1, index = 2, middle = 4, ring = 8, pinky = 16.

## Raw detections vs the iOS processed layer

Every Tap SDK receives the **raw** gesture detections from the sensor (class indexes 100–114: idle, thumb swipes, pinches, pinch-holds, fist, fist-hold). See `tapkit-air-gestures` and `README.md` for the table.

iOS TAPKit **also** post-processes that stream (200 ms cooldown, hold latching, swipe debounce) and delivers **edges** on `tapXRAirGestured`:

```swift
func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture) {
    switch gesture {
    case .ClickIndex: select()
    case .DragIndex: beginHold()
    case .Drop: endHold()
    case .SwipeLeft: goBack()
    case .FistBegin: hideControls()
    case .FistEnd: showControls()
    default: break
    }
}
```

`TAPXRAirGesture.None` is `0`. Do not compare `gesture.rawValue` to the firmware class indexes 100–114.

## Gotchas

- The SDK does not scan. Pair in Settings first, and close other apps that hold the connection (including Tap Manager).
- `TAPInputMode.text()` types into the focused text field and does **not** call `tapped` or `moused`.
- On TapXR and TapBand, controller mode enables model detection and IMU motion. `TAPXRState` selects the vision model (`.tapping()` → tapping model + trigger, `.airMouse()` → air-gesture model + stream). You can also call `setVisionSensorModel` and `setVisionSensorOpMode`.
- `setTAPInputMode` writes `TAPV2DeviceFeature` flags. A later mode change can overwrite a direct `setFeature` call.
- One vision model at a time: `.tapping` with `.trigger`, or `.airGesture` with `.stream`.
- Haptics: `vibrate(durations:forIdentifiers:)`. Values are on/pause milliseconds, 10 ms steps, up to 18 values (each value is sent as `ms/10`, so the useful range is 10–2550).
- By default the SDK switches devices to text mode when the app backgrounds. Set `sendModeInBackground = true` to keep the current mode.
- `getFeature` / `getVisionSensorModel` / `getIMUSensitivity` / `getStandbyState` are Swift-only completion handlers. The `set*` APIs are visible to Objective-C.
- `setIMUSensitivity` takes `TAPIMUGyroSensitivity` and `TAPIMUAcclSensitivity`. Example: `setIMUSensitivity(.dps250, accelerometer: .g2, forIdentifiers: ids)`. Do not pass raw integers. `.dps125` and `.g2` are the lowest ranges (wire byte `1`).
- Do not invent APIs, Bluetooth UUIDs, or enum cases. Check `README.md` and the public types in `TAPKit-iOS/`.
- Update firmware with the Tap Manager app. Test on a real device. There is no simulator.

## Skills

| Skill | Use for |
|-------|---------|
| `tapkit-getting-started` | add the framework, pairing, the connect order, a view-controller template, troubleshooting |
| `tapkit-tapping` | finger combinations, double taps, input modes, haptics |
| `tapkit-air-gestures` | raw firmware detections, iOS processed `TAPXRAirGesture`, Tap Strap `TAPAirGesture`, standby |
| `tapkit-motion` | pointer deltas, roll / pitch / yaw, AssistiveTouch mouse |
| `tapkit-raw-sensors` | raw accelerometer / gyro, `TAPIMUGyroSensitivity` / `TAPIMUAcclSensitivity` / `TAPFingerAcclSensitivity` |
| `tapkit-knob` | pinch-hold + wrist roll to change a value |
| `tapkit-dpad` | swipes, click to select, hold to rotate or drag |
| `tapkit-build-an-app` | complete iOS apps: UIKit or SwiftUI, one interaction at a time |

Skill files live in `plugins/tapkit-ios-sdk/skills/<name>/SKILL.md`. Install them into an app repo with `./install-skills.sh`.

## Contributing to this repository

Only for work on the SDK itself (not for apps that use it):

- Build the **TAPKit** scheme in `TAPKit.xcodeproj`. Do not commit `TAPKit.framework`.
- The canonical integration sample is `TAPKit-Example/ViewController.swift`.
- `.cursor/skills/tapkit-ios-sdk/SKILL.md` is the in-repo reference for agents editing this SDK. The installable app skills live under `plugins/tapkit-ios-sdk/skills/` and are what `install-skills.sh` copies.
- When the public API changes, update `README.md`, `AGENTS.md`, `.cursor/rules/tapkit-ios-sdk.mdc`, and the matching skill.
- Installer check (no Xcode required): `bash tests/check_install_skills.sh`. If `swiftc` is on `PATH`, that script also compiles the knob and D-Pad logic tests.
