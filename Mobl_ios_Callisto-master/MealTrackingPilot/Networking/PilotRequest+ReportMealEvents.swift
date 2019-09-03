//
//  PilotRequest+ReportMealEvents.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func reportMealEvents(_ mealEvents: [MealEvent], accessCredentials: AccessCredentials?) -> PilotRequest {
        let mealEventIdentifiers: [String] = mealEvents.map { $0.identifier }
        return PilotRequest(
            method: .PATCH,
            path: "flags",
            bodyParameters: ["meal_event_ids" : mealEventIdentifiers],
            accessCredentials: accessCredentials
        )
    }
}
