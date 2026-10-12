import Foundation

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func testKnob() {
    var knob = KnobTracker(stepDegrees: 2)
    expect(knob.onRoll(10) == 0, "idle roll")
    expect(knob.onGesture(6) == "start" && knob.active == 1, "middle pinch grabs knob 1")
    expect(knob.onRoll(10) == 0, "first roll sets the reference")
    let steps = [knob.onRoll(11), knob.onRoll(12), knob.onRoll(15), knob.onRoll(9)]
    expect(steps.count == 4 && steps[0] == 0 && steps[1] == 1 && steps[2] == 1 && steps[3] == -2, "step sequence \(steps)")
    expect(knob.onGesture(5) == "start" && knob.active == 0, "a different pinch re-grabs")
    expect(knob.onRoll(179) == 0 && knob.onRoll(-177) == 2, "wrap across ±180")
    expect(knob.onGesture(9) == "release" && knob.active == nil, "Drop releases")
    expect(knob.onGesture(9) == nil, "Drop while idle is ignored")
    expect(knob.onRoll(40) == 0, "roll while idle stays zero")
}

func testDpadRotateLock() {
    var dpad = DpadController()
    expect(dpad.onGesture(17, now: 0.0) == [.direction("left")], "swipe left")
    expect(dpad.onGesture(17, now: 0.01) == [], "debounced repeat")
    expect(dpad.onGesture(1, now: 0.1) == [.pinch(0)], "short pinch")
    expect(dpad.onGesture(5, now: 0.2) == [.hold(0)] && dpad.mode == "pending", "pinch hold")
    expect(dpad.onGesture(1, now: 0.25) == [], "pinch ignored while holding")
    _ = dpad.onMotion(dx: 0, dy: 0, roll: 0, now: 0.3)
    let locked = dpad.onMotion(dx: 0, dy: 0, roll: 30, now: 0.5)
    expect(locked.contains(.mode("rotate")), "twist locks rotate")
    expect(dpad.onMotion(dx: 5, dy: 5, roll: 40, now: 0.6) == [.rotate(40)], "rotate follows roll")
    expect(dpad.onGesture(9, now: 0.7) == [.release(0)] && dpad.held == nil, "Drop releases")
}

func testDpadDragLockAndFist() {
    var dpad = DpadController()
    _ = dpad.onGesture(7, now: 0.0)
    _ = dpad.onMotion(dx: 0, dy: 0, roll: 0, now: 0.1)
    _ = dpad.onMotion(dx: 0, dy: 0, roll: 5, now: 0.5)
    expect(
        dpad.onMotion(dx: 3, dy: -2, roll: 5, now: 1.1) == [.mode("drag"), .drag(dx: 3, dy: -2)],
        "small twist becomes drag after the window"
    )
    expect(dpad.onGesture(14, now: 1.2) == [.release(2), .hide], "fist hides and releases")
    expect(dpad.onGesture(17, now: 1.3) == [], "hidden gestures are ignored")
    expect(dpad.onGesture(15, now: 1.4) == [.show], "relaxing the fist shows again")
}

@main
struct SkillLogicTestRunner {
    static func main() {
        testKnob()
        testDpadRotateLock()
        testDpadDragLockAndFist()
        print("Skill logic tests passed.")
    }
}
