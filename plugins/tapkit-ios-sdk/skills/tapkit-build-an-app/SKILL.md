---
name: tapkit-build-an-app
description: Build a complete iOS app or interactive experience controlled by a TAP device. Use when the user asks to build, make, or create something with their Tap, including games, presentations, media control, or creative tools.
---

# Build an iOS app with a TAP

The user may not be a developer. Keep the project small, explain how to run it in Xcode in plain words, and test with the real device. There is no TAP simulator.

## Workflow

1. **Ask** only what is missing: device (Tap Strap, Tap Strap 2, TapXR, or TapBand), UIKit or SwiftUI, and what the app should do. TapBand is coming soon, same BLE API as TapXR, not for sale: https://www.tapwithus.com/tapband-waitlist/ — still build against that API.
2. **Connect first.** Use `tapkit-getting-started`. Confirm `tapped` prints a combination before building anything else.
3. **Pick the input** and load that skill:
   - finger taps and combos: `tapkit-tapping`
   - swipes, pinches, fist: `tapkit-air-gestures` (TapXR / TapBand processed layer)
   - pointer, tilt, rotation: `tapkit-motion`
   - twist-to-adjust value: `tapkit-knob`
   - directions, select, drag or rotate: `tapkit-dpad`
   - data recording: `tapkit-raw-sensors`
4. **Pick the output** from the table below.
5. **Build one interaction, have the user try it, then add the next.**
6. **Give feedback:** `vibrate(durations:)` and something on screen, so the user knows the gesture was seen.
7. **Deliver** an Xcode project that builds the app with TAPKit embedded. Tell the user to select their iPhone, trust the developer certificate, pair the Tap in Settings, and press Run.

## Core pattern

Delegate methods already run on the main queue. Update UI in them. Do not parse, log, or compute a model there if it takes more than a moment; hop to a background queue and come back to the main queue to draw.

```swift
final class TapSession: TAPKitDelegate {
    var onTap: ((UInt8) -> Void)?

    func start() {
        TAPKit.sharedKit.addDelegate(self)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(.tapping(), applyImmediate: true)
        TAPKit.sharedKit.start()
    }

    func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
        onTap?(combination)
    }
}
```

SwiftUI: own a `TapSession` on an `ObservableObject`, publish the latest event, and render from that. The delegate is still a class. Do not make the SwiftUI view itself the delegate unless it is a `UIViewController`.

## Output patterns

| Output | How |
|--------|-----|
| On-screen UI | UIKit views or SwiftUI. Show "Waiting…", "Connected", "Disconnected". |
| The Tap types letters | `TAPInputMode.text()` while a text field is focused. The delegate will not see those taps. |
| System cursor | `TAPInputMode.controllerWithMouseHID()` and AssistiveTouch (iOS 13+). |
| Sound | `AVAudioEngine` or a short `AVAudioPlayer` in the app bundle. |
| Another app | Not from this SDK. iOS apps do not inject global key presses. |

Add on-screen buttons that perform the same actions as the taps, so the UI can be tried without a device.

## Rules

- Do not modify TAPKit to make an app work. Call the public API in `README.md`.
- Do not add CocoaPods, SwiftPM, or Carthage instructions. This SDK is an embedded `TAPKit.framework` (build the TAPKit scheme, then Embed & Sign). There is no `Package.swift` or podspec.
- Do not invent enum cases, Bluetooth UUIDs, or a scanning API.
- Pairing happens in Settings → Bluetooth before launch.
- If the device does not connect or taps do not arrive, use the troubleshooting table in `tapkit-getting-started`.
- Unity games in this repository use `TAPKitUnityBridge`, which is a separate C callback surface. A normal iOS app should use `TAPKitDelegate`, not the Unity bridge.
