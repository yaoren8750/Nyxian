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
        self.tableView.rowHeight = 44
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 2
        case 3:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Compilers translate human readable source code into machine code, while linkers combine compiled code and libraries into a final executable file."
        case 1:
            return "An incremental build compiles only the parts of the code that have changed, reducing build times by avoiding a full rebuild of the entire project."
        case 2:
            return "Threading in compilation refers to the compiler's ability to perform tasks in parallel like parsing, code generation, and optimization across multiple CPU threads to speed up the build process."
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "General"
        case 3:
            return "Special"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cell = PickerTableCell(
                options: (indexPath.row == 0) ? ["LLVM"] : ["GNU"],
                title: (indexPath.row == 0) ? "Compiler" : "Linker",
                key: (indexPath.row == 0) ? "LDECompiler" : "LDELinker",
                defaultValue: 0
            )
            break
        case 1:
            cell = SwitchTableCell(title: "Incremental Build", key: "LDEIncrementalBuild", defaultValue: true)
            break
        case 2:
            if indexPath.row == 0 {
                cell = SwitchTableCell(title: "Threaded Build", key: "LDEThreadedBuild", defaultValue: true)
            } else {
                cell = StepperTableCell(title: "Use Threads", key: "cputhreads", defaultValue: 0, minValue: 1, maxValue: getOptimalThreadCount())
            }
            break
        case 3:
            cell = ButtonTableCell(title: (indexPath.row == 0) ? "Import Certificate" : "Reset All")
            (cell as! ButtonTableCell).button?.addAction(UIAction(handler: { _ in
                if indexPath.row == 0 {
                    let importPopup: CertificateImporter = CertificateImporter() {}
                    let importSettings: UINavigationController = UINavigationController(rootViewController: importPopup)
                    importSettings.modalPresentationStyle = .pageSheet
                    self.present(importSettings, animated: true)
                } else {
                    let alert: UIAlertController = UIAlertController(
                        title: "Warning",
                        message: "All projects and preferences will be wiped! Are you sure you wanna proceed?",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    alert.addAction(UIAlertAction(title: "Proceed", style: .destructive) { _ in
                        if let appDomain = Bundle.main.bundleIdentifier {
                            UserDefaults.standard.removePersistentDomain(forName: appDomain)
                            UserDefaults.standard.synchronize()
                        }
                        
                        Bootstrap.shared.bootstrapVersion = 0
                        Bootstrap.shared.clearPath(path: "/")
                        restartProcess()
                    })
                    
                    self.present(alert, animated: true)
                }
            }), for: .touchUpInside)
            break
        default:
            cell = UITableViewCell()
        }
        
        return cell
    }
}
