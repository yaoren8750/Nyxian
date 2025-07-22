//
//  CertificateViewController.swift
//  Zeus
//
//  Created by fridakitten on 12.05.25.
//

import UIKit
import UniformTypeIdentifiers
import IDeviceSwift

class PairingImporter: UIThemedTableViewController, UITextFieldDelegate {
    var textField: UITextField?
    
    var pairing: ImportTableCell?
    
    let sectionTitles: [String] = [
        "Pairing",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Import Pairing"
        
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
        
        if UIDevice.current.userInterfaceIdiom == .phone {
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
            pairing = ImportTableCell(parent: self)
            cell = pairing!
            break
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
        return 1
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func importButton() {
        try? FileManager.default.moveItem(at: URL(fileURLWithPath: self.pairing!.url!.path), to: URL(fileURLWithPath: Bootstrap.shared.bootstrapPath("/pairingFile.plist")))
        
        if !FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile()) {
            NotificationServer.NotifyUser(level: .error, notification: "Importing pairing file failed!")
        }
        
        HeartbeatManager.shared.start()
        
        let status = HeartbeatManager.shared.checkSocketConnection()
        
        if !status.isConnected {
            NotificationServer.NotifyUser(level: .error, notification: "StosVPN is not running, make sure it does! Error: \(status.error ?? "Unknown")")
        }
        
        self.dismiss(animated: true)
    }
}
