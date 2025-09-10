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

import UIKit
import UniformTypeIdentifiers

class ProcessManagementViewController: UIThemedTableViewController, UITextFieldDelegate {
    var processes: [LDEProcess] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Process Management"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for value in LDEProcessManager.shared().processes {
            let key: Any = value.0
            let number: NSNumber = key as! NSNumber
            self.processes.append(LDEProcessManager.shared().process(forProcessIdentifier: number.int32Value))
        }
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.processes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let process: LDEProcess = self.processes[indexPath.row]
        
        let cell: UITableViewCell = UITableViewCell()
        cell.textLabel?.text = "PATH: \(process.executablePath ?? "Unknown") | PID: \(process.pid) | UID: \(process.uid) | GID: \(process.gid)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
