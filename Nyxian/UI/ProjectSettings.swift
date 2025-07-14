//
//  ProjectSettings.swift
//  Nyxian
//
//  Created by SeanIsTethered on 13.07.25.
//

import Foundation
import UIKit

class ProjectSettingsViewController: UITableViewController {
    let project: AppProject
    
    let vtkey: [[(String, String, String)]]
    
    init(style: UITableView.Style,
         project: AppProject) {
        self.project = project
        self.vtkey = [
            [
                (self.project.projectConfig.displayname,"Display Name","LDEDisplayName"),
                (self.project.projectConfig.bundleid,"BundleID","LDEBundleIdentifier"),
                (self.project.projectConfig.version,"Version","LDEBundleVersion"),
                (self.project.projectConfig.shortVersion,"Short Version","LDEBundleShortVersion")
            ],
            [
                (self.project.projectConfig.executable,"Executable","LDEExecutable"),
                (self.project.projectConfig.minimum_version,"Minimum Deployments","LDEMinimumVersion")
            ]
        ]

        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ((section == 0) ? 1 : self.vtkey[section - 1].count)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Icon"
        case 1:
            return "Info"
        case 2:
            return "Build"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section != 0 {
            let cell: TextFieldTableCellHandler = TextFieldTableCellHandler(title: self.vtkey[indexPath.section - 1][indexPath.row].1, value: self.vtkey[indexPath.section - 1][indexPath.row].0)
            cell.writeHandler = { value in
                self.project.projectConfig.writeKey(key: self.vtkey[indexPath.section - 1][indexPath.row].2, value: value)
                self.project.projectTableCell.reload()
            }
            return cell
        } else {
            let cell: UITableViewCell = UITableViewCell()
            cell.textLabel?.text = "S0n"
            return cell
        }
    }
}
