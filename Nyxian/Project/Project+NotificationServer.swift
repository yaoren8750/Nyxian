//
//  Project+NotificationServer.swift
//  Nyxian
//
//  Created by FridaDEV on 16.05.25.
//

import Foundation
import UIKit

func getTopViewController(base: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap { $0.windows }
    .first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
    
    if let nav = base as? UINavigationController {
        return getTopViewController(base: nav.visibleViewController)
    }
    
    if let tab = base as? UITabBarController {
        return getTopViewController(base: tab.selectedViewController)
    }
    
    if let presented = base?.presentedViewController {
        return getTopViewController(base: presented)
    }
    
    return base
}

class NotificationServer {
    enum NotifLevel: String {
        case note = "Note"
        case warning = "Warning"
        case error = "Error"
    }
    
    static func NotifyUser(
        level: NotifLevel,
        notification: String,
        delay: Double = 0.0
    ) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            DispatchQueue.main.async {
                if let rootVC = getTopViewController() {
                    let alert: UIAlertController = UIAlertController(
                        title: level.rawValue,
                        message: notification,
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Close", style: .cancel))
                    
                    rootVC.present(alert, animated: true)
                }
            }
        }
    }
}
