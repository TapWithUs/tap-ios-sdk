---
name: tapkit-raw-sensors
description: Stream raw accelerometer and gyroscope samples with TAPInputMode.rawSensor or V2 raw IMU, and set sensitivity. Use for raw sensors, raw IMU, accelerometer, gyro, logging, or custom gesture recognition.
---

# Raw sensors

For recording and custom gesture models. For a cursor or wrist angle, prefer `tapkit-motion` (less data, already reduced to deltas and degrees).

## Turn the stream on

Legacy and V2 both use an input mode. Raw mode replaces controller mode, so `tapped` and `moused` stop until you switch back.

```swift
let sensitivity = TAPRawSensorSensitivity(
    deviceAccelerometer: 0,
    imuGyro: 0,
    imuAccelerometer: 0
)
TAPKit.sharedKit.setTAPInputMode(
    .rawSensor(sensitivity: sensitivity),
    forIdentifiers: [identifier]
)
```

Ranges accepted by `TAPRawSensorSensitivity` (0 is valid and is the default):

| Property | Range | Sensor |
|----------|-------|--------|
| `deviceAccelerometer` | 0–4 | finger accelerometers |
| `imuGyro` | 0–5 | thumb gyroscope |
| `imuAccelerometer` | 0–4 | thumb accelerometer |

On V2 you can change IMU sensitivity without leaving the mode:

```swift
TAPKit.sharedKit.setIMUSensitivity(gyro: 0, accelerometer: 0, forIdentifiers: [identifier])
// gyro 0–5, accelerometer 0–4
```

`getIMUSensitivity(forIdentifier:)` completes on the main queue with `nil` on timeout or on a legacy device.

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
- Each `Point3` is a `Double` already multiplied by the sensitivity factor for that axis. Do not treat the values as raw LSB counts, and do not assume a unit (mg, g, mdps) without measuring against a known motion.
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
