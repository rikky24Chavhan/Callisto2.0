//
//  Int+Extensions.swift
//  MealTrackingPilot
//
//  Created by Litteral, Maximilian on 10/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

extension Int {
    var layoutPriority: UILayoutPriority {
        return UILayoutPriority(Float(self))
    }
}
