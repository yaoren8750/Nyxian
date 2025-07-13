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
    
    init(style: UITableView.Style,
         project: AppProject) {
        self.project = project
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let value: String
        let title: String
        let key: String
        
        switch indexPath.row {
        case 0:
            value = self.project.projectConfig.executable
            title = "Executable"
            key = "LDEExecutable"
            break
        case 1:
            value = self.project.projectConfig.displayname
            title = "Display Name"
            key = "LDEDisplayName"
            break
        default:
            value = "NULL"
            title = "NULL"
            key = "NULL"
            break
        }
        
        let cell: TextFieldTableCellHandler = TextFieldTableCellHandler(title: title, value: value)
        cell.writeHandler = { value in
            self.project.projectConfig.writeKey(key: key, value: value)
            self.project.projectTableCell.reload()
        }
        
        return cell
    }
}
