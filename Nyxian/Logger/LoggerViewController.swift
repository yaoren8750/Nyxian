//
//  LoggerViewController.swift
//  LindDE
//
//  Created by fridakitten on 09.05.25.
//

import Foundation
import UIKit

class LoggerTextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.backgroundColor = .clear
        self.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        self.isEditable = false
        self.isSelectable = true
        
        self.text = LDELogger.log
    }
    
    convenience init() {
        self.init(frame: .zero, textContainer: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoggerView: UINavigationController {
    let loggerText: LoggerTextView = LoggerTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        let shadowImage = self.imageWithColor(color: .lightGray, size: CGSize(width: 1.0, height: 0.5))
        self.navigationController?.navigationBar.shadowImage = shadowImage
        self.navigationController?.navigationBar.setBackgroundImage(shadowImage, for: .default)
        
        let navigationBar = UINavigationBar(frame: CGRect(
            x: 0,
            y: 0,
            width: self.view.frame.size.width,
            height: 55
        ))
        
        let navItem = UINavigationItem(title: "Console")
        navigationBar.setItems([navItem], animated: true)
        self.view.addSubview(navigationBar)
        
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.insertSubview(blurView, at: 0)
        
        self.loggerText.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.loggerText)
        
        NSLayoutConstraint.activate([
            self.loggerText.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: 6),
            self.loggerText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.loggerText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            self.loggerText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0)
        ])
    }
    
    func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
