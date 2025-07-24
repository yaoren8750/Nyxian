//
//  FileList+iPad.swift
//  Nyxian
//
//  Created by SeanIsTethered on 23.07.25.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    let project: AppProject
    
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
        let masterVC = FileListViewController(project: project)
        let detailVC = CodeEditorViewController(project: project, path: (self.lastPathOpenedInProject != nil) ? "\(self.project.getPath())/\(self.lastPathOpenedInProject!)" : project.getPath().URLGet().appendingPathComponent("Config").appendingPathComponent("Project.plist").path)

        let masterNav = UINavigationController(rootViewController: masterVC)
        let detailNav = UINavigationController(rootViewController: detailVC)

        self.viewControllers = [masterNav, detailNav]
        self.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleMyNotification(_:)), name: Notification.Name("FileListAct"), object: nil)
    }
    
    private var blurViewTag = 999_001

    @objc func handleMyNotification(_ notification: Notification) {
        guard
            let args = notification.object as? [String],
            args.count > 1,
            args[0] == "open"
        else { return }
        
        self.lastPathOpenedInProject = relativePath(from: self.project.getPath().URLGet(), to: args[1].URLGet())

        DispatchQueue.main.async {
            let blur = self.addBlur(on: self.viewControllers[1].view, alpha: 0.0)
            UIView.animate(withDuration: 0.20, animations: {
                blur.alpha = 1
            }, completion: { _ in
                let editor = CodeEditorViewController(project: self.project, path: args[1])
                let nav = UINavigationController(rootViewController: editor)

                self.viewControllers[1] = nav
                let blur = self.addBlur(on: self.viewControllers[1].view, alpha: 1.0)
                
                UIView.animate(withDuration: 0.20, delay: 0.05, options: .curveEaseInOut, animations: {
                    blur.alpha = 0
                }, completion: { _ in
                    blur.removeFromSuperview()
                })
            })
        }
    }

    private func addBlur(on hostView: UIView, alpha: Double = 1.0) -> UIVisualEffectView {
        if let existing = hostView.viewWithTag(blurViewTag) as? UIVisualEffectView {
            return existing
        }

        let effect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.tag = blurViewTag
        blurView.alpha = alpha
        blurView.frame = hostView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostView.addSubview(blurView)
        return blurView
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class DetailViewController: UIViewController {
    var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
        label.frame = view.bounds
        label.textAlignment = .center
        view.addSubview(label)
    }
}
