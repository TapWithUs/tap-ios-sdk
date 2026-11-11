import Foundation

// Compiled with TAPKit-iOS/TAPKit/TAPV2StandbyTracker.swift by
// tests/check_install_skills.sh when swiftc is on PATH.

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

/// The input-mode write TAPKit sends at connect must wait when standby was
/// just commanded, even before the device reports it.
func testWritesAreHeldFromTheStandbyCommand() {
    var tracker = TAPV2StandbyTracker()
    expect(!tracker.holdsWrites(for: "A"), "awake device takes writes")
    tracker.commanded(standby: true, identifier: "A")
    expect(tracker.holdsWrites(for: "A"), "writes held from the standby command")
    expect(!tracker.holdsWrites(for: "B"), "other devices unaffected")
}

func testReportedWakeReleasesWritesAndReappliesTheMode() {
    var tracker = TAPV2StandbyTracker()
    tracker.commanded(standby: true, identifier: "A")
    expect(!tracker.reported(standby: true, identifier: "A"), "entering standby re-applies nothing")
    tracker.commanded(standby: false, identifier: "A")
    expect(tracker.holdsWrites(for: "A"), "still held until the device reports waking")
    expect(tracker.reported(standby: false, identifier: "A"), "reported wake re-applies the mode")
    expect(!tracker.holdsWrites(for: "A"), "writes released after the wake")
    expect(!tracker.reported(standby: false, identifier: "A"), "an awake device's report re-applies nothing")
}

func testDeviceStandbyAndDisconnect() {
    var tracker = TAPV2StandbyTracker()
    expect(!tracker.reported(standby: true, identifier: "A"), "device's own standby")
    expect(tracker.holdsWrites(for: "A"), "held while the device sleeps")
    tracker.forget("A")
    expect(!tracker.holdsWrites(for: "A"), "cleared on disconnect")
}

@main
struct V2StandbyTrackerTestRunner {
    static func main() {
        testWritesAreHeldFromTheStandbyCommand()
        testReportedWakeReleasesWritesAndReappliesTheMode()
        testDeviceStandbyAndDisconnect()
        print("V2 standby tracker tests passed.")
    }
}
