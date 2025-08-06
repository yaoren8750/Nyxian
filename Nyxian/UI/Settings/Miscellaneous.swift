/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit

class MiscellaneousController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Miscellaneous"
        self.tableView.rowHeight = 44
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ButtonTableCell = ButtonTableCell(title: {
            switch indexPath.row {
            case 0:
                return "Import Certificate"
            case 1:
                return "Reset All"
            default:
                return "Unknown"
            }
        }())
        
        cell.button?.addAction(UIAction(handler: { _ in
            switch indexPath.row {
            case 0:
                let importPopup: CertificateImporter = CertificateImporter(style: .insetGrouped)
                let importSettings: UINavigationController = UINavigationController(rootViewController: importPopup)
                importSettings.modalPresentationStyle = .pageSheet
                
                // dynamic size
                if UIDevice.current.userInterfaceIdiom == .phone {
                    if #available(iOS 16.0, *) {
                        if let sheet = importSettings.sheetPresentationController {
                            sheet.animateChanges {
                                sheet.detents = [
                                    .custom { _ in
                                        return 200
                                    }
                                ]
                            }
                            
                            sheet.prefersGrabberVisible = true
                        }
                    }
                }
                
                self.present(importSettings, animated: true)
                break
            case 1:
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
                break
            default:
                break
            }
        }), for: .touchUpInside)
        
        return cell
    }
}
