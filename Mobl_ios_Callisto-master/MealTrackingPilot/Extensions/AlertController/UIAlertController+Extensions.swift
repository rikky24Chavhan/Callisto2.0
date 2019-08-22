//
//  UIAlertController+Extensions.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 6/8/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension UIAlertController {
    class func errorAlertController(withMessage message: String, completion: (() -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { _ in
            alertController.dismiss(animated: true, completion: completion)
        }
        alertController.addAction(action)
        return alertController
    }
}
