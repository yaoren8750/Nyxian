//
//  ProjectCell.swift
//  Nyxian
//
//  Created by FridaDEV on 16.05.25.
//

import Foundation
import UIKit

class ProjectTableCell: UITableViewCell {
    let project: AppProject
    
    init(
        project: AppProject
    ) {
        self.project = project
        super.init(style: .subtitle, reuseIdentifier: nil)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.textLabel?.text = self.project.projectConfig.displayname
        self.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        self.detailTextLabel?.text = self.project.projectConfig.bundleid
        self.detailTextLabel?.font = UIFont.systemFont(ofSize: 10)
        
        self.textLabel?.numberOfLines = 1
        self.detailTextLabel?.numberOfLines = 1
        
        self.imageView?.image = UIImage(named: "DefaultIcon")
        
        self.imageView?.translatesAutoresizingMaskIntoConstraints = false
        self.textLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.detailTextLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        let imageSize: CGFloat = 50
        NSLayoutConstraint.activate([
            self.imageView!.widthAnchor.constraint(equalToConstant: imageSize),
            self.imageView!.heightAnchor.constraint(equalToConstant: imageSize),
            self.imageView!.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.imageView!.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            self.textLabel!.leadingAnchor.constraint(equalTo: self.imageView!.trailingAnchor, constant: 16),
            self.textLabel!.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 16),
            self.textLabel!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            self.detailTextLabel!.leadingAnchor.constraint(equalTo: self.textLabel!.leadingAnchor),
            self.detailTextLabel!.topAnchor.constraint(equalTo: self.textLabel!.bottomAnchor, constant: 0),
            self.detailTextLabel!.trailingAnchor.constraint(equalTo: self.textLabel!.trailingAnchor),
            self.detailTextLabel!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -20)
        ])
        
        self.imageView?.layer.cornerRadius = 10
        self.imageView?.clipsToBounds = true
        self.imageView?.layer.borderWidth = 0.5
        self.imageView?.layer.borderColor = UIColor.gray.cgColor
        
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = .zero
        self.preservesSuperviewLayoutMargins = false
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            self.accessoryType = .disclosureIndicator
        }
    }
    
    func reload() {
        self.textLabel?.text = self.project.projectConfig.displayname
        self.detailTextLabel?.text = self.project.projectConfig.bundleid
    }
}
