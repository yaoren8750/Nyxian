//
//  Main.swift
//  Nyxian
//
//  Created by fridakitten on 14.05.25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        print("Meow")
        
        let tabViewController: UITabBarController = UITabBarController()
        
        let contentViewController: ContentViewController = ContentViewController(path: "\(NSHomeDirectory())/Documents/Projects")
        let settingsViewController: SettingsViewController = SettingsViewController()
        
        let projectsNavigationController: UINavigationController = UINavigationController(rootViewController: contentViewController)
        let settingsNavigationController: UINavigationController = UINavigationController(rootViewController: settingsViewController)
        
        projectsNavigationController.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "square.grid.2x2.fill"), tag: 0)
        settingsNavigationController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)

        tabViewController.viewControllers = [projectsNavigationController, settingsNavigationController]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = tabViewController
        window?.makeKeyAndVisible()

        return true
    }
}
