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

class ApplicationManagementViewController: UIThemedTableViewController, UITextFieldDelegate, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
    var applications: [LDEApplicationObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Application Management"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", image: UIImage(systemName: "plus"), target: self, action: #selector(plusButtonPressed))
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
        return NXProjectTableCell(appObject: applications[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let application = applications[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let openAction = UIAction(title: "Normal", image: UIImage(systemName: "play.fill")) { _ in
                LDEMultitaskManager.shared().openApplication(withBundleIdentifier: application.bundleIdentifier, terminateIfRunning: true, enableDebugging: false)
            }
            
            let openActionDebug = UIAction(title: "Debug", image: UIImage(systemName: "ant.fill")) { _ in
                LDEMultitaskManager.shared().openApplication(withBundleIdentifier: application.bundleIdentifier, terminateIfRunning: true, enableDebugging: true)
            }

            let openMenu: UIMenu = UIMenu(title: "Open", image: UIImage(systemName: "arrow.up.right.square.fill"), children: [openAction,openActionDebug])
            
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
            
            return UIMenu(title: "", children: [openMenu, deleteAction])
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let application = applications[indexPath.row]
        LDEMultitaskManager.shared().openApplication(withBundleIdentifier: application.bundleIdentifier)
    }
    
    @objc func plusButtonPressed() {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        DispatchQueue.global().async {
            guard let selectedURL = urls.first else { return }
            
            let fileManager = FileManager.default
            let tempRoot = NSTemporaryDirectory()
            let workRoot = (tempRoot as NSString).appendingPathComponent(UUID().uuidString)
            let unzipRoot = (workRoot as NSString).appendingPathComponent("unzipped")
            let payloadDir = (unzipRoot as NSString).appendingPathComponent("Payload")
            
            guard ((try? fileManager.createDirectory(atPath: unzipRoot, withIntermediateDirectories: true)) != nil) else { return }
            guard unzipArchiveAtPath(selectedURL.path, unzipRoot) else { return }
            var miError: AnyObject?
            guard let miBundle = MIBundle(bundleInDirectory: URL(fileURLWithPath: payloadDir), withExtension: "app", error: &miError) else { return }
            
            let bundleURL = miBundle.bundleURL!
            let lcapp = LCAppInfo(bundlePath: bundleURL.path)
            lcapp!.patchExecAndSignIfNeed(completionHandler: { [weak self] result, error in
                guard let self = self else { return }
                if result {
                    lcapp!.save()
                    let bundlePath = lcapp!.bundlePath()
                    let bundleId = lcapp!.bundleIdentifier()
                    if LDEApplicationWorkspace.shared().installApplication(atBundlePath: bundlePath) {
                        LDEMultitaskManager.shared().openApplication(withBundleIdentifier: bundleId)
                        let appObject: LDEApplicationObject = LDEApplicationWorkspace.shared().applicationObject(forBundleID: miBundle.identifier)
                        self.applications.append(appObject)
                        self.tableView.reloadData()
                    } else {
                        NotificationServer.NotifyUser(level: .error, notification: "Failed to install application.")
                    }
                    try? fileManager.removeItem(atPath: workRoot)
                } else {
                    NotificationServer.NotifyUser(level: .error, notification: "Failed to sign application.")
                }
            }, progressHandler: { _ in }, forceSign: false)
        }
    }
}
