---
name: tapkit-tapping
description: Decode TAP finger combinations, map them to in-app actions, detect double taps, and give haptic feedback with vibrate(durations:). Use for tapping, finger combos, chords, in-app shortcuts, multitap, or TAPInputMode.
---

# Tapping

Works on legacy (v1) and V2. Start from `tapkit-getting-started` for the connect order.

## Combination bitmask

`combination` in `tapped` is an integer 1–31. Each bit is one finger:

| Bit | Value | Finger |
|-----|-------|--------|
| 0 | 1 | thumb |
| 1 | 2 | index |
| 2 | 4 | middle |
| 3 | 8 | ring |
| 4 | 16 | pinky |

Examples: `1` thumb, `2` index, `3` thumb+index, `6` index+middle, `31` all five.

```swift
func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
    let fingers = TAPCombination.toFingers(combination) // [Bool] thumb → pinky
    switch combination {
    case 2: goNext()        // index
    case 4: goPrevious()    // middle
    case 6: select()        // index + middle
    case 31: close()        // all five
    default: break
    }
}
```

`TAPCombination.fromFingers` builds a bitmask. `TAPCombination.combinationSpeakableString(for:)` is a debug string.

Single-finger taps are the most reliable. Prefer them for frequent actions. Use two-finger combos next. Use three or more fingers only for rare actions.

`multitap` is 1–3 and reflects keyboard multitap state when the firmware sends it. It is not a double-tap detector. Detect double taps yourself (below).

## Turn on tap events

- `TAPInputMode.controller()` — **default you want.** Delivers `tapped` and `moused`.
- `TAPInputMode.text()` — the Tap is a Bluetooth keyboard. `tapped` and `moused` do **not** fire. Use this only when the user should type into a text field.
- `TAPInputMode.controllerWithMouseHID()` — controller callbacks plus the system AssistiveTouch cursor (iOS 13+).
- `TAPInputMode.controllerWithFullHID()` — full HID controller mode.
- `TAPInputMode.tapHold()` — short taps still arrive via `tapped`. Long presses arrive via `tapHoldStarted` / `tapHoldEnded`.

```swift
TAPKit.sharedKit.setTAPInputMode(.controller(), forIdentifiers: nil)
TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
```

On TapXR, also set `TAPXRState.tapping()` so the device stays in tapping rather than air-mouse. On other V2 devices, set the tapping vision model (see `tapkit-air-gestures`).

The SDK re-sends the current mode on a timer while the app is active, so the device stays in it.

## Double taps

The SDK reports every tap. Detect a double tap with a time window. If a single tap must not also fire, delay the single action until the window ends.

```swift
private var lastCode: UInt8?
private var lastTap = Date.distantPast
private var pending: DispatchWorkItem?

func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
    let now = Date()
    if lastCode == combination, now.timeIntervalSince(lastTap) < 0.35 {
        pending?.cancel()
        handleDouble(combination)
        lastCode = nil
        return
    }
    lastCode = combination
    lastTap = now
    let work = DispatchWorkItem { [weak self] in self?.handleSingle(combination) }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
}
```

## Typing and in-app actions

The SDK does not synthesize OS key presses. Two different jobs:

- **Type into a text field:** `setTAPInputMode(.text(), forIdentifiers:)`. The Tap is the keyboard. Your delegate will not see those taps.
- **Trigger an in-app action:** stay in controller mode and switch on `combination` in `tapped`.

Do not add a library that injects global keystrokes. iOS apps cannot drive other apps that way.

## Haptic feedback

```swift
TAPKit.sharedKit.vibrate(durations: [80], forIdentifiers: [identifier])
TAPKit.sharedKit.vibrate(durations: [100, 100, 100], forIdentifiers: nil) // on, pause, on
```

Values are milliseconds, quantized to 10 ms, maximum 18 values. `nil` identifiers vibrate every connected device. Delegate callbacks are already on the main queue, so call `vibrate` directly.

## Docs

- Input modes and the combination table: `README.md` in the SDK repository
- Sample: `TAPKit-Example/ViewController.swift`
