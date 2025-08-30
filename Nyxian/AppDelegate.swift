/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit

var tabViewController: UIThemedTabBarController = UIThemedTabBarController()

@objc class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let contentViewController: ContentViewController = ContentViewController(path: "\(NSHomeDirectory())/Documents/Projects")
        let settingsViewController: SettingsViewController = SettingsViewController(style: .insetGrouped)
        
        let projectsNavigationController: UINavigationController = UINavigationController(rootViewController: contentViewController)
        let settingsNavigationController: UINavigationController = UINavigationController(rootViewController: settingsViewController)
        
        projectsNavigationController.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "square.grid.2x2.fill"), tag: 0)
        settingsNavigationController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)
        
        tabViewController.viewControllers = [projectsNavigationController, settingsNavigationController]
        
        if let appException = logReadIfAvailable() {
            UserDefaults.standard.set(nil, forKey: "LDEAppException")
            
            let blurEffect: UIBlurEffect = UIBlurEffect(style: .systemMaterial)
            let blurView: UIVisualEffectView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = window!.frame
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.alpha = 1.0
            
            let label: UILabel = UILabel()
            label.text = "Guest App Crashed"
            label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false;
            
            // Candy Info :3
            var candyInfo: NSString? = nil
            if let projectSelected: String = UserDefaults.standard.string(forKey: "LDELastProjectSelected"),
               let functionName: String = appException.func {
                let project: NXProject = NXProject(path: "\(NSHomeDirectory())/Documents/Projects/\(projectSelected)")
                
                let sourceStack = FindFilesStack(project.path, ["c","cpp","m","mm"], ["Resources"])
                var objectStack: [String] = []
                for item in sourceStack {
                    objectStack.append("\(project.cachePath!)/\(expectedObjectFile(forPath: relativePath(from: project.path.URLGet(), to: item.URLGet())))")
                }
                for item in objectStack {
                    let ptr = getExceptionFromObjectFile((item as NSString).utf8String, ("\(functionName)" as NSString).utf8String, appException.offset)
                    if(ptr != nil) {
                        candyInfo = NSString(cString: ptr!, encoding: NSUTF8StringEncoding);
                    }
                }
            }
            
            let reasonLabel: UITextView = UITextView()
            reasonLabel.isEditable = false
            reasonLabel.isSelectable = true
            reasonLabel.isScrollEnabled = true
            reasonLabel.text = "\(appException.log ?? "")\n\(candyInfo ?? "Unknown file")"
            reasonLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            reasonLabel.translatesAutoresizingMaskIntoConstraints = false
            reasonLabel.backgroundColor = UIColor.systemGray3
            reasonLabel.layer.borderWidth = 1
            reasonLabel.layer.borderColor = UIColor.systemGray.cgColor
            reasonLabel.layer.cornerRadius = 15
            
            let vc: UIViewController = UIViewController()
            vc.view.addSubview(blurView)
            
            let closeButton: UIButton = self.createDebugButton(symbolName: "xmark", action: UIAction { _ in
                self.window?.rootViewController = tabViewController
                self.window?.makeKeyAndVisible()
            })
            
            let replayButton: UIButton = self.createDebugButton(symbolName: "memories", action: UIAction { _ in
                if let projectSelected: String = UserDefaults.standard.string(forKey: "LDELastProjectSelected") {
                    let project: NXProject = NXProject(path: "\(NSHomeDirectory())/Documents/Projects/\(projectSelected)")
                    UserDefaults.standard.set(project.bundlePath, forKey: "LDEAppPath")
                    UserDefaults.standard.set(project.homePath, forKey: "LDEHomePath")
                    restartProcess()
                }
            })
            
            blurView.contentView.addSubview(closeButton)
            blurView.contentView.addSubview(replayButton)
            blurView.contentView.addSubview(label)
            blurView.contentView.addSubview(reasonLabel)
            
            NSLayoutConstraint.activate([
                closeButton.centerYAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -100),
                closeButton.leftAnchor.constraint(equalTo: blurView.leftAnchor, constant: 25),
                closeButton.rightAnchor.constraint(equalTo: blurView.centerXAnchor, constant: -12.5),
                closeButton.heightAnchor.constraint(equalToConstant: 75),
                
                replayButton.centerYAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -100),
                replayButton.rightAnchor.constraint(equalTo: blurView.rightAnchor, constant: -25),
                replayButton.leftAnchor.constraint(equalTo: blurView.centerXAnchor, constant: 12.5),
                replayButton.heightAnchor.constraint(equalToConstant: 75),
                
                label.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: blurView.topAnchor, constant: 100),
                label.widthAnchor.constraint(equalTo: blurView.widthAnchor),
                label.heightAnchor.constraint(equalToConstant: 80),
                
                reasonLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
                reasonLabel.bottomAnchor.constraint(equalTo: closeButton.topAnchor, constant: -25),
                reasonLabel.leftAnchor.constraint(equalTo: blurView.leftAnchor, constant: 25),
                reasonLabel.rightAnchor.constraint(equalTo: blurView.rightAnchor, constant: -25)
            ])
            
            window?.rootViewController = vc
            window?.makeKeyAndVisible()
        } else {
            window?.rootViewController = tabViewController
            window?.makeKeyAndVisible()
        }

        return true
    }
    
    func createDebugButton(markColor: UIColor? = nil, symbolName: String, action: UIAction) -> UIButton {
        let button: UIButton = UIButton()
        button.backgroundColor = UIColor.systemGray3
        button.translatesAutoresizingMaskIntoConstraints = false;
        button.layer.cornerRadius = 15;
        button.layer.borderWidth = 1;
        
        if let markColor = markColor {
            button.layer.borderColor = markColor.cgColor;
        } else {
            button.layer.borderColor = UIColor.systemGray.cgColor;
        }

        let config: UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        let symbolImage: UIImage? = UIImage(systemName: symbolName, withConfiguration: config)
        button.setImage(symbolImage, for: .normal)
        
        if let markColor = markColor {
            button.tintColor = markColor
        } else {
            button.tintColor = UIColor.label
        }
        
        button.addAction(action, for: .touchUpInside)

        return button
    }
}
