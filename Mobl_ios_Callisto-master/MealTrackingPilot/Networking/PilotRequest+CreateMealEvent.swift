//
//  PilotRequest+CreateMealEvent.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/30/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import APIClient

extension PilotRequest {
    static func createMealEvent(_ mealEvent: MealEvent, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(method: .POST, path: "meal_events", bodyParameters: mealEvent.json, accessCredentials: accessCredentials)
    }
}
