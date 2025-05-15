//
//  CertificateViewController.swift
//  Zeus
//
//  Created by fridakitten on 12.05.25.
//

import UIKit

class IconViewController: UITableViewController {
    var textField: UITextField?
    
    var icons: [String] = [
        "Default",
        "Drawn"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Icons"
        self.tableView.rowHeight = 65
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.icons.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let iconName: String = self.icons[indexPath.row]
        
        if iconName == "Default" {
            UIApplication.shared.setAlternateIconName(nil)
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName)
    }
}
