//
//  ToolChain.swift
//  Nyxian
//
//  Created by fridakitten on 16.05.25.
//

import UIKit

class ToolChainController: UIThemedTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Toolchain"
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.rowHeight = 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "An incremental build compiles only the parts of the code that have changed, reducing build times by avoiding a full rebuild of the entire project."
        case 1:
            return "Threading in compilation refers to the compiler's ability to perform tasks in parallel like parsing, code generation, and optimization across multiple CPU threads to speed up the build process."
        case 2:
            return "The functionality makes sense when you want perfect memory management, this basically relaunches Nyxian in a smart way while preserving the UI state and restoring it very fast on reopening, this is stock on success although there is a trick that allows us to programatically relaunch the app, this might work on your device."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Features"
        case 2:
            return "Experimental"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cell = SwitchTableCell(title: "Incremental Build", key: "LDEIncrementalBuild", defaultValue: true)
            break
        case 1:
            cell = StepperTableCell(title: "Use Threads", key: "cputhreads", defaultValue: 1, minValue: 1, maxValue: getOptimalThreadCount())
            break
        case 2:
            if indexPath.row == 0 {
                cell = SwitchTableCell(title: "Restart App (On Failure)", key: "LDEReopen", defaultValue: false)
            } else {
                cell = SwitchTableCell(title: "Restart App (On Succeed)", key: "LDEReopenSucceed", defaultValue: true)
            }
        default:
            cell = UITableViewCell()
        }
        
        return cell
    }
}
