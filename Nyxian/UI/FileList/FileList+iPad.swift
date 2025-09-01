/*
 Copyright (C) 2025 cr4zyengineer

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

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    let project: NXProject
    
    init(project: NXProject) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let masterVC = FileListViewController(project: project)
        let detailVC = SplitScreenDetailViewController(project: project)

        let masterNav = UINavigationController(rootViewController: masterVC)
        let detailNav = UINavigationController(rootViewController: detailVC)
        
        self.viewControllers = [masterNav,detailNav]

        self.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        LDEMultitaskManager.shared().pullWindowIfExistingUp(of: self.project)
    }
}

class SplitScreenDetailViewController: UIViewController {
    let project: NXProject
    let label = UILabel()
    var titleView: UIView?
    
    var lock: NSLock = NSLock()
    var childVCMaster: UIViewController?
    var childVC: UIViewController? {
        get {
            childVCMaster
        }
        set {
            self.lock.lock()
            
            if let oldVC = childVCMaster {
                if oldVC == newValue {
                    self.lock.unlock()
                    return
                }
                
                // Animate oldVC out
                UIView.animate(withDuration: 0.3, animations: {
                    oldVC.view.alpha = 0
                }, completion: { _ in
                    oldVC.view.removeFromSuperview()
                    oldVC.removeFromParent()
                })
            }

            if let vc = newValue {
                childVCMaster = vc
                self.addChild(vc)
                vc.view.alpha = 0 // Start invisible
                self.view.addSubview(vc.view)
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    vc.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 31),
                    vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
                
                // Animate new VC in
                UIView.animate(withDuration: 0.3) {
                    vc.view.alpha = 1
                }
            }
            
            self.lock.unlock()
        }
    }
    var childButton: UIButtonTab?
    
    /*
     TabBarView -> Experiment
     */
    private let scrollView = UIScrollView()
    private let tabBarView = UIView()
    private let stack = UIStackView()
    private var tabs: [UIButtonTab] = []
    
    func addTab(path: String) {
        if let existingTab = tabs.first(where: { $0.path == path }) {
            self.childButton = existingTab
            self.childVC = existingTab.vc
            updateTabSelection(selectedTab: existingTab)
            return
        }

        let button = UIButtonTab(frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                 project: self.project,
                                 path: path) { button in
            self.childButton = button
            self.childVC = button.vc
            self.updateTabSelection(selectedTab: button)
        } closeAction: { button in
            if self.childVC == button.vc {
                self.childVC = nil
            }
            if let synpushServer = button.vc.synpushServer {
                synpushServer.deinit()
            }
            
            guard let index = self.tabs.firstIndex(of: button) else { return }
            
            self.stack.removeArrangedSubview(button)
            button.removeFromSuperview()
            self.tabs.remove(at: index)
            
            var newSelectedTab: UIButtonTab? = nil
            if self.tabs.count > 0 {
                if index < self.tabs.count {
                    newSelectedTab = self.tabs[index]
                } else if index - 1 >= 0 {
                    newSelectedTab = self.tabs[index - 1]
                }
            }
            
            if let tabToSelect = newSelectedTab {
                self.childButton = tabToSelect
                self.childVC = tabToSelect.vc
                self.updateTabSelection(selectedTab: tabToSelect)
            } else {
                self.childButton = nil
                self.childVC = nil
                self.updateTabSelection(selectedTab: nil)
            }
        }

        self.stack.addArrangedSubview(button)
        self.tabs.append(button)
        
        self.updateTabSelection(selectedTab: button)
    }
    
    /*
     Initial Class
     */
    init(project: NXProject) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
        self.titleView = self.navigationItem.titleView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Workspace"
        self.view.backgroundColor = currentTheme?.gutterBackgroundColor
        self.view.addSubview(label)
        
        // Adding the indicator of the empty editor
        self.label.textAlignment = .center
        self.label.text = "No Editor"
        self.label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.label.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.label.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.label.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
        
        // Adding the scrollview used for the file stack
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false;
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.isScrollEnabled = true
        self.view.addSubview(self.scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Adding the stack
        self.stack.backgroundColor = UIColor.clear
        self.stack.axis = .horizontal
        self.stack.alignment = .top
        self.stack.distribution = .fillProportionally
        self.stack.translatesAutoresizingMaskIntoConstraints = false
                
        self.scrollView.addSubview(self.stack)
        NSLayoutConstraint.activate([
            self.stack.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.stack.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            self.stack.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.stack.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor)
        ])
        
        let bottomBorderView = UIView()
        bottomBorderView.backgroundColor = currentTheme?.gutterHairlineColor
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(bottomBorderView)

        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            bottomBorderView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            bottomBorderView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        let buildButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "play.fill"), primaryAction: UIAction { _ in
            buildProjectWithArgumentUI(targetViewController: self, project: self.project, buildType: .RunningApp)
        })
        let packageButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "archivebox.fill"), primaryAction: UIAction { _ in
            buildProjectWithArgumentUI(targetViewController: self, project: self.project, buildType: .InstallPackagedApp)
        })
        let issueNavigator: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.triangle.fill"), primaryAction: UIAction { _ in
            let loggerView = UINavigationController(rootViewController: UIDebugViewController(project: self.project))
            loggerView.modalPresentationStyle = .formSheet
            self.present(loggerView, animated: true)
        })
        let console: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "apple.terminal.fill"), primaryAction: UIAction { _ in
            let loggerView = UINavigationController(rootViewController: LoggerViewController())
            loggerView.modalPresentationStyle = .formSheet
            self.present(loggerView, animated: true)
        })
        self.navigationItem.rightBarButtonItems = [buildButton,packageButton,issueNavigator,console]
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMyNotification(_:)), name: Notification.Name("FileListAct"), object: nil)
    }
    
    @objc func handleMyNotification(_ notification: Notification) {
        guard let args = notification.object as? [String] else { return }
        if args.count > 1,
           args[0] == "open" {
            self.addTab(path: args[1])
        } else {
            return
        }
    }
    
    private func updateTabSelection(selectedTab: UIButtonTab?) {
        let selectionColor = currentTheme?.gutterBackgroundColor ?? UIColor.systemGray4

        let selectedColor: UIColor = selectionColor
        let unselectedColor: UIColor = selectedColor.darker(by: 4)
        
        for tab in tabs {
            let targetColor: UIColor = (tab == selectedTab) ? selectedColor : unselectedColor
            let targetAlpha: CGFloat = (tab == selectedTab) ? 1.0 : 0.0
            
            UIView.animate(withDuration: 0.25) {
                tab.backgroundColor = targetColor
                tab.closeButton.alpha = targetAlpha
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class UIButtonTab: UIButton {
    let path: String
    let vc: CodeEditorViewController
    let closeButton: UIButton
    
    init(frame: CGRect,
         project: NXProject,
         path: String,
         openAction: @escaping (UIButtonTab) -> Void,
         closeAction: @escaping (UIButtonTab) -> Void) {
        self.path = path
        self.vc = CodeEditorViewController(project: project, path: path)
        self.closeButton = UIButton()
        
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false;
        
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32)
        self.setTitle(vc.path.URLGet().lastPathComponent, for: .normal)
        self.setTitleColor(currentTheme?.textColor, for: .normal)
        self.titleLabel?.font = .systemFont(ofSize: 13)
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        self.titleLabel?.textAlignment = .center
        self.layer.borderColor = UIColor.white.cgColor
        
        let leftBorderView = UIView()
        leftBorderView.backgroundColor = currentTheme?.gutterHairlineColor
        leftBorderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(leftBorderView)

        NSLayoutConstraint.activate([
            leftBorderView.leftAnchor.constraint(equalTo: self.leftAnchor),
            leftBorderView.topAnchor.constraint(equalTo: self.topAnchor),
            leftBorderView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            leftBorderView.widthAnchor.constraint(equalToConstant: 1)
        ])
        
        let rightBorderView = UIView()
        rightBorderView.backgroundColor = currentTheme?.gutterHairlineColor
        rightBorderView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(rightBorderView)

        NSLayoutConstraint.activate([
            rightBorderView.rightAnchor.constraint(equalTo: self.rightAnchor),
            rightBorderView.topAnchor.constraint(equalTo: self.topAnchor),
            rightBorderView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rightBorderView.widthAnchor.constraint(equalToConstant: 0.5)
        ])
        
        self.addAction(UIAction { _ in
            openAction(self)
        }, for: .touchUpInside)
        
        // Close button
        self.closeButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.closeButton)
        
        NSLayoutConstraint.activate([
            self.closeButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.closeButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.closeButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.closeButton.widthAnchor.constraint(equalTo: self.closeButton.heightAnchor)
        ])
        
        self.closeButton.showsMenuAsPrimaryAction = true
        
        // Open before making the menu
        openAction(self)
        
        // Making menu
        var items: [UIMenuElement] = []
        var buttons: [UIBarButtonItem] = []
        for item in vc.navigationItem.rightBarButtonItems ?? [] {
            if let title = item.title {
                items.append(UIAction(title: title, image: item.image, handler: { _ in
                    self.vc.perform(item.action)
                }))
            } else {
                buttons.append(item)
            }
        }
        
        closeButton.menu = UIMenu(options: .displayInline, children: [
            UIMenu(options: .displayInline, children: items),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Close", handler: { _ in
                    closeAction(self)
                })
            ])
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIColor {
    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        let newBrightness = max(brightness - percentage/100, 0)
        return UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}

