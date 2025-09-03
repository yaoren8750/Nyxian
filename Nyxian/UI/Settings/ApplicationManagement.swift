/*
 Copyright (C) 2025 cr4zyengineer

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

class ApplicationManagementViewController: UIThemedTableViewController, UITextFieldDelegate {
    var applications: [LDEApplicationObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Application Management"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.applications = LDEApplicationWorkspace.shared().allApplicationObjects()
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.text = applications[indexPath.row].displayName
        cell.detailTextLabel?.text = applications[indexPath.row].bundleIdentifier
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let application = applications[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let openAction = UIAction(title: "Open", image: UIImage(systemName: "arrow.up.right.square.fill")) { _ in
                LDEMultitaskManager.shared().openApplication(withBundleIdentifier: application.bundleIdentifier)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                LDEMultitaskManager.shared().closeApplication(withBundleIdentifier: application.bundleIdentifier)
                if(LDEApplicationWorkspace.shared().deleteApplication(withBundleID: application.bundleIdentifier)) {
                    if let index = self.applications.firstIndex(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
                        self.applications.remove(at: index)
                        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
            }
            
            return UIMenu(title: "", children: [openAction, deleteAction])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let application = applications[indexPath.row]
        LDEMultitaskManager.shared().openApplication(withBundleIdentifier: application.bundleIdentifier)
    }
}
