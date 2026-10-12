// Template. Add this file to an iOS app target that embeds TAPKit.framework.
// Pair the Tap in Settings → Bluetooth before launching.

import UIKit
import TAPKit

final class QuickstartViewController: UIViewController, TAPKitDelegate {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        statusLabel.text = "Waiting for a paired TAP…"
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        TAPKit.sharedKit.addDelegate(self)
        TAPKit.sharedKit.setDefaultTAPInputMode(.controller(), immediate: true)
        TAPKit.sharedKit.setDefaultTAPXRState(.tapping(), applyImmediate: true)
        TAPKit.sharedKit.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TAPKit.sharedKit.removeDelegate(self)
    }

    func tapConnected(withIdentifier identifier: String, name: String) {
        statusLabel.text = "Connected: \(name)"
        TAPKit.sharedKit.vibrate(durations: [100, 100, 100], forIdentifiers: [identifier])
    }

    func tapDisconnected(withIdentifier identifier: String) {
        statusLabel.text = "Disconnected"
    }

    func tapFailedToConnect(withIdentifier identifier: String, name: String) {
        statusLabel.text = "Failed to connect \(name)"
    }

    func tapped(identifier: String, combination: UInt8, multitap: UInt8) {
        let fingers = TAPCombination.toFingers(combination)
        let names = ["thumb", "index", "middle", "ring", "pinky"]
        let pressed = zip(names, fingers).compactMap { name, down in down ? name : nil }
        statusLabel.text = "\(combination)  \(pressed.joined(separator: "+"))"
    }
}
