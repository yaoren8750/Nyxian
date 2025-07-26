//
//  FileList+iPad.swift
//  Nyxian
//
//  Created by SeanIsTethered on 23.07.25.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    let project: AppProject
    
    init(project: AppProject) {
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
}

class SplitScreenDetailViewController: UIViewController {
    let project: AppProject
    let label = UILabel()
    var titleView: UIView?
    
    var childVCMaster: UIViewController?
    var childVC: UIViewController? {
        get {
            childVCMaster
        }
        set {
            self.navigationItem.rightBarButtonItems! = Array(self.navigationItem.rightBarButtonItems!.prefix(2))
            
            if let oldVC = childVCMaster {
                UIView.transition(with: oldVC.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    oldVC.view.alpha = 0
                }, completion: { _ in
                    oldVC.view.removeConstraints(oldVC.view.constraints)
                    oldVC.view.removeFromSuperview()
                    oldVC.removeFromParent()
                    if newValue == nil { self.navigationItem.titleView = self.titleView }
                })
            }

            if let vc = newValue {
                childVCMaster = vc
                self.addChild(vc)
                vc.view.alpha = 0
                self.view.addSubview(vc.view)
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    vc.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
                    vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
                vc.didMove(toParent: self)

                UIView.animate(withDuration: 0.3) {
                    vc.view.alpha = 1
                }

                /*let menuButton: UIButton = UIButton()
                menuButton.showsMenuAsPrimaryAction = true
                menuButton.semanticContentAttribute = .forceRightToLeft
                var bconfig = UIButton.Configuration.filled()
                bconfig.image = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
                bconfig.imagePadding = 5
                bconfig.background = .clear()
                bconfig.baseBackgroundColor = .clear
                bconfig.baseForegroundColor = currentTheme?.textColor
                bconfig.cornerStyle = .capsule
                var container = AttributeContainer()
                container.font = UIFont.boldSystemFont(ofSize: 16)
                container.foregroundColor = currentTheme?.textColor
                bconfig.attributedTitle = AttributedString(vc.title ?? "Unknown", attributes: container)
                menuButton.configuration = bconfig
                
                var items: [UIMenuElement] = []
                var buttons: [UIBarButtonItem] = []
                for item in vc.navigationItem.rightBarButtonItems ?? [] {
                    if let title = item.title {
                        items.append(UIAction(title: title, image: item.image, handler: { _ in
                            vc.perform(item.action)
                        }))
                    } else {
                        buttons.append(item)
                    }
                }
                
                let menu: UIMenu = UIMenu(options: .displayInline, children: [
                    UIMenu(options: .displayInline, children: items),
                    UIMenu(options: .displayInline, children: [
                        UIAction(title: "Close", handler: { _ in
                            self.childVC = nil
                            if let button = self.childButton {
                                self.stack.removeArrangedSubview(button)
                            }
                        })
                    ])
                ])
                menuButton.menu = menu
                self.navigationItem.titleView = menuButton
                
                if !buttons.isEmpty {
                    self.navigationItem.rightBarButtonItems?.append(makeSeparator())
                    self.navigationItem.rightBarButtonItems?.append(contentsOf: buttons)
                }*/
            }
        }
    }
    var childButton: UIButtonTab?
    
    /*
     TabBarView -> Experiment
     */
    private let tabBarView = UIView()
    private let stack = UIStackView()
    
    func addTab(vc: CodeEditorViewController) {
        let button = UIButtonTab(frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                 vc: vc) { button in
            self.childButton = button
            self.childVC = button.vc
        } closeAction: { button in
            self.childVC = nil
            if let button = self.childButton {
                self.stack.removeArrangedSubview(button)
            }
        }
        
        self.stack.addArrangedSubview(button)
    }
    
    /*
     Initial Class
     */
    init(project: AppProject) {
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
        
        self.label.textAlignment = .center
        self.label.text = "Empty"
        self.label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.label.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.label.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.label.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
        
        self.view.addSubview(self.tabBarView)
        
        self.tabBarView.backgroundColor = .clear
        self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.tabBarView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.tabBarView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.tabBarView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        self.stack.axis = .horizontal
        self.stack.alignment = .bottom
        self.stack.distribution = .fillEqually
        self.stack.translatesAutoresizingMaskIntoConstraints = false
                
        self.tabBarView.addSubview(self.stack)
        NSLayoutConstraint.activate([
            self.stack.leftAnchor.constraint(equalTo: self.tabBarView.leftAnchor),
            self.stack.rightAnchor.constraint(equalTo: self.tabBarView.rightAnchor),
            self.stack.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.stack.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor)
        ])
        
        let bottomBorderView = UIView()
        bottomBorderView.backgroundColor = currentTheme?.gutterHairlineColor
        bottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.addSubview(bottomBorderView)

        NSLayoutConstraint.activate([
            bottomBorderView.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor),
            bottomBorderView.leftAnchor.constraint(equalTo: self.tabBarView.leftAnchor),
            bottomBorderView.rightAnchor.constraint(equalTo: self.tabBarView.rightAnchor),
            bottomBorderView.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        let buildButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "play.fill"), primaryAction: UIAction { _ in
            self.buildProject()
        })
        let issueNavigator: UIBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "exclamationmark.triangle.fill"), primaryAction: UIAction { _ in
            NotificationCenter.default.post(name: Notification.Name("FileListAct"), object: ["issue"])
        })
        self.navigationItem.rightBarButtonItems = [buildButton,issueNavigator]
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMyNotification(_:)), name: Notification.Name("FileListAct"), object: nil)
    }
    
    @objc func handleMyNotification(_ notification: Notification) {
        guard let args = notification.object as? [String] else { return }
        if args.count > 1,
           args[0] == "open" {
            self.childVC = CodeEditorViewController(project: project, path: args[1])
            self.addTab(vc: self.childVC as! CodeEditorViewController)
        } else if args.count > 0,
                  args[0] == "issue" {
            self.childVC = UIDebugViewController(project: self.project)
        } else {
            return
        }
    }
    
    func makeSeparator() -> UIBarButtonItem {
        let separatorWidth: CGFloat = 1
        let separatorHeight: CGFloat = 30

        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: separatorWidth, height: separatorHeight))
        separatorView.backgroundColor = UIColor.systemGray3
        separatorView.layer.cornerRadius = separatorWidth / 2
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        let separatorItem = UIBarButtonItem(customView: separatorView)

        NSLayoutConstraint.activate([
            separatorView.widthAnchor.constraint(equalToConstant: separatorWidth),
            separatorView.heightAnchor.constraint(equalToConstant: separatorHeight)
        ])

        return separatorItem
    }
    
    private func buildProject() {
        self.navigationItem.titleView?.isUserInteractionEnabled = false
        XCodeButton.switchImageSync(systemName: "hammer.fill", animated: false)
        LDELogger.clear()
        guard let oldBarButton: UIBarButtonItem = self.navigationItem.rightBarButtonItem else { return }
        let barButton: UIBarButtonItem = UIBarButtonItem(customView: XCodeButton.shared)

        self.navigationItem.setRightBarButton(barButton, animated: true)
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        Builder.buildProject(withProject: project) { result in
            DispatchQueue.main.async {
                self.navigationItem.setRightBarButton(oldBarButton, animated: true)
                self.navigationItem.setHidesBackButton(false, animated: true)
                
                if !result {
                    NotificationCenter.default.post(name: Notification.Name("FileListAct"), object: ["issue"])
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class UIButtonTab: UIButton {
    let vc: CodeEditorViewController
    
    init(frame: CGRect,
         vc: CodeEditorViewController,
         openAction: @escaping (UIButtonTab) -> Void,
         closeAction: @escaping (UIButtonTab) -> Void) {
        self.vc = vc
        super.init(frame: frame)
        
        self.setTitle(vc.path.URLGet().lastPathComponent, for: .normal)
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
        let closeButton: UIButton = UIButton()
        closeButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: self.topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            closeButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])
        
        closeButton.showsMenuAsPrimaryAction = true
        
        // Making menu
        var items: [UIMenuElement] = []
        var buttons: [UIBarButtonItem] = []
        for item in vc.navigationItem.rightBarButtonItems ?? [] {
            if let title = item.title {
                items.append(UIAction(title: title, image: item.image, handler: { _ in
                    vc.perform(item.action)
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
