//
//  FileList+iPad.swift
//  Nyxian
//
//  Created by SeanIsTethered on 23.07.25.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    let project: AppProject
    let path: String
    
    init(project: AppProject, path: String) {
        self.project = project
        self.path = path
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let masterVC = FileListViewController(project: project, path: path)
        let detailVC = CodeEditorViewController(project: project, path: path.URLGet().appendingPathComponent("Config").appendingPathComponent("Project.plist").path)

        let masterNav = UINavigationController(rootViewController: masterVC)
        let detailNav = UINavigationController(rootViewController: detailVC)

        self.viewControllers = [masterNav, detailNav]
        self.delegate = self
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
