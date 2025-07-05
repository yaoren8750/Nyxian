//
//  NavigationController.swift
//  LindDE
//
//  Created by fridakitten on 06.05.25.
//

import UIKit

var currentTheme: LindDEThemer?
var currentNavigationBarAppearance = UINavigationBarAppearance()
var currentTabBarAppearance = UITabBarAppearance()

func RevertUI() {
    currentTheme = getCurrentSelectedTheme()
    
    guard let currentTheme = currentTheme else { return }
    
    currentNavigationBarAppearance.backgroundColor = currentTheme.gutterBackgroundColor
    currentNavigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: currentTheme.textColor]
    currentNavigationBarAppearance.buttonAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: currentTheme.textColor]
    currentNavigationBarAppearance.backButtonAppearance = UIBarButtonItemAppearance()
    currentNavigationBarAppearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor : currentTheme.textColor]
    
    UINavigationBar.appearance().compactAppearance = currentNavigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = currentNavigationBarAppearance
    
    if #available(iOS 15.0, *) {
        currentTabBarAppearance.configureWithOpaqueBackground()
        currentTabBarAppearance.backgroundColor = currentTheme.gutterBackgroundColor
        UITabBar.appearance().standardAppearance = currentTabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = currentTabBarAppearance
    }
    
    UITableView.appearance().backgroundColor = currentTheme.gutterBackgroundColor
    UITableViewCell.appearance().backgroundColor = currentTheme.backgroundColor
    
    UILabel.appearance().textColor = currentTheme.textColor
    UIView.appearance().tintColor = currentTheme.textColor
    
    NotificationCenter.default.post(name: Notification.Name("uiColorChangeNotif"), object: nil, userInfo: nil)
}
