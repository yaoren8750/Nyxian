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
            if let oldVC = childVCMaster {
                UIView.transition(with: oldVC.view, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    oldVC.view.alpha = 0
                }, completion: { _ in
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
                    vc.view.topAnchor.constraint(equalTo: view.topAnchor),
                    vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
                vc.didMove(toParent: self)

                UIView.animate(withDuration: 0.3) {
                    vc.view.alpha = 1
                }

                let menuButton: UIButton = UIButton()
                menuButton.showsMenuAsPrimaryAction = true
                menuButton.semanticContentAttribute = .forceRightToLeft
                var bconfig = UIButton.Configuration.filled()
                bconfig.image = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
                bconfig.imagePadding = 5
                bconfig.background = .clear()
                bconfig.baseBackgroundColor = .clear
                bconfig.cornerStyle = .capsule
                var container = AttributeContainer()
                container.font = UIFont.boldSystemFont(ofSize: 16)
                container.foregroundColor = currentTheme?.textColor
                bconfig.attributedTitle = AttributedString(vc.title ?? "Unknown", attributes: container)
                menuButton.configuration = bconfig
                
                var items: [UIMenuElement] = []
                for item in vc.navigationItem.rightBarButtonItems ?? [] {
                    items.append(UIAction(title: item.title ?? "Unknown", image: item.image, handler: { _ in
                        vc.perform(item.action)
                    }))
                }
                
                let menu: UIMenu = UIMenu(options: .displayInline, children: [
                    UIMenu(options: .displayInline, children: items),
                    UIMenu(options: .displayInline, children: [
                        UIAction(title: "Close", handler: { _ in self.childVC = nil })
                    ])
                ])
                menuButton.menu = menu
                self.navigationItem.titleView = menuButton
            }
        }
    }
    
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
        } else if args.count > 0,
                  args[0] == "issue" {
            self.childVC = UIDebugViewController(project: self.project)
        } else {
            return
        }
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
