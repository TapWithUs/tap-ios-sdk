//
//  GestureSampleViewController.swift
//  TAPKit-Example
//
//  Knob and D-Pad sample. The trackers are the skill scripts
//  plugins/tapkit-ios-sdk/skills/tapkit-knob/scripts/KnobTracker.swift and
//  plugins/tapkit-ios-sdk/skills/tapkit-dpad/scripts/DpadController.swift.
//

import UIKit
import TAPKit

final class GestureSampleViewController: UIViewController, TAPKitDelegate {
    private let statusLabel = UILabel()
    private let detailLabel = UILabel()
    private let modeControl = UISegmentedControl(items: ["Knob", "D-Pad"])
    private let knobStack = UIStackView()
    private var knobLabels = [UILabel]()
    private let padView = UIView()
    private var padCenterX: NSLayoutConstraint?
    private var padCenterY: NSLayoutConstraint?
    private var padWidth: CGFloat = 72

    private var knob = KnobTracker(stepDegrees: 2)
    private var dpad = DpadController()
    private var knobValues = [50, 50, 50, 50]
    private var latestDelta = (dx: 0, dy: 0)
    private var activeIdentifier: String?
    private var padOffset = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        buildLayout()
        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        showKnob(true)
        refreshKnobLabels()

        let connected = TAPKit.sharedKit.getConnectedTaps()
        if let first = connected.first {
            activeIdentifier = first.key
            statusLabel.text = "Connected: \(first.value). Hold a pinch and twist."
        } else {
            statusLabel.text = "Waiting for a paired TAP. This screen needs a V2 device."
        }
        enableAirGestureMode()
        TAPKit.sharedKit.addDelegate(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TAPKit.sharedKit.removeDelegate(self)
        restoreTappingMode()
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func modeChanged() {
        let knobMode = modeControl.selectedSegmentIndex == 0
        showKnob(knobMode)
        if knobMode {
            detailLabel.text = "Each pinch (index, middle, ring, pinky) is its own knob."
        } else {
            detailLabel.text = "Swipe to move focus. Pinch to select. Hold, then twist or drag."
        }
    }

    private func enableAirGestureMode() {
        TAPKit.sharedKit.setFeature(.modelDetection, enabled: true, forIdentifiers: nil)
        TAPKit.sharedKit.setFeature(.imuMotionData, enabled: true, forIdentifiers: nil)
        TAPKit.sharedKit.setVisionSensorModel(.airGesture, forIdentifiers: nil)
        TAPKit.sharedKit.setVisionSensorOpMode(.stream, forIdentifiers: nil)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(.airMouse(), applyImmediate: true)
    }

    private func restoreTappingMode() {
        TAPKit.sharedKit.setVisionSensorModel(.tapping, forIdentifiers: nil)
        TAPKit.sharedKit.setVisionSensorOpMode(.trigger, forIdentifiers: nil)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(.tapping(), applyImmediate: true)
    }

    func tapConnected(withIdentifier identifier: String, name: String) {
        activeIdentifier = identifier
        statusLabel.text = "Connected: \(name)"
        enableAirGestureMode()
    }

    func tapDisconnected(withIdentifier identifier: String) {
        if activeIdentifier == identifier {
            activeIdentifier = nil
        }
        statusLabel.text = "Disconnected"
    }

    func tapXRAirGestured(identifier: String, gesture: TAPXRAirGesture) {
        activeIdentifier = identifier
        let now = ProcessInfo.processInfo.systemUptime
        if modeControl.selectedSegmentIndex == 0 {
            applyKnob(knob.onGesture(gesture.rawValue), identifier: identifier)
        } else {
            applyDpad(dpad.onGesture(gesture.rawValue, now: now), identifier: identifier)
        }
    }

    func moused(identifier: String, velocityX: Int16, velocityY: Int16, isMouse: Bool) {
        if isMouse == false {
            return
        }
        latestDelta = (dx: Int(velocityX), dy: Int(velocityY))
    }

    func tapDidChangeOrientation(roll: Int, pitch: Int, yaw: Int) {
        let now = ProcessInfo.processInfo.systemUptime
        if modeControl.selectedSegmentIndex == 0 {
            let steps = knob.onRoll(Double(roll))
            if steps != 0, let index = knob.active, knobValues.indices.contains(index) {
                let next = knobValues[index] + steps
                knobValues[index] = min(100, max(0, next))
                refreshKnobLabels()
                detailLabel.text = "Knob \(index)  \(knobValues[index])"
            }
            return
        }
        let sample = latestDelta
        latestDelta = (0, 0)
        applyDpad(
            dpad.onMotion(dx: sample.dx, dy: sample.dy, roll: Double(roll), now: now),
            identifier: activeIdentifier
        )
    }

    private func applyKnob(_ event: String?, identifier: String) {
        if event == "start" {
            statusLabel.text = "Knob \(knob.active ?? 0) grabbed"
            TAPKit.sharedKit.vibrate(durations: [40], forIdentifiers: [identifier])
        } else if event == "release" {
            statusLabel.text = "Released"
        }
    }

    private func applyDpad(_ events: [DpadEvent], identifier: String?) {
        for event in events {
            switch event {
            case .direction(let name):
                detailLabel.text = "Direction \(name)"
            case .pinch(let index):
                detailLabel.text = "Select \(index)"
                buzz(identifier)
            case .hold(let index):
                detailLabel.text = "Hold \(index)"
                buzz(identifier)
            case .mode(let name):
                detailLabel.text = "Mode \(name)"
                buzz(identifier)
            case .rotate(let degrees):
                padView.transform = CGAffineTransform(rotationAngle: CGFloat(degrees * 1.8) * .pi / 180)
            case .drag(let dx, let dy):
                padOffset.x += CGFloat(dx) * 0.45
                padOffset.y += CGFloat(dy) * 0.45
                padCenterX?.constant = padOffset.x
                padCenterY?.constant = padOffset.y
            case .release(_):
                detailLabel.text = "Release"
                padOffset = CGPoint.zero
                padCenterX?.constant = 0
                padCenterY?.constant = 0
                padView.transform = CGAffineTransform.identity
            case .hide:
                padView.alpha = 0.15
                detailLabel.text = "Hidden"
            case .show:
                padView.alpha = 1
                detailLabel.text = "Shown"
            }
        }
    }

    private func buzz(_ identifier: String?) {
        guard let identifier = identifier else {
            return
        }
        TAPKit.sharedKit.vibrate(durations: [40], forIdentifiers: [identifier])
    }

    private func showKnob(_ show: Bool) {
        knobStack.isHidden = show == false
        padView.isHidden = show
    }

    private func refreshKnobLabels() {
        let names = ["Index", "Middle", "Ring", "Pinky"]
        for index in 0..<knobLabels.count {
            knobLabels[index].text = "\(names[index])  \(knobValues[index])"
        }
    }

    private func buildLayout() {
        let close = UIButton(type: .system)
        close.setTitle("Done", for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .center
        detailLabel.text = "Each pinch (index, middle, ring, pinky) is its own knob."

        knobStack.axis = .vertical
        knobStack.spacing = 8
        let names = ["Index", "Middle", "Ring", "Pinky"]
        for _ in names {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
            knobLabels.append(label)
            knobStack.addArrangedSubview(label)
        }

        padView.backgroundColor = UIColor(red: 0.15, green: 0.45, blue: 0.85, alpha: 1)
        padView.layer.cornerRadius = 8

        let views = [close, modeControl, statusLabel, detailLabel, knobStack, padView]
        for subview in views {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        let safe = view.safeAreaLayoutGuide
        let centerX = padView.centerXAnchor.constraint(equalTo: safe.centerXAnchor)
        let centerY = padView.centerYAnchor.constraint(equalTo: safe.centerYAnchor, constant: 40)
        padCenterX = centerX
        padCenterY = centerY
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: safe.topAnchor, constant: 8),
            close.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            modeControl.topAnchor.constraint(equalTo: safe.topAnchor, constant: 48),
            modeControl.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 24),
            modeControl.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            statusLabel.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            detailLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            knobStack.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 24),
            knobStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 24),
            knobStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            centerX,
            centerY,
            padView.widthAnchor.constraint(equalToConstant: padWidth),
            padView.heightAnchor.constraint(equalToConstant: padWidth),
        ])
    }
}
