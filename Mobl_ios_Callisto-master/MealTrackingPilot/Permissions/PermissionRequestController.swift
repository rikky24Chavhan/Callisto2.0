//
//  PermissionRequestController.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol PermissionRequestController {
    func requestPermissions(completion: @escaping () -> Void)
}
