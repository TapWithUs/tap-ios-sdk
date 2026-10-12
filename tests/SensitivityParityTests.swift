import Foundation

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func sameBytes(_ actual: [UInt8], _ expected: [UInt8]) -> Bool {
    if actual.count != expected.count {
        return false
    }
    for index in 0..<actual.count {
        if actual[index] != expected[index] {
            return false
        }
    }
    return true
}

func expectBytes(_ actual: [UInt8], _ expected: [UInt8], _ message: String) {
    expect(sameBytes(actual, expected), "\(message): \(actual) != \(expected)")
}

func dataBytes(_ data: Data) -> [UInt8] {
    return [UInt8](data)
}

func testEnumWireValues() {
    expect(TAPFingerAcclSensitivity.g2.rawValue == 1, "finger G2")
    expect(TAPFingerAcclSensitivity.g4.rawValue == 2, "finger G4")
    expect(TAPFingerAcclSensitivity.g8.rawValue == 3, "finger G8")
    expect(TAPFingerAcclSensitivity.g16.rawValue == 4, "finger G16")
    expect(TAPIMUGyroSensitivity.dps125.rawValue == 1, "gyro DPS125")
    expect(TAPIMUGyroSensitivity.dps250.rawValue == 2, "gyro DPS250")
    expect(TAPIMUGyroSensitivity.dps500.rawValue == 3, "gyro DPS500")
    expect(TAPIMUGyroSensitivity.dps1000.rawValue == 4, "gyro DPS1000")
    expect(TAPIMUGyroSensitivity.dps2000.rawValue == 5, "gyro DPS2000")
    expect(TAPIMUAcclSensitivity.g2.rawValue == 1, "xl G2")
    expect(TAPIMUAcclSensitivity.g4.rawValue == 2, "xl G4")
    expect(TAPIMUAcclSensitivity.g8.rawValue == 3, "xl G8")
    expect(TAPIMUAcclSensitivity.g16.rawValue == 4, "xl G16")
}

func testNormalizingWireValue() {
    expect(TAPFingerAcclSensitivity.normalizingWireValue(0) == 1, "finger 0")
    expect(TAPFingerAcclSensitivity.normalizingWireValue(2) == 2, "finger 2")
    expect(TAPFingerAcclSensitivity.normalizingWireValue(9) == 4, "finger 9")
    expect(TAPIMUGyroSensitivity.normalizingWireValue(0) == 1, "gyro 0")
    expect(TAPIMUGyroSensitivity.normalizingWireValue(5) == 5, "gyro 5")
    expect(TAPIMUGyroSensitivity.normalizingWireValue(9) == 5, "gyro 9")
    expect(TAPIMUAcclSensitivity.normalizingWireValue(0) == 1, "xl 0")
    expect(TAPIMUAcclSensitivity.normalizingWireValue(3) == 3, "xl 3")
    expect(TAPIMUAcclSensitivity.normalizingWireValue(9) == 4, "xl 9")
}

func testRawModeCommandBytes() {
    let defaults = TAPRawSensorSensitivity()
    expectBytes(defaults.bytes(), [1, 1, 1], "default raw bytes")

    let pythonCase = TAPRawSensorSensitivity(finger: .g2, gyro: .dps250, accelerometer: .g8)
    expectBytes(pythonCase.bytes(), [1, 2, 3], "G2 DPS250 G8")
    let pythonCommand = TAPInputMode.rawSensor(sensitivity: pythonCase).data()
    expect(pythonCommand != nil, "raw mode command")
    expectBytes(dataBytes(pythonCommand!), [0x3, 0xc, 0x0, 0xa, 1, 2, 3], "Python G2/DPS250/G8 command")

    let documented = TAPRawSensorSensitivity(finger: .g4, gyro: .dps250, accelerometer: .g8)
    expectBytes(dataBytes(TAPInputMode.rawSensor(sensitivity: documented).data()!), [0x3, 0xc, 0x0, 0xa, 2, 2, 3], "G4/DPS250/G8 command")

    let partial = TAPRawSensorSensitivity(finger: .g16, gyro: .dps125, accelerometer: .g2)
    expectBytes(dataBytes(TAPInputMode.rawSensor(sensitivity: partial).data()!), [0x3, 0xc, 0x0, 0xa, 4, 1, 1], "G16 with default rest")

    let zero = TAPRawSensorSensitivity(deviceAccelerometer: 0, imuGyro: 0, imuAccelerometer: 0)
    expectBytes(zero.bytes(), [1, 1, 1], "integer 0 is sent as 1")

    let inRange = TAPRawSensorSensitivity(deviceAccelerometer: 2, imuGyro: 2, imuAccelerometer: 2)
    expectBytes(inRange.bytes(), [2, 2, 2], "in-range integers stay")

    let clamped = TAPRawSensorSensitivity(deviceAccelerometer: 9, imuGyro: 9, imuAccelerometer: 9)
    expectBytes(clamped.bytes(), [4, 5, 4], "above max clamps")

    let assigned = TAPRawSensorSensitivity()
    assigned.deviceAccelerometer = 0
    assigned.imuGyro = 2
    assigned.imuAccelerometer = 9
    expectBytes(assigned.bytes(), [1, 2, 4], "property setter normalizes")
}

func testScaleFactors() {
    let low = TAPRawSensorSensitivity(finger: .g2, gyro: .dps125, accelerometer: .g2)
    expect(low.sensitivityFactor(for: TAPRawSensorSensitivity.kDeviceAccelerometer) == 3.90625, "finger scale 1")
    expect(low.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUGyro) == 4.375, "gyro scale 1")
    expect(low.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUAccelerometer) == 0.061, "xl scale 1")

    let mid = TAPRawSensorSensitivity(finger: .g16, gyro: .dps500, accelerometer: .g4)
    expect(mid.sensitivityFactor(for: TAPRawSensorSensitivity.kDeviceAccelerometer) == 31.25, "finger scale 4")
    expect(mid.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUGyro) == 17.5, "gyro scale 3")
    expect(mid.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUAccelerometer) == 0.122, "xl scale 2")

    let highGyro = TAPRawSensorSensitivity(finger: .g2, gyro: .dps2000, accelerometer: .g16)
    expect(highGyro.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUGyro) == 70, "gyro scale 5")
    expect(highGyro.sensitivityFactor(for: TAPRawSensorSensitivity.kIMUAccelerometer) == 0.488, "xl scale 4")
}

func testV2SensitivityFrame() {
    expectBytes(
        dataBytes(TAPV2Encoder.encodeSetIMUSensitivity(gyro: 1, xl: 1)),
        [1, 1, 2, 0, 1, 1],
        "V2 set IMU default"
    )
    expectBytes(
        dataBytes(TAPV2Encoder.encodeSetIMUSensitivity(gyro: 2, xl: 3)),
        [1, 1, 2, 0, 2, 3],
        "V2 set IMU DPS250 G8"
    )

    let raw = TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity(finger: .g2, gyro: .dps250, accelerometer: .g8))
    let rawCommands = TAPV2InputModeMapper.commands(for: raw, xrState: nil)
    expect(rawCommands.count > 0, "raw mode V2 commands")
    expectBytes(dataBytes(rawCommands[rawCommands.count - 1]), [1, 1, 2, 0, 2, 3], "raw mode V2 frame is gyro then xl")

    let zero = TAPInputMode.rawSensor(sensitivity: TAPRawSensorSensitivity(deviceAccelerometer: 0, imuGyro: 0, imuAccelerometer: 0))
    let zeroCommands = TAPV2InputModeMapper.commands(for: zero, xrState: nil)
    expectBytes(dataBytes(zeroCommands[zeroCommands.count - 1]), [1, 1, 2, 0, 1, 1], "V2 frame sends 1 for integer 0")

    let debug = TAPInputMode.v2Debug()
    let debugCommands = TAPV2InputModeMapper.commands(for: debug, xrState: nil)
    expectBytes(dataBytes(debugCommands[debugCommands.count - 1]), [1, 1, 2, 0, 1, 1], "v2Debug default sensitivity")
}

func testReadBackMapping() {
    let reading = TAPIMUSensitivity(gyroWireValue: 2, accelerometerWireValue: 3)
    expect(reading != nil, "known wire values")
    expect(reading!.gyro == .dps250 && reading!.gyroWireValue == 2, "gyro read-back")
    expect(reading!.accelerometer == .g8 && reading!.accelerometerWireValue == 3, "xl read-back")
    expect(TAPIMUSensitivity(gyroWireValue: 0, accelerometerWireValue: 1) == nil, "0 is not a known range")
    expect(TAPIMUSensitivity(gyroWireValue: 6, accelerometerWireValue: 1) == nil, "gyro 6 is unknown")
}

@main
struct SensitivityParityTestRunner {
    static func main() {
        testEnumWireValues()
        testNormalizingWireValue()
        testRawModeCommandBytes()
        testScaleFactors()
        testV2SensitivityFrame()
        testReadBackMapping()
        print("Sensitivity parity tests passed.")
    }
}
