//
//  HomeTableViewController.swift
//  BoseTest
//
//  Created by Carl Ekman on 2019-09-08.
//  Copyright © 2019 TrySwift. All rights reserved.
//

import UIKit
import BoseWearable

class HomeTableViewController: UITableViewController {

    @IBOutlet weak var connectToLastSwitch: UISwitch!

    private var mode: ConnectUIMode {
        return connectToLastSwitch.isOn
            ? .connectToLast(timeout: 5)
            : .alwaysShow
    }

    @IBAction func connectButtonTapped(_ sender: Any) {
        let sensorIntent = SensorIntent(sensors: [.gameRotation, .accelerometer], samplePeriods: [._20ms])
        let gestureIntent = GestureIntent(gestures: [.input])

        BoseWearable.shared.startConnection(mode: mode, sensorIntent: sensorIntent, gestureIntent: gestureIntent) { result in
            switch result {
            case .success(let session):
                print(session)
                navigateToVC(for: session)

            case .failure(let error):
                print(error)
                break

            case .cancelled:
                break
            }
        }

        func navigateToVC(for session: WearableDeviceSession) {
            guard let vc = storyboard?.instantiateViewController(withIdentifier: "DeviceViewController") as? DeviceViewController else {
                fatalError("Cannot instantiate view controller")
            }

             vc.session = session
            show(vc, sender: self)
        }
    }
}
