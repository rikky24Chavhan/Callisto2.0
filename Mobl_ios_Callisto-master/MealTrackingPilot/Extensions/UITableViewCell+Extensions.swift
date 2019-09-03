//
//  UITableViewCell+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import Intrepid

extension UITableViewCell {
    public static var cellIdentifier: String {
        return String(describing: self)
    }

    public static func registerCell(_ tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: cellIdentifier)
    }

    public static func registerNib(_ tableView: UITableView) {
        tableView.register(ip_nib, forCellReuseIdentifier: cellIdentifier)
    }
}
