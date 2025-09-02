//
//  ApplicationManagement.swift
//  Nyxian
//
//  Created by SeanIsTethered on 02.09.25.
//

class ApplicationManagementViewController: UIThemedTableViewController, UITextFieldDelegate {
    var applications: [LDEApplicationObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Application Management"
        
        self.applications = LDEApplicationWorkspace.shared().allApplicationObjects()
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
                LDEMultitaskManager.shared().openApplication(withBundleID: application.bundleIdentifier)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill"), attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                LDEMultitaskManager.shared().terminateApplication(withBundleID: application.bundleIdentifier)
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
}
