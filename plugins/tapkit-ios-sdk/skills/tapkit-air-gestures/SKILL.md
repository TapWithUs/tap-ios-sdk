---
name: tapkit-air-gestures
description: Handle TAPXRAirGesture (processed click, drag, drop, fist, swipe) on TapXR and TapBand, document raw firmware class indexes, switch tapping vs air-gesture models, and handle Tap Strap TAPAirGesture. Use for air gestures, pinch, swipe, fist, TAPXRState, or raw detections.
---

# Air gestures

TapXR (current developer firmware) and TapBand share the same BLE API and the **full** gesture set: taps, thumb swipes up/down/left/right, thumb-to-finger pinches with hold, and fist with hold. TapBand is coming soon (not for sale): https://www.tapwithus.com/tapband-waitlist/

Every Tap SDK receives the **raw** detections from the sensor. iOS TAPKit also exposes a **processed** layer on `tapXRAirGestured`. Use that processed callback in iOS apps. Tap Strap air gestures are at the end of this page.

The device runs one vision model at a time:

| Model | Output | Callback |
|-------|--------|----------|
| `.tapping` with op mode `.trigger` | finger taps | `tapped` |
| `.airGesture` with op mode `.stream` | swipes, pinches, fist | `tapXRAirGestured` |

`TAPV2VisionSensorOpMode`: `.trigger`, `.stream`, `.streamOnTrigger` (experiments).

## Enable and switch

`TAPXRState` is written with the input mode on TapXR and TapBand:

```swift
TAPKit.sharedKit.setTAPInputMode(.controller(), forIdentifiers: [identifier])
TAPKit.sharedKit.setTAPXRState(.airMouse(), forIdentifiers: [identifier]) // air-gesture model + stream
TAPKit.sharedKit.setTAPXRState(.tapping(), forIdentifiers: [identifier])  // tapping model + trigger
```

You can set the same features directly (same BLE API on TapXR and TapBand). These calls are ignored on Tap Strap.

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

You can switch at runtime. Read the current state with `getVisionSensorModel(forIdentifier:)` and `getVisionSensorOpMode(forIdentifier:)`. Completions run on the main queue. `nil` means timeout (default 2 s) or a Tap Strap.

`setTAPInputMode` also writes these features. A later mode change can overwrite a direct `setFeature` call. Set the mode first, then the vision model.

## Raw detections (every Tap SDK)

The sensor reports class indexes. TAPKit receives this stream. Other Tap SDKs expose the integers directly. On iOS there is **no** `TAPKitDelegate` method for the class index; TAPKit consumes the stream and then calls `tapXRAirGestured`.

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

Verified against `GesturePostprocessor.LBL_IDX`. Do not invent extra codes. Do not invent a firmware version number.

```swift
// Raw class indexes (firmware). Not TAPXRAirGesture.rawValue.
// TAPXRAirGesture.None is 0, not 100. Do not switch on these in tapXRAirGestured.
func rawClassMeaning(_ classIndex: Int) -> String {
    switch classIndex {
    case 101: return "swipe left"
    case 102: return "swipe right"
    case 103: return "swipe up"
    case 104: return "swipe down"
    case 105: return "pinch index"
    case 106: return "pinch middle"
    case 107: return "pinch ring"
    case 108: return "pinch pinky"
    case 109: return "fist"
    case 110: return "hold index"
    case 111: return "hold middle"
    case 112: return "hold ring"
    case 113: return "hold pinky"
    case 114: return "fist hold"
    case 100: return "idle"
    default: return "unknown"
    }
}
```

## Processed layer (iOS)

`tapXRAirGestured` delivers **edges** after TAPKit post-processes the raw stream: 200 ms cooldown, hold latching (a hold stays until idle), swipe debounce. Apps do not see the repeating raw class indexes. Prefer this enum for iOS code. `gesture.descriptionString()` is for logs.

| Case | Raw | Meaning |
|------|-----|---------|
| `ClickIndex` / `ClickMiddle` / `ClickRing` / `ClickPinky` | 1–4 | Short pinch, thumb + that finger |
| `DragIndex` / `DragMiddle` / `DragRing` / `DragPinky` | 5–8 | Pinch held (grab) |
| `Drop` | 9 | Pinch released |
| `FistBegin` / `FistEnd` | 14 / 15 | Fist held / fist released |
| `SwipeLeft` / `SwipeRight` / `SwipeUp` / `SwipeDown` | 17–20 | One swipe |

`PotentialDragOrClick*` (10–13) can appear on some TapXR hardware while TAPKit is still deciding click versus drag. Ignore it until a click, drag, or drop arrives. Current developer firmware goes through the processed converter, which emits click, drag, drop, swipe, and fist edges, not the potential cases.

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

Map from raw class to processed edge (after post-process): `LEFT`→`SwipeLeft`, `AB`→`ClickIndex`, `AB_HOLD`→`DragIndex` (once), idle after a hold→`Drop` or `FistEnd`.

## Standby (TapXR and TapBand)

```swift
TAPKit.sharedKit.setFeature(.standbyGestureDetection, enabled: true, forIdentifiers: [identifier])
TAPKit.sharedKit.setStandbyState(false, forIdentifiers: [identifier]) // wake
```

`tapChangedStandbyState(identifier:isInStandby:)` reports changes. `getStandbyState(forIdentifier:)` reads it.

## Tap Strap air gestures

In controller mode, `tapAirGestured` delivers `TAPAirGesture` for Tap Strap firmware: one- and two-finger up, down, left, right, and thumb-to-index / thumb-to-middle touches. There is no model switch on that path.

```swift
func tapAirGestured(identifier: String, gesture: TAPAirGesture) {
    switch gesture {
    case .OneFingerUp: moveUp()
    case .OneFingerDown: moveDown()
    case .IndexToThumbTouch: select()
    default: break
    }
}
```

`tapChangedAirGesturesState(identifier:isInAirGesturesState:)` reports entering or leaving air-gesture state on that path.

The `TAPAirGesture` cases whose raw values are ≥ 100 are older XR payload values. They are **not** the firmware class table above, and they are **not** `TAPXRAirGesture`. New TapXR and TapBand code should use `tapXRAirGestured`.

## Docs

- Enums and device configuration: `README.md` in the SDK repository
- Knob and D-Pad recipes built on processed edges: `tapkit-knob`, `tapkit-dpad`
