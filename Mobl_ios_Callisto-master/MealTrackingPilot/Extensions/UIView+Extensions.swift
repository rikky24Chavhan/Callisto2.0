//
//  UIView+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UIView {
    func copyView() -> UIView? {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as? UIView
    }
}
