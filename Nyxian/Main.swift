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
        let tabViewController: UITabBarController = UITabBarController()
        
        let contentViewController: ContentViewController = ContentViewController(path: "\(NSHomeDirectory())/Documents/Projects")
        let settingsViewController: SettingsViewController = SettingsViewController(style: .insetGrouped)
        
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

extension UIApplication {
    func relaunch() {
        pthread_dispatch {
            pthread_dispatch {
                while true {
                    LSApplicationWorkspace.default().openApplication(withBundleID: Bundle.main.bundleIdentifier)
                }
            }
            
            usleep(500)
            exit(0)
        }
    }
}
