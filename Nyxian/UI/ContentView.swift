//
//  ContentView.swift
//  LindDE
//
//  Created by lindsey on 05.05.25.
//

import Foundation
import UIKit

@objc class ContentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: CGRectNull, style: .plain)
    var projects: [AppProject] = []
    var path: String
    
    var lastProjectWasSelected: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "LDELastProjectSelectedEven")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LDELastProjectSelectedEven")
        }
    }
    var lastProjectSelected: Int {
        get {
            return UserDefaults.standard.integer(forKey: "LDELastProjectSelected")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LDELastProjectSelected")
        }
    }
    
    @objc init(path: String) {
        RevertUI()
        
        Bootstrap.shared.bootstrap()
        LDELogger.setup()
        CertBlob.startSigner()
        
        self.path = path
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Projects"
        
        let barbutton: UIBarButtonItem = UIBarButtonItem()
        barbutton.image = UIImage(systemName: "plus")
        barbutton.target = self
        barbutton.action = #selector(PlusTabbed)
        
        self.navigationItem.setRightBarButton(barbutton, animated: false)
        
        self.view.backgroundColor = .systemBackground
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 70
        
        self.view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        self.projects = AppProject.listProjects(ofPath: self.path)
        
        self.tableView.reloadData()
        
        if lastProjectWasSelected {
            if lastProjectSelected < projects.count {
                let selectedProject = projects[lastProjectSelected]
                let fileVC = FileListViewController(project: selectedProject,
                                                    path: selectedProject.getPath())
                self.navigationController?.pushViewController(fileVC, animated: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        lastProjectWasSelected = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        cell.textLabel?.text = self.projects[indexPath.row].projectConfig.executable
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        cell.detailTextLabel?.text = self.projects[indexPath.row].projectConfig.bundleid
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 10)
        
        cell.textLabel?.numberOfLines = 1
        cell.detailTextLabel?.numberOfLines = 1
        
        cell.imageView?.image = UIImage(named: "DefaultIcon")
        
        cell.imageView?.translatesAutoresizingMaskIntoConstraints = false
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        cell.detailTextLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        let imageSize: CGFloat = 50
        NSLayoutConstraint.activate([
            cell.imageView!.widthAnchor.constraint(equalToConstant: imageSize),
            cell.imageView!.heightAnchor.constraint(equalToConstant: imageSize),
            cell.imageView!.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            cell.imageView!.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            cell.textLabel!.leadingAnchor.constraint(equalTo: cell.imageView!.trailingAnchor, constant: 16),
            cell.textLabel!.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
            cell.textLabel!.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            cell.detailTextLabel!.leadingAnchor.constraint(equalTo: cell.textLabel!.leadingAnchor),
            cell.detailTextLabel!.topAnchor.constraint(equalTo: cell.textLabel!.bottomAnchor, constant: 0),
            cell.detailTextLabel!.trailingAnchor.constraint(equalTo: cell.textLabel!.trailingAnchor),
            cell.detailTextLabel!.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -20)
        ])
        
        cell.imageView?.layer.cornerRadius = 10
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 0.5
        cell.imageView?.layer.borderColor = UIColor.gray.cgColor
        
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = .zero
        cell.preservesSuperviewLayoutMargins = false
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedProject = projects[indexPath.row]
        let fileVC = FileListViewController(project: selectedProject,
                                            path: selectedProject.getPath())
        self.navigationController?.pushViewController(fileVC, animated: true)
        
        lastProjectSelected = indexPath.row
        lastProjectWasSelected = true
    }
    
    /*func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
                   point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in

            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                AppProject.removeProject(project: self.projects[indexPath.row])
                
                self.projects.remove(at: indexPath.row)
                
                self.tableView.reloadData()
            }

            return UIMenu(title: "", children: [deleteAction])
        }
    }*/
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let project = self.projects[indexPath.row]
            
            let alert: UIAlertController = UIAlertController(
                title: "Warning",
                message: "Are you sure you want to remove \"\(project.projectConfig.displayname)\"?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
                AppProject.removeProject(project: project)
                self.projects = AppProject.listProjects(ofPath: self.path)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            })
            
            self.present(alert, animated: true)
        }
    }
    
    @objc func PlusTabbed() {
        let alert = UIAlertController(title: "Create Project",
                                      message: "",
                                      preferredStyle: .alert)
        
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Name"
        }
        
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "Bundle Identifier"
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let createAction: UIAlertAction = UIAlertAction(title: "Create", style: .default) { action -> Void in
            let name = (alert.textFields![0]).text!
            let bundleid = (alert.textFields![1]).text!
            
            self.projects.append(AppProject.createAppProject(
                atPath: self.path,
                executable: name,
                bundleid: bundleid
            ))
            
            let newIndexPath = IndexPath(row: self.projects.count - 1, section: 0)
            
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(createAction)
        
        self.present(alert, animated: true)
    }
    
    @objc func GearTabbed() {
        let vc = SettingsViewController()
        let navc = UINavigationController(rootViewController: vc)
        navc.modalPresentationStyle = .formSheet
        self.present(navc, animated: true)
    }
}
