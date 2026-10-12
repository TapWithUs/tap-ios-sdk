# TAP iOS SDK

Connect order, every time: add TAPKit and `NSBluetoothAlwaysUsageDescription`, pair the Tap in Settings → Bluetooth, `addDelegate`, `setDefaultTAPInputMode` (and `setDefaultTAPXRState` for TapXR), then `start()`. `start()` alone delivers no taps.

> Repo: https://github.com/TapWithUs/tap-ios-sdk
> Skills: https://github.com/TapWithUs/tap-ios-sdk/tree/master/plugins/tapkit-ios-sdk/skills
> API: `README.md` in this repository. Example: `TAPKit-Example/ViewController.swift`

Native iOS framework for Tap Strap, Tap Strap 2, TapXR, and TapBand. It receives taps, air gestures, mouse movement, and raw sensor data, and sends haptics and mode commands. Swift, with Objective-C interoperability.

## One entry point, two protocols

`TAPKit.sharedKit` is the only API. On connect the SDK detects the firmware protocol per device:

- **Legacy (v1)**: Tap Strap, Tap Strap 2, older TapXR. Input modes (`TAPInputMode`) and, on TapXR, `TAPXRState`.
- **V2 (framed)**: TapBand, newer TapXR. The same delegate callbacks and mode APIs, plus device features, vision-sensor model, standby, and serial number.

There is no separate client class to branch on. Write one delegate. APIs marked V2-only are ignored on legacy hardware (getters complete with `nil`).

## Required order

```swift
import TAPKit

class TapController: TAPKitDelegate {
    func start() {
        TAPKit.sharedKit.addDelegate(self)                                          // 1. delegate
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)    // 2. input mode
        TAPKit.sharedKit.setDefaultTAPXRState(.tapping(), applyImmediate: true)    // 3. TapXR only
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
| `tapXRAirGestured(identifier:gesture:)` | V2 / TapXR spatial gestures (`TAPXRAirGesture`): click, drag, drop, swipe, fist. |
| `tapAirGestured(identifier:gesture:)` | Legacy strap air gestures (`TAPAirGesture`). |
| `rawSensorDataReceived(identifier:data:)` | Raw sensor sample, only in raw-sensor or V2-debug mode. |
| `tapDidReadBatteryLevel` / `tapDidReadHardwareVersion` / `tapDidReadFirmwareVersion` / `tapDidReadSerialNumber` | Device info. Versions are `MMmmbb` integers (`30200` = 3.2.0). |
| `tapHoldStarted` / `tapHoldEnded` | Long press. Tap Hold mode only. |
| `tapChangedStandbyState(identifier:isInStandby:)` | Standby transitions. V2 devices. |

Tap bits: thumb = 1, index = 2, middle = 4, ring = 8, pinky = 16.

## Gotchas

- The SDK does not scan. Pair in Settings first, and close other apps that hold the connection (including Tap Manager).
- `TAPInputMode.text()` types into the focused text field and does **not** call `tapped` or `moused`.
- On V2, controller mode enables model detection and IMU motion. A TapXR with hardware version ≥ 40000 also gets a vision model from `TAPXRState` (`.tapping()` → tapping model + trigger, `.airMouse()` → air-gesture model + stream). Other V2 devices need `setVisionSensorModel` and `setVisionSensorOpMode` explicitly or they may stay silent.
- `setTAPInputMode` writes V2 features itself. A later mode change can overwrite a direct `setFeature` call.
- V2 runs one vision model at a time: `.tapping` with `.trigger`, or `.airGesture` with `.stream`.
- `tapXRAirGestured` is an edge (click, drag start, drop, swipe, fist begin/end). It is not the repeating raw model code stream. Do not look for codes 100–114; those are not the app-facing enum.
- Haptics: `vibrate(durations:forIdentifiers:)`. Values are on/pause milliseconds, 10 ms steps, up to 18 values (each value is sent as `ms/10`, so the useful range is 10–2550).
- By default the SDK switches devices to text mode when the app backgrounds. Set `sendModeInBackground = true` to keep the current mode.
- V2 `get*` read-backs are Swift-only completion handlers. The `set*` APIs are visible to Objective-C.
- IMU sensitivity wire codes are 1-based, matching tap-python-sdk: `TAPIMUGyroSensitivity.dps125` and `TAPIMUAcclSensitivity.g2` are sent as `1`. Use `setIMUSensitivity(_:accelerometer:)`. Do not send `0`.
- Do not invent APIs, Bluetooth UUIDs, or enum cases. Check `README.md` and the public types in `TAPKit-iOS/`.
- Update firmware with the Tap Manager app. Test on a real device. There is no simulator.

## Skills

| Skill | Use for |
|-------|---------|
| `tapkit-getting-started` | add the framework, pairing, the connect order, a view-controller template, troubleshooting |
| `tapkit-tapping` | finger combinations, double taps, input modes, haptics |
| `tapkit-air-gestures` | V2 model switching, `TAPXRAirGesture`, legacy `TAPAirGesture`, standby |
| `tapkit-motion` | pointer deltas, roll / pitch / yaw, AssistiveTouch mouse |
| `tapkit-raw-sensors` | raw accelerometer / gyro, sensitivity |
| `tapkit-knob` | V2 pinch-hold + wrist roll to change a value |
| `tapkit-dpad` | V2 swipes, click to select, hold to rotate or drag |
| `tapkit-build-an-app` | complete iOS apps: UIKit or SwiftUI, one interaction at a time |

Skill files live in `plugins/tapkit-ios-sdk/skills/<name>/SKILL.md`. Install them into an app repo with `./install-skills.sh`.

## Contributing to this repository

Only for work on the SDK itself (not for apps that use it):

- Build the **TAPKit** scheme in `TAPKit.xcodeproj`. Do not commit `TAPKit.framework`.
- The canonical integration sample is `TAPKit-Example/ViewController.swift`.
- `.cursor/skills/tapkit-ios-sdk/SKILL.md` is the in-repo reference for agents editing this SDK. The installable app skills live under `plugins/tapkit-ios-sdk/skills/` and are what `install-skills.sh` copies.
- When the public API changes, update `README.md`, `AGENTS.md`, `.cursor/rules/tapkit-ios-sdk.mdc`, and the matching skill.
- Installer check (no Xcode required): `bash tests/check_install_skills.sh`. If `swiftc` is on `PATH`, that script also compiles the knob and D-Pad logic tests.
