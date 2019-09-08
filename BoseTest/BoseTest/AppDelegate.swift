//
//  AppDelegate.swift
//  BoseTest
//
//  Created by Carl Ekman on 2019-09-08.
//  Copyright © 2019 TrySwift. All rights reserved.
//

import UIKit
import BoseWearable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        BoseWearable.enableCommonLogging()
        BoseWearable.configure()

        return true
    }
}
