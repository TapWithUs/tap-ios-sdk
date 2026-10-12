---
name: tapkit-air-gestures
description: Switch a V2 Tap between tapping and air-gesture models and handle TAPXRAirGesture (swipe, click, drag, drop, fist). Use for air gestures, pinch, swipe, fist, model switching, TAPXRState, or legacy TAPAirGesture.
---

# Air gestures and vision models

V2 model switching applies to TapBand and newer TapXR. Legacy strap air gestures are at the end of this page.

The V2 device runs one vision model at a time:

| Model | Output | Callback |
|-------|--------|----------|
| `.tapping` with op mode `.trigger` | finger taps | `tapped` |
| `.airGesture` with op mode `.stream` | swipes, pinches, fist | `tapXRAirGestured` |

`TAPV2VisionSensorOpMode`: `.trigger`, `.stream`, `.streamOnTrigger` (experiments).

## Enable and switch

TapXR with hardware version ≥ 40000: `TAPXRState` is folded into the mode write.

```swift
TAPKit.sharedKit.setTAPInputMode(.controller(), forIdentifiers: [identifier])
TAPKit.sharedKit.setTAPXRState(.airMouse(), forIdentifiers: [identifier]) // air-gesture model + stream
TAPKit.sharedKit.setTAPXRState(.tapping(), forIdentifiers: [identifier])  // tapping model + trigger
```

Any V2 device, including TapBand: set the features yourself. These calls are ignored on legacy hardware.

```swift
func useAirGestures(_ identifier: String) {
    let ids = [identifier]
    TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: ids)
    TAPKit.sharedKit.setVisionSensorModel(.airGesture, forIdentifiers: ids)
    TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: ids)
}

func useTapping(_ identifier: String) {
    let ids = [identifier]
    TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: ids)
    TAPKit.sharedKit.setVisionSensorModel(.tapping, forIdentifiers: ids)
    TAPKit.sharedKit.setVisionSensorOpMode(.trigger, forIdentifiers: ids)
}
```

You can switch at runtime. Read the current state with `getVisionSensorModel(forIdentifier:)` and `getVisionSensorOpMode(forIdentifier:)`. Completions run on the main queue. `nil` means timeout (default 2 s) or a legacy device.

`setTAPInputMode` also writes these features. A later mode change can overwrite a direct `setFeature` call. Set the mode first, then the vision model.

## TAPXRAirGesture

`tapXRAirGestured` delivers **edges**, after the SDK post-processes the model stream. Apps do not see repeating raw codes. Prefer this enum for new code. `gesture.descriptionString()` is for logs.

| Case | Raw | Meaning |
|------|-----|---------|
| `ClickIndex` / `ClickMiddle` / `ClickRing` / `ClickPinky` | 1–4 | Short pinch, thumb + that finger |
| `DragIndex` / `DragMiddle` / `DragRing` / `DragPinky` | 5–8 | Pinch held (grab) |
| `Drop` | 9 | Pinch released |
| `FistBegin` / `FistEnd` | 14 / 15 | Fist held / fist released |
| `SwipeLeft` / `SwipeRight` / `SwipeUp` / `SwipeDown` | 17–20 | One swipe |

`PotentialDragOrClick*` (10–13) can appear on the older TapXR path while the SDK is still deciding click versus drag. Ignore it until a click, drag, or drop arrives. The V2 converter emits click, drag, drop, swipe, and fist edges, not the potential cases.

```swift
func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture) {
    switch gesture {
    case .SwipeLeft: goBack()
    case .ClickIndex: select()
    case .DragIndex: beginGrab()
    case .Drop: endGrab()
    case .FistBegin: hideControls()
    case .FistEnd: showControls()
    default: break
    }
}
```

Do not port tap-python-sdk `UnifiedAirGestures` numbers (100–114) into an iOS app. The iOS callback is already translated into `TAPXRAirGesture`.

## Standby (V2)

```swift
TAPKit.sharedKit.setFeature(.standbyGestureDetection, enabled: true, forIdentifiers: [identifier])
TAPKit.sharedKit.setStandbyState(false, forIdentifiers: [identifier]) // wake
```

`tapChangedStandbyState(identifier:isInStandby:)` reports changes. `getStandbyState(forIdentifier:)` reads it.

## Legacy air gestures (Tap Strap)

In controller mode, `tapAirGestured` delivers `TAPAirGesture` for older strap firmware: one- and two-finger up, down, left, right, and thumb-to-index / thumb-to-middle touches. There is no model switch on that path.

`tapChangedAirGesturesState(identifier:isInAirGesturesState:)` reports entering or leaving air-gesture state on that legacy path.

The `TAPAirGesture` cases whose raw values are ≥ 100 are older XR payloads. New TapXR code should use `tapXRAirGestured` instead.

## Docs

- Enums and V2 configuration: `README.md` in the SDK repository
- Knob and D-Pad recipes built on these edges: `tapkit-knob`, `tapkit-dpad`
