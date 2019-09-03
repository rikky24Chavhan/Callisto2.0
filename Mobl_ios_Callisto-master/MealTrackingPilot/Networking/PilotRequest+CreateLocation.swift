//
//  PilotRequest+CreateLocation.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/18/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func createLocation(_ location: Location, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(
            method: .POST,
            path: "locations",
            bodyParameters: location.json,
            accessCredentials: accessCredentials
        )
    }
}
