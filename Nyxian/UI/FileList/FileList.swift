//
//  FileList.swift
//  LindDE
//
//  Created by lindsey on 05.05.25.
//

import UIKit

class FileListViewController: UITableViewController {
    static var buildCancelled: Bool = false
    let project: AppProject
    let path: String
    var entries: [FileListEntry]
    let isSublink: Bool
    
    init(
        isSublink: Bool = false,
        project: AppProject,
        path: String = ""
    ) {
        Author.shared.setTargetProject(project.projectConfig.displayname)
        
        self.project = project
        self.path = path
        self.entries = FileListEntry.getEntries(ofPath: self.path)
        self.isSublink = isSublink
        super.init(nibName: nil, bundle: nil)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(performRefresh), for: .valueChanged)
    }
    
    @objc func performRefresh() {
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }

        UIView.animate(withDuration: 0.3, animations: {
            for indexPath in visibleRows {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    cell.alpha = 0
                    cell.transform = CGAffineTransform(translationX: 0, y: 20)
                }
            }
        }, completion: { _ in
            self.entries = FileListEntry.getEntries(ofPath: self.path)
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()

            let newVisibleRows = self.tableView.indexPathsForVisibleRows ?? []
            for indexPath in newVisibleRows {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    cell.alpha = 0
                    cell.transform = CGAffineTransform(translationX: 0, y: 20)
                }
            }

            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut], animations: {
                for indexPath in newVisibleRows {
                    if let cell = self.tableView.cellForRow(at: indexPath) {
                        cell.alpha = 1
                        cell.transform = .identity
                    }
                }
            }, completion: nil)

            self.refreshControl?.endRefreshing()
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // TESTING
        // Label
        let customTitleLabel = self.isSublink ? UILabel() : UIButton()
        
        if let customTitleLabel = customTitleLabel as? UILabel {
            customTitleLabel.text = self.isSublink ? URL(fileURLWithPath: self.path).lastPathComponent : project.projectConfig.displayname
            customTitleLabel.textColor = .label
            customTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        } else if let customTitleLabel = customTitleLabel as? UIButton {
            customTitleLabel.setTitle(self.isSublink ? URL(fileURLWithPath: self.path).lastPathComponent : project.projectConfig.displayname, for: .normal)
            customTitleLabel.setTitleColor(.label, for: .normal)
            customTitleLabel.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            
            var elements: [UIMenuElement] = []
            
            LDELogger.log(forProject: self.project)
                
            elements.append(UIAction(title: "Build", image: UIImage(systemName: "hammer.fill"), handler: { _ in
                self.buildProject()
            }))
            elements.append(UIAction(title: "Log", image: UIImage(systemName: "apple.terminal.fill"), handler: { _ in
                let loggerView = LoggerView()
                loggerView.modalPresentationStyle = .formSheet
                self.present(loggerView, animated: true)
            }))
            elements.append(UIAction(title: "Settings", image: {
                if #available(iOS 17.0, *) {
                    return UIImage(systemName: "gearshape.fill")
                } else {
                    return UIImage(systemName: "gear")
                }
            }(), handler: { _ in
                let loggerView = LoggerView()
                loggerView.modalPresentationStyle = .formSheet
                self.present(loggerView, animated: true)
            }))
            
            let sectionMenu: UIMenu
            
            if #available(iOS 17.0, *) {
                sectionMenu = UIMenu(options: .displayAsPalette, children: elements)
            } else {
                sectionMenu = UIMenu(children: elements)
            }
            
            customTitleLabel.menu = sectionMenu
            customTitleLabel.showsMenuAsPrimaryAction = true
        }
        
        if !self.isSublink {
            let circleDimensions: CGFloat = 20
            
            // Circle
            let circle: UIView = UIView()
            circle.backgroundColor = .systemGray5
            circle.layer.cornerRadius = circleDimensions / 2
            circle.layer.masksToBounds = true
            circle.translatesAutoresizingMaskIntoConstraints = false
            customTitleLabel.addSubview(circle)
            
            // Image
            let config: UIImage.SymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
            let image: UIImage? = UIImage(systemName: "chevron.down", withConfiguration: config)
            let imageView: UIImageView = UIImageView(image: image)
            imageView.tintColor = .systemGray
            imageView.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(imageView)
            
            // Constraints
            NSLayoutConstraint.activate([
                circle.topAnchor.constraint(equalTo: customTitleLabel.topAnchor),
                circle.bottomAnchor.constraint(equalTo: customTitleLabel.bottomAnchor),
                circle.leadingAnchor.constraint(equalTo: customTitleLabel.trailingAnchor, constant: 4),
                circle.heightAnchor.constraint(equalToConstant: circleDimensions),
                circle.widthAnchor.constraint(equalToConstant: circleDimensions),
                
                imageView.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
            ])
        }
        
        self.navigationItem.titleView = customTitleLabel
        
        let barbutton: UIBarButtonItem = UIBarButtonItem()
        barbutton.image = UIImage(systemName: "ellipsis.circle")
        // TESTING END
        
        var elements: [UIMenuElement] = []
        
        elements.append(UIAction(title: "Create", handler: { _ in
            
            enum CreateEntryMode {
                case file
                case folder
            }
            
            func createEntry(mode: CreateEntryMode) {
                let alert: UIAlertController = UIAlertController(
                    title: "Create \((mode == .file) ? "File" : "Folder")",
                    message: nil,
                    preferredStyle: .alert
                )
                
                alert.addTextField { textField in
                    textField.placeholder = "Name"
                }
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
                    let destination: URL = URL(fileURLWithPath: self.path).appendingPathComponent(alert.textFields![0].text ?? "")
                    
                    func addFile() {
                        self.entries.append(FileListEntry.getEntry(ofPath: destination.path))
                        let newIndexPath = IndexPath(row: self.entries.count - 1, section: 0)
                        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    
                    func replaceFile() {
                        let index = self.entries.firstIndex(where: { $0.name == destination.lastPathComponent} )
                        if let index {
                            self.entries.remove(at: index)
                            let oldIndexPath = IndexPath(row: index, section: 0)
                            self.tableView.deleteRows(at: [oldIndexPath], with: .automatic)
                        }
                        
                        self.entries.append(FileListEntry.getEntry(ofPath: destination.path))
                        let newIndexPath = IndexPath(row: self.entries.count - 1, section: 0)
                        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                    }
                    
                    switch mode {
                    case .folder:
                        if FileManager.default.fileExists(atPath: destination.path) {
                            let alert: UIAlertController = UIAlertController(
                                title: "Error",
                                message: "Folder with the name \"\(destination.lastPathComponent)\" already exists.",
                                preferredStyle: .alert
                            )
                            
                            alert.addAction(UIAlertAction(title: "Close", style: .default))
                            
                            self.present(alert, animated: true)
                        } else {
                            try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)
                            addFile()
                        }
                    case .file:
                        var isDirectory: ObjCBool = ObjCBool(false)
                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory) {
                            let alert: UIAlertController = UIAlertController(
                                title: isDirectory.boolValue ? "Error" : "Warning",
                                message: "\(isDirectory.boolValue ? "Folder" : "File") with the name \"\(destination.lastPathComponent)\" already exists. \(isDirectory.boolValue ? "Folder cannot be overwritten" : "Do you want to overwrite it?")",
                                preferredStyle: .alert
                            )
                            
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                            
                            if !isDirectory.boolValue {
                                alert.addAction(UIAlertAction(
                                    title: "Overwrite",
                                    style: .destructive
                                ) { _ in
                                    try? String(getFileContentForName(filename: destination.lastPathComponent)).write(to: destination, atomically: true, encoding: .utf8)
                                    replaceFile()
                                })
                            }
                            
                            self.present(alert, animated: true)
                        } else {
                            try? String(getFileContentForName(filename: destination.lastPathComponent)).write(to: destination, atomically: true, encoding: .utf8)
                            addFile()
                        }
                    }
                })
                
                self.present(alert, animated: true)
            }
            
            let actionSheet: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "File", style: .default){ _ in
                createEntry(mode: .file)
            })
            
            actionSheet.addAction(UIAlertAction(title: "Folder", style: .default) { _ in
                createEntry(mode: .folder)
            })
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            self.present(actionSheet, animated: true)
        }))
        
        let sectionMenu = UIMenu(children: elements)
        
        barbutton.menu = sectionMenu
        
        self.navigationItem.setRightBarButton(barbutton, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let customTitleLabel = self.navigationItem.titleView as? UIButton {
            self.project.projectConfig.plistHelper?.reloadIfNeeded()
            customTitleLabel.setTitle(self.project.projectConfig.displayname, for: .normal)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let entry = self.entries[indexPath.row]
            if ((try? FileManager.default.removeItem(atPath: "\(self.path)/\(entry.name)")) != nil) {
                self.entries.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entries.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if !self.navigationItem.hidesBackButton {
            let fileListEntry: FileListEntry = self.entries[indexPath.row]
            
            if fileListEntry.type == .dir {
                let fileVC = FileListViewController(
                    isSublink: true,
                    project: project,
                    path: fileListEntry.path
                )
                self.navigationController?.pushViewController(fileVC, animated: true)
            } else {
                let fileVC = UINavigationController(rootViewController: CodeEditorViewController(
                    project: project,
                    path: fileListEntry.path,
                    codeEditorConfig: project.codeEditorConfig
                ))
                fileVC.modalPresentationStyle = .overFullScreen
                self.present(fileVC, animated: true)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        let entry = self.entries[indexPath.row]
        let path = entry.path // Assuming entry.path is a valid file path as String
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        
        cell.accessoryType = (entry.type == .dir) ? .disclosureIndicator : .none
        cell.textLabel?.text = url.deletingPathExtension().lastPathComponent
        cell.separatorInset = .zero
        
        // Remove default imageView
        cell.imageView?.isHidden = true
        
        // Add custom preview icon view
        let iconView = UIView(frame: CGRect(x: 15, y: 7, width: 25, height: 25))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .light)
        label.translatesAutoresizingMaskIntoConstraints = false

        if entry.type == .file {
            switch ext {
            case "m":
                label.text = "m"
                label.textColor = .systemPurple
                iconView.addSubview(label)
            case "h":
                label.text = "h"
                label.textColor = .systemGray
                iconView.addSubview(label)
            case "c":
                label.text = "c"
                label.textColor = .systemBlue
                iconView.addSubview(label)
            case "mm":
                addStackedLabel(to: iconView, base: "m", offset: CGPoint(x: 9, y: -6), color: .systemBlue)
            case "nx":
                label.text = "n"
                label.textColor = .systemPurple
                iconView.addSubview(label)
            case "nxm":
                addStackedLabel(to: iconView, base: "n", offset: CGPoint(x: 9, y: -6), color: .systemPurple)
            case "cpp":
                addStackedLabel(to: iconView, base: "c", offset: CGPoint(x: 8, y: -5), color: .systemBlue)
            case "plist":
                addSystemImage(to: iconView, name: "tablecells.fill")
            case "swift":
                addSystemImage(to: iconView, name: "swift", tintColor: .systemRed)
            case "zip", "tar", "zst":
                addSystemImage(to: iconView, name: "doc.fill")
            case "ipa":
                addSystemImage(to: iconView, name: "app.gift.fill")
            default:
                addSystemImage(to: iconView, name: "text.page.fill")
            }
        } else {
            addSystemImage(to: iconView, name: "folder.fill", tintColor: .systemBlue)
        }
        
        cell.contentView.addSubview(iconView)

        var constraints: [NSLayoutConstraint] = [
            iconView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15),
            iconView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 25),
            iconView.heightAnchor.constraint(equalToConstant: 25)
        ]

        if label.superview != nil {
            constraints.append(contentsOf: [
                label.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
        
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cell.textLabel!.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            cell.textLabel!.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])
        
        return cell
    }
    
    private func addStackedLabel(to view: UIView, base: String, offset: CGPoint, color: UIColor) {
        let baseLabel = UILabel()
        baseLabel.text = base
        baseLabel.font = .systemFont(ofSize: 20, weight: .light)
        baseLabel.textColor = color
        baseLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let plusLabel = UILabel()
        plusLabel.text = "+"
        plusLabel.font = .systemFont(ofSize: 10, weight: .light)
        plusLabel.textColor = color
        plusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(baseLabel)
        view.addSubview(plusLabel)

        NSLayoutConstraint.activate([
            baseLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            baseLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            plusLabel.leadingAnchor.constraint(equalTo: baseLabel.trailingAnchor, constant: offset.x),
            plusLabel.topAnchor.constraint(equalTo: baseLabel.topAnchor, constant: offset.y)
        ])
    }

    private func addSystemImage(to view: UIView, name: String, tintColor: UIColor? = nil) {
        let imageView = UIImageView(image: UIImage(systemName: name))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = tintColor ?? .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func buildProject() {
        self.navigationItem.titleView?.isUserInteractionEnabled = false
        XCodeButton.switchImageSync(systemName: "hammer.fill", animated: false)
        LDELogger.clear()
        guard let oldBarButton: UIBarButtonItem = self.navigationItem.rightBarButtonItem else { return }
        let barButton: UIBarButtonItem = UIBarButtonItem(customView: XCodeButton.shared)
        
        var elements: [UIMenuElement] = []
        elements.append(UIAction(title: "Cancel", handler: { _ in
            Builder.abort = true
        }))
        
        let sectionMenu = UIMenu(options: .displayInline, children: elements)
        XCodeButton.shared.showsMenuAsPrimaryAction = true
        XCodeButton.shared.menu = sectionMenu
        
        self.navigationItem.setRightBarButton(barButton, animated: true)
        self.navigationItem.setHidesBackButton(true, animated: true)
        Builder.buildProject(withProject: project) { result in
            DispatchQueue.main.async {
                self.navigationItem.setHidesBackButton(false, animated: true)
                self.navigationItem.setRightBarButton(oldBarButton, animated: true)
                
                self.navigationItem.titleView?.isUserInteractionEnabled = true
                
                if !result {
                    let loggerView = LoggerView()
                    loggerView.modalPresentationStyle = .formSheet
                    self.present(loggerView, animated: true)
                }
            }
        }
    }
}
