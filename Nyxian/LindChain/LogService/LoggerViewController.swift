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

import Foundation
import UIKit

class LoggerTextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.backgroundColor = UITableView.appearance().backgroundColor
        self.textColor = UILabel.appearance().textColor
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

class LoggerViewController: UIViewController {
    let loggerText: LoggerTextView = LoggerTextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .clear
        self.title = "Console"
        
        self.loggerText.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.loggerText)

        NSLayoutConstraint.activate([
            self.loggerText.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.loggerText.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.loggerText.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.loggerText.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
}
