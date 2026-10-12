---
name: tapkit-getting-started
description: First skill for any TAP iOS app. The order is add TAPKit and NSBluetoothAlwaysUsageDescription, pair the Tap in Settings, addDelegate, setDefaultTAPInputMode (and setDefaultTAPXRState for TapXR), then start(). start() alone delivers no taps. Use for adding the SDK, pairing, connecting, setup, or no tap events.
---

# TAPKit getting started

Works for legacy (v1) and V2 devices. TAPKit detects the protocol per device. The same delegate methods fire for both.

## 1. Ask the user (once)

- Which device: Tap Strap, Tap Strap 2, TapXR, or TapBand?
- Is the Tap turned on, charged, and paired in the iPhone or iPad **Settings → Bluetooth**?
- Is the firmware up to date (update it in the Tap Manager app)?
- UIKit or SwiftUI?

## 2. Add the SDK

This repository ships an Xcode framework, not a Swift package or CocoaPod.

1. Clone https://github.com/TapWithUs/tap-ios-sdk and open `TAPKit.xcodeproj`.
2. Build the **TAPKit** scheme. That produces `TAPKit.framework`.
3. Embed that framework in the app (Embed & Sign).
4. `import TAPKit` in Swift. In Objective-C, `#import <TAPKit/TAPKit-Swift.h>`.

`Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Bluetooth is required to connect to TAP devices.</string>
```

If the deployment target is below iOS 13, also add `NSBluetoothPeripheralUsageDescription`.

The SDK only connects to TAP devices already paired in Settings. It does not scan and it has no pairing screen.

## 3. Connect and listen

Copy [scripts/QuickstartViewController.swift](scripts/QuickstartViewController.swift) into the app target. The required order is:

1. `addDelegate`. Implement `TAPKitDelegate` (every method is optional).
2. `setDefaultTAPInputMode(.controller(), immediate: true)`. Text mode types on the keyboard and sends **no** tap callbacks.
3. For TapXR, `setDefaultTAPXRState`. `.tapping()` for finger taps, `.airMouse()` for pointer and air gestures.
4. `start()` once, from the main screen. Calling `start()` again is safe (`resume()` starts only if needed).
5. Remove the delegate in `viewWillDisappear` or `deinit`.

`forIdentifiers: nil` applies a command to every connected device. Otherwise pass the UUID strings from `tapConnected` or `getConnectedTaps()`.

## 4. What each device sends

| You want | What to set | Callback |
|----------|-------------|----------|
| Finger taps | `.controller()` and, on TapXR, `.tapping()` | `tapped(identifier:combination:multitap:)` |
| Air mouse | `.controller()` and `.airMouse()` | `moused(identifier:velocityX:velocityY:isMouse:)` |
| V2 swipes, pinch, fist | `.airMouse()`, or set the air-gesture vision model (see `tapkit-air-gestures`) | `tapXRAirGestured` |
| Legacy strap air gestures | Controller mode | `tapAirGestured` |
| Raw IMU | `TAPInputMode.rawSensor(sensitivity:)` | `rawSensorDataReceived` |

V2 devices that are not TapXR (hardware version below 40000, including TapBand) do not receive a vision model from `TAPXRState`. After `tapConnected`, enable input directly:

```swift
TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: [identifier])
TAPKit.sharedKit.setVisionSensorModel(.tapping, forIdentifiers: [identifier])
TAPKit.sharedKit.setVisionSensorOpMode(.trigger, forIdentifiers: [identifier])
```

## 5. Callback rules

- Delegate methods run on the main queue. Update UI directly. Do not do heavy work or block.
- `vibrate(durations:forIdentifiers:)` gives haptic feedback. Values are on/pause milliseconds, 10 ms steps, at most 18 values.
- Battery, firmware, and hardware version are read on connect and also via `readBatteryLevel`, `readFirmwareVersion`, and `readHardwareVersion`. Results come back through the matching `tapDidRead*` methods. Versions are integers `MMmmbb` (`30200` = 3.2.0).
- Logs: `TAPKit.log.disableAllEvents()`, or `TAPKit.log.enable(event: .error)`.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Nothing connects | Turn the Tap on, pair it in Settings → Bluetooth, force-quit Tap Manager and any other app using it, then reopen this app. |
| `tapConnected` fires but `tapped` does not (text mode) | Set `TAPInputMode.controller()`. Text mode types letters and hides taps from the SDK. |
| Connected V2 device, still no taps | Enable `.modelDetection`, then `setVisionSensorModel(.tapping)` and `setVisionSensorOpMode(.trigger)`. On TapXR, `setTAPXRState(.tapping())` does this when hardware version is ≥ 40000. |
| Letters appear in a text field when tapping | The device is in text mode. Switch to controller mode. |
| Bluetooth permission alert never appears | Add `NSBluetoothAlwaysUsageDescription`, then delete and reinstall the app. |
| Events stop in the background | Default behavior switches the device to text mode when the app resigns active. Set `TAPKit.sharedKit.sendModeInBackground = true` to keep the mode. |
| A V2 getter completion is `nil` | The device is legacy, it did not answer within `timeout` (default 2 s), or another get of the same kind replaced this one. |

## More

- API reference: `README.md` in the SDK repository
- Working sample: `TAPKit-Example/ViewController.swift`
- Next skills: `tapkit-tapping`, `tapkit-air-gestures`, `tapkit-motion`, `tapkit-raw-sensors`, `tapkit-knob`, `tapkit-dpad`, `tapkit-build-an-app`
