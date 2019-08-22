//
//  UITableViewHeaderFooterView+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UITableViewHeaderFooterView {
    public static var headerFooterIdentifier: String {
        return String(describing: self)
    }

    public static func registerHeaderFooterView(_ tableView: UITableView) {
        tableView.register(self, forHeaderFooterViewReuseIdentifier: headerFooterIdentifier)
    }

    public static func registerNib(_ tableView: UITableView) {
        tableView.register(ip_nib, forHeaderFooterViewReuseIdentifier: headerFooterIdentifier)
    }
}
