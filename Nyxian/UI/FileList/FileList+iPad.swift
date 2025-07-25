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
        super.init(style: .doubleColumn)
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
        
        self.setViewController(masterNav, for: .primary)
        self.setViewController(detailNav, for: .secondary)
        
        self.preferredDisplayMode = .oneBesideSecondary
        self.preferredSplitBehavior = .tile
        self.displayModeButtonVisibility = .never
        self.primaryEdge = .leading

        self.delegate = self
    }
}

class SplitScreenDetailViewController: UIViewController {
    let project: AppProject
    let label = UILabel()
    
    var childVCMaster: UIViewController?
    var childVC: UIViewController? {
        get {
            childVCMaster
        }
        set {
            if let oldVC = childVCMaster {
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParent()
            }
            if let vc = newValue {
                childVCMaster = vc
                self.addChild(vc)
                self.view.addSubview(vc.view)
                vc.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    vc.view.topAnchor.constraint(equalTo: view.topAnchor),
                    vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
                vc.didMove(toParent: self)
            }
        }
    }
    
    var lastPathOpenedInProject: String? {
        get {
            return UserDefaults.standard.string(forKey: "\(project.getUUID()).lastPathOpenedInProject")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "\(project.getUUID()).lastPathOpenedInProject")
        }
    }
    
    init(project: AppProject) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
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
            //self.title = args[1].URLGet().lastPathComponent
            //self.label.text = args[1]
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
                
                if result && self.project.projectConfig.restartAppOnSucceed {
                    exit(0)
                } else if !result {
                    if self.project.projectConfig.restartAppOnSucceed {
                        restartProcess()
                    } else {
                        let loggerView = UINavigationController(rootViewController: UIDebugViewController(project: self.project))
                        loggerView.modalPresentationStyle = .formSheet
                        self.present(loggerView, animated: true)
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
