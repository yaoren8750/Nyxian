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

class SettingsViewController: UIThemedTableViewController {
    private var hasRestoredLastSelection = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !hasRestoredLastSelection,
           let savedIndex = UserDefaults.standard.value(forKey: "LastSelectedSettingsIndex") as? Int,
           navigationController?.topViewController === self {

            hasRestoredLastSelection = true
            navigateToController(for: savedIndex, animated: false)
        } else {
            UserDefaults.standard.set(nil, forKey: "LastSelectedSettingsIndex")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator

        switch indexPath.row {
        case 0:
            cell.imageView?.image = UIImage(systemName: {
                if #available(iOS 16.0, *) {
                    return "wrench.adjustable.fill"
                } else {
                    return "gearshape.2.fill"
                }
            }())
            cell.textLabel?.text = "Toolchain"
        case 1:
            cell.imageView?.image = UIImage(systemName: "paintbrush.fill")
            cell.textLabel?.text = "Customization"
        case 2:
            cell.imageView?.image = UIImage(systemName: "tray.2.fill")
            cell.textLabel?.text = "Miscellaneous"
        case 3:
            cell.imageView?.image = UIImage(systemName: "info")
            cell.textLabel?.text = "Info"
        default:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.set(indexPath.row, forKey: "LastSelectedSettingsIndex")
        navigateToController(for: indexPath.row, animated: true)
    }

    private func navigateToController(for index: Int, animated: Bool) {
        let viewController: UIViewController

        switch index {
        case 0:
            viewController = ToolChainController(style: .insetGrouped)
        case 1:
            viewController = CustomizationViewController(style: .insetGrouped)
        case 2:
            viewController = MiscellaneousController(style: .insetGrouped)
        case 3:
            viewController = AppInfoViewController(style: .insetGrouped)
        default:
            return
        }

        navigationController?.pushViewController(viewController, animated: animated)
    }
}
