//
//  PilotRequest+CreateStepSample.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

extension PilotRequest {
    static func createStepSample(_ stepSample: StepSample, accessCredentials: AccessCredentials?) -> PilotRequest {
        return PilotRequest(
            method: .POST,
            path: "healthkit_samples",
            bodyParameters: stepSample.json,
            accessCredentials: accessCredentials
        )
    }
}
