//
//  ViewController.swift
//  BoseTest
//
//  Created by Carl Ekman on 2019-09-08.
//  Copyright © 2019 TrySwift. All rights reserved.
//

import UIKit
import BoseWearable

class DeviceViewController: UIViewController {

    var session: WearableDeviceSession! {
        didSet {
            session?.delegate = self as? WearableDeviceSessionDelegate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
