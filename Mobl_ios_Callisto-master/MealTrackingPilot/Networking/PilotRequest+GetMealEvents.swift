//
//  PilotRequest+GetMealEvents.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func getMealEvents(accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(
            method: .GET,
            path: "meal_events",
            accessCredentials: accessCredentials
        )
    }
}
