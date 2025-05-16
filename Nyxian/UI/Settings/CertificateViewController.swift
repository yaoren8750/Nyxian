//
//  CertificateViewController.swift
//  Zeus
//
//  Created by fridakitten on 12.05.25.
//

import UIKit
import UniformTypeIdentifiers

class CertificateImporter: UITableViewController, UITextFieldDelegate {
    var textField: UITextField?
    
    var cert: ImportTableCell?
    var prov: ImportTableCell?
    
    let sectionTitles: [String] = [
        "Certificate",
        "Mobileprovision",
        "Password"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Import Certificate"
        
        let importButton: UIBarButtonItem = UIBarButtonItem(
            title: "Submit",
            style: .done,
            target: self,
            action: #selector(importButton)
        )
        self.navigationItem.setRightBarButton(importButton, animated: true)
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.isScrollEnabled = false
        self.tableView.rowHeight = 44
        
        if #available(iOS 16.0, *) {
            if let sheet = self.navigationController?.sheetPresentationController {
                DispatchQueue.main.async {
                    sheet.animateChanges {
                        sheet.detents = [
                            .custom { context in
                                let contentHeight = self.tableView.contentSize.height + 50
                                return contentHeight
                            }
                        ]
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            cert = ImportTableCell(parent: self)
            cell = cert!
            //cell.textLabel?.text = "Import"
            break
        case 1:
            prov = ImportTableCell(parent: self)
            cell = prov!
            break
        case 2:
            cell = UITableViewCell()
            self.textField = UITextField(frame: CGRect(x: 15, y: 0, width: tableView.frame.width - 30, height: 44))
            self.textField?.placeholder = "ie. 123456"
            self.textField?.delegate = self
            cell.contentView.addSubview(textField!)
        default:
            cell = UITableViewCell()
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func importButton() {
        try? FileManager.default.removeItem(atPath: CertBlob.getSelectedCertBlobPath())
        
        CertBlob.createCertBlob(
            p12Path: self.cert!.url!.path,
            mpPath: self.prov!.url!.path,
            password: textField?.text ?? "",
            name: "Meow"
        )
        
        self.dismiss(animated: true)
    }
}
