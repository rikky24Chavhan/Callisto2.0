//
//  PilotRequest+GetMeals.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/4/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation


extension PilotRequest {
    static func getMeals(classification: MealClassification, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(
            method: .GET,
            path: "meals",
            queryParameters: ["type" : classification.rawValue],
            accessCredentials: accessCredentials
        )
    }
}
