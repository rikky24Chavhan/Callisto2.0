//
//  PilotRequest+CurrentUser.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/14/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func getCurrentUser(accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(method: .GET, path: "current_user", accessCredentials: accessCredentials)
    }
}
