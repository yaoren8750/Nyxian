//
//  CertificateViewController.swift
//  Zeus
//
//  Created by fridakitten on 12.05.25.
//

import UIKit

class IconViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    let tableView: UITableView = UITableView(frame: .zero, style: .insetGrouped)
    var textField: UITextField?
    
    var icons: [String] = [
        "Default",
        "Drawn"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Icons"
        self.view.backgroundColor = .systemBackground
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.isScrollEnabled = false
        self.tableView.rowHeight = 65
        self.view.addSubview(self.tableView)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.icons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        let iconName = icons[indexPath.row]
        if let image = UIImage(named: "IconPreview\(iconName)") {
            let customImageView = UIImageView(image: image)
            customImageView.layer.cornerRadius = 10
            customImageView.layer.masksToBounds = true
            customImageView.translatesAutoresizingMaskIntoConstraints = false
            customImageView.contentMode = .scaleAspectFit
            cell.contentView.addSubview(customImageView)
            
            NSLayoutConstraint.activate([
                customImageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                customImageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                customImageView.widthAnchor.constraint(equalToConstant: 50),
                customImageView.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

        cell.textLabel?.text = iconName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cell.textLabel!.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            cell.textLabel!.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 80) // room for image
        ])

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let iconName: String = self.icons[indexPath.row]
        
        if iconName == "Default" {
            UIApplication.shared.setAlternateIconName(nil)
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName)
    }
}
