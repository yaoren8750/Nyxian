//
//  NavigationController.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

import UIKit

func RevertUI() {
    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.backgroundColor = UIColor.systemBackground
    let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
    navigationBarAppearance.titleTextAttributes = titleAttributes
    let buttonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    navigationBarAppearance.buttonAppearance.normal.titleTextAttributes = buttonAttributes
    let backItemAppearance = UIBarButtonItemAppearance()
    backItemAppearance.normal.titleTextAttributes = [.foregroundColor : UIColor.label]
    navigationBarAppearance.backButtonAppearance = backItemAppearance
    let blurEffect = UIBlurEffect(style: .light)
    UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance?.backgroundEffect = blurEffect
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor.systemBackground
    if #available(iOS 15.0, *) {
        UITabBar.appearance().scrollEdgeAppearance = appearance
    } else {
        // Fallback on earlier versions
    }
}
