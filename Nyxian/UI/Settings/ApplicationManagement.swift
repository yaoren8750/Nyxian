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
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.textLabel?.text = applications[indexPath.row].bundleIdentifier
        
        return cell
    }
}
