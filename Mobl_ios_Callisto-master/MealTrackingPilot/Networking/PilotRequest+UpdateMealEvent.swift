//
//  PilotRequest+UpdateMealEvent.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 5/11/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func updateMealEvent(_ mealEvent: MealEvent, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(
            method: .PATCH,
            path: "meal_events/\(mealEvent.identifier)",
            bodyParameters: mealEvent.json,
            accessCredentials: accessCredentials
        )
    }
}
