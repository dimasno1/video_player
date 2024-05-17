//
//  AppDelegate.swift
//  video-player
//
//  Created by Dzmitry Paplauski on 10.05.24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    let context = AppContext()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = GalleryModule.create(context: context)
        window?.makeKeyAndVisible()

        return true
    }
}

