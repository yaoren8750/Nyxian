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

class ProcessManagementViewController: UIThemedTableViewController {
    var processes: [LDEProcess] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Process Management"
        tableView.register(ProcessCell.self, forCellReuseIdentifier: ProcessCell.reuseID)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        processes.removeAll()
        for value in LDEProcessManager.shared().processes {
            let number = value.0 as! NSNumber
            if let proc = LDEProcessManager.shared().process(forProcessIdentifier: number.int32Value) {
                processes.append(proc)
            }
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return processes.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProcessCell.reuseID, for: indexPath) as! ProcessCell
        cell.configure(with: processes[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let process = processes[indexPath.row]
        
        let killAction = UIContextualAction(style: .destructive, title: "Kill") { _, _, completion in
            if process.terminate() {
                self.processes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                NotificationServer.NotifyUser(level: .error, notification: "Could not kill \(process.pid)")
            }
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [killAction])
    }
}
