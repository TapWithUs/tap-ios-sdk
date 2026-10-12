---
name: tapkit-raw-sensors
description: Stream raw accelerometer and gyroscope samples with TAPInputMode.rawSensor or V2 raw IMU, and set sensitivity. Use for raw sensors, raw IMU, accelerometer, gyro, logging, or custom gesture recognition.
---

# Raw sensors

For recording and custom gesture models. For a cursor or wrist angle, prefer `tapkit-motion` (less data, already reduced to deltas and degrees).

## Turn the stream on

Legacy and V2 both use an input mode. Raw mode replaces controller mode, so `tapped` and `moused` stop until you switch back.

```swift
let sensitivity = TAPRawSensorSensitivity(finger: .g2, gyro: .dps125, accelerometer: .g2)
TAPKit.sharedKit.setTAPInputMode(
    .rawSensor(sensitivity: sensitivity),
    forIdentifiers: [identifier]
)
```

The enum raw values are the bytes written into the mode command, and they match tap-python-sdk (`FingerAcclSensitivity`, `ImuGyroSensitivity`, `ImuAcclSensitivity`). They are **1-based**. `.g2` and `.dps125` are sent as `1`. `TAPRawSensorSensitivity()` sends `[1, 1, 1]`, the same default as Python `InputModeRaw()`.

| Enum | Cases | Wire codes |
|------|-------|------------|
| `TAPFingerAcclSensitivity` | `.g2` `.g4` `.g8` `.g16` | 1–4 |
| `TAPIMUGyroSensitivity` | `.dps125` `.dps250` `.dps500` `.dps1000` `.dps2000` | 1–5 |
| `TAPIMUAcclSensitivity` | `.g2` `.g4` `.g8` `.g16` | 1–4 |

The older integer initializer takes those same wire codes (`deviceAccelerometer:`, `imuGyro:`, `imuAccelerometer:`). A code that is already in range is stored unchanged. `0` is stored as `1`. Values above the max are clamped. Gyro and IMU-accelerometer scale factors match Python. Finger factors stay at `3.90625`, `7.8125`, `15.625`, and `31.25` mg/LSB.

On V2, change the thumb IMU without leaving the mode. This writes the same two bytes as Python `set_imu_sensitivity` (gyro, then accelerometer). The finger range is not in that V2 frame.

```swift
TAPKit.sharedKit.setIMUSensitivity(.dps125, accelerometer: .g2, forIdentifiers: [identifier])

TAPKit.sharedKit.getIMUSensitivity(forIdentifier: identifier) { (reading: TAPIMUSensitivity?) in
    // reading?.gyro == .dps125, reading?.gyroWireValue == 1
}
```

`getIMUSensitivity` completes on the main queue with `nil` on timeout, on a legacy device, or if the device returns a byte that is not one of the enum raw values.

`TAPInputMode.v2Debug()` (or `v2Debug(sensitivity:)`) turns on raw IMU, model detection, and IMU motion together, with the air-gesture model streaming. Use it for bring-up, not for a shipping mode: it is the noisiest stream.

Leave raw mode with `setTAPInputMode(.controller(), forIdentifiers:)`.

Developer mode in Tap Manager is required for raw streaming on some v1 firmware. If samples never arrive, ask the user to enable it and reconnect.

## Samples

```swift
func rawSensorDataReceived(identifier: String, data: RawSensorData) {
    switch data.type {
    case .IMU:
        if let gyro = data.getPoint(for: RawSensorData.iIMU_GYRO) {
            // gyro.x, gyro.y, gyro.z
        }
        if let accel = data.getPoint(for: RawSensorData.iIMU_ACCELEROMETER) {
            // thumb accelerometer
        }
    case .Device:
        // finger accelerometers, thumb first
        _ = data.getPoint(for: RawSensorData.iDEV_THUMB)
        _ = data.getPoint(for: RawSensorData.iDEV_INDEX)
        _ = data.getPoint(for: RawSensorData.iDEV_MIDDLE)
        _ = data.getPoint(for: RawSensorData.iDEV_RING)
        _ = data.getPoint(for: RawSensorData.iDEV_PINKY)
    default:
        break
    }
}
```

- `timestamp` is the device clock (`UInt32`), not wall time. Use it for spacing between samples.
- Each `Point3` is a `Double` already multiplied by the sensitivity factor for that axis: mg/LSB for accelerometers and mdps/LSB for the gyro, using the factor for the 1-based wire code. Do not treat the values as raw LSB counts.
- The callback is one sample, on the main queue, at a high rate. Append to an array and write the file later. Do not format CSV or touch the disk inside the callback.
- Do not assume a fixed rate. The SDK README mentions about 200 messages per minute; measure with `timestamp` on the device you have before depending on that number.

## Logging

Keep a buffer on the delegate object and flush it when recording stops:

```swift
private var rows: [String] = []

func rawSensorDataReceived(identifier: String, data: RawSensorData) {
    let kind = data.type == .IMU ? "imu" : "accl"
    let values = data.points.map { "\($0.x),\($0.y),\($0.z)" }.joined(separator: ",")
    rows.append("\(identifier),\(data.timestamp),\(kind),\(values)")
}
```

Write `rows` to a file from a button, not from the callback. Share the file with the system share sheet.

## Docs

- Raw sensor section of `README.md` in the SDK repository
- Parsed type: `TAPKit-iOS/Helpers/RawSensorData/RawSensorData.swift`
