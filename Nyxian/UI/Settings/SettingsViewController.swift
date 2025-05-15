//
//  SettingsViewController.swift
//  LindDE
//
//  Created by fridakitten on 09.05.25.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        let button: UIButton = UIButton()
        button.setTitle((indexPath.row == 0) ? "Reset All" : "Import Certificate", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        
        if indexPath.row == 0 {
            button.addAction(UIAction(title: "Reset All", handler: { _ in
                Bootstrap.shared.bootstrapVersion = 0
                Bootstrap.shared.clearPath(path: "/")
                restartProcess()
            }), for: .touchUpInside)
        } else {
            button.addAction(UIAction(title: "Import Certificate", handler: { _ in
                let vc: CertificateImporter = CertificateImporter(completion: {})
                let navvc: UINavigationController = UINavigationController(rootViewController: vc)
                self.present(navvc, animated: true)
            }), for: .touchUpInside)
        }
        
        cell.contentView.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            button.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return cell
    }
}
