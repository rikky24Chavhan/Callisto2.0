//
//  PilotRequest+CreateMeal.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import APIClient

extension PilotRequest {
    static func createMeal(_ meal: Meal, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(method: .POST, path: "meals", bodyParameters: meal.json, accessCredentials: accessCredentials)
    }
}
