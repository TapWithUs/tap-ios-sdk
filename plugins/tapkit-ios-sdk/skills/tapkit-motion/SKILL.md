---
name: tapkit-motion
description: Use TAP hand motion from moused velocities and tapDidChangeOrientation roll, pitch, and yaw to move a cursor, tilt, or rotate. Use for air mouse, pointer, cursor, AssistiveTouch, or orientation.
---

# Motion and air mouse

Start from `tapkit-getting-started`. Motion and taps can be on together.

## Enable

```swift
TAPKit.sharedKit.setTAPInputMode(.controller(), forIdentifiers: nil)
TAPKit.sharedKit.setTAPXRState(.airMouse(), forIdentifiers: nil) // TapXR and TapBand
```

If `TAPXRState` is not set, turn the stream on:

```swift
TAPKit.sharedKit.setFeature(.imuMotionData, enabled: true, forIdentifiers: [identifier])
```

Turn it off with `setFeature(.imuMotionData, enabled: false, ...)` when the screen does not need motion, to save battery. A later `setTAPInputMode(.controller())` turns it back on.

`TAPInputMode.controllerWithMouseHID()` also drives the iOS AssistiveTouch cursor (iOS 13+, Accessibility settings). The app still receives `moused`.

## Pointer deltas

```swift
func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse: Bool) {
    guard isMouse else { return } // false is an idle / zero packet
    cursor.x += CGFloat(velocityX) * gain
    cursor.y += CGFloat(velocityY) * gain
}
```

- `velocityX` and `velocityY` are signed deltas since the last packet. Scale them in the app.
- `isMouse == false` means "not a pointer move". Skip it or you will fight idle packets.
- There is no fixed packet rate. If timing matters, measure it.

## Orientation

```swift
func tapDidChangeOrientation(roll: Int, pitch: Int, yaw: Int) {
    // degrees
}
```

This callback does **not** include a device identifier. With two Taps connected, the app cannot tell which hand moved. Track one device, or keep the last `moused` identifier only as a hint (it is not guaranteed to match).

- `roll`, `pitch`, `yaw` are signed degrees.
- Do not treat absolute roll as a dial. Store the roll when the gesture starts (a `DragIndex` grab, see `tapkit-knob`) and use the delta. Roll wraps at ±180.
- Tap Strap mouse packets may omit useful euler angles. Use raw IMU (`tapkit-raw-sensors`) when you need orientation from a Tap Strap.

## Patterns

**Clamp a cursor** inside the view bounds. Add a dead zone so a still hand does not drift: ignore the sample when `abs(velocityX) + abs(velocityY) < 2`.

**Smooth** a noisy angle with an exponential average:

```swift
smooth = alpha * value + (1 - alpha) * smooth // alpha around 0.3
```

**System cursor:** `controllerWithMouseHID()` plus AssistiveTouch. The app does not draw that cursor.

If a direction is mirrored on the user's device, flip the sign and ask them to try again.

## Docs

- `moused` and `tapDidChangeOrientation`: `README.md` in the SDK repository
- Combining motion with pinch-hold: `tapkit-knob`, `tapkit-dpad`
