//
//  HomeTableViewController.swift
//  BoseTest
//
//  Created by Carl Ekman on 2019-09-08.
//  Copyright © 2019 TrySwift. All rights reserved.
//

import UIKit

class HomeTableViewController: UITableViewController {

    @IBOutlet weak var connectToLastSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
    }

    @IBAction func connectButtonTapped(_ sender: Any) {
        print("Connect!")
    }
}
