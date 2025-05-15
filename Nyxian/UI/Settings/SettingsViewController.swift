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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = PickerTableCell(
            options: (indexPath.row == 0) ? ["LLVM"] : ["GNU"],
            title: (indexPath.row == 0) ? "Compiler" : "Linker",
            key: (indexPath.row == 0) ? "LDECompiler" : "LDELinker",
            defaultValue: 0
        )
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Toolchain Libraries"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Compilers translate human readable source code into machine code, while linkers combine compiled code and libraries into a final executable file."
    }
}
