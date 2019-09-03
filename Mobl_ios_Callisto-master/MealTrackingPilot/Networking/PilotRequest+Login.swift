//
//  PilotRequest+Login.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/8/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func login(credentials: LoginCredentials) -> PilotRequest {
        return PilotRequest(
            method: .POST,
            path: "users",
            authenticated: false,
            bodyParameters: credentials.httpBodyParameters()
        )
    }
}
