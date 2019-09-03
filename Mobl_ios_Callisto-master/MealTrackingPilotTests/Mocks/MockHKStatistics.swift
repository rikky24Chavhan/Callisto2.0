//
//  MockHKStatistics.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import HealthKit
@testable import MealTrackingPilot

class MockHKStatistics: HKStatisticsProtocol {

    let steps: Double
    let startDate: Date
    let endDate: Date
    var hasSumQuantity = true

    init(steps: Double, startDate: Date, endDate: Date) {
        self.steps = steps
        self.startDate = startDate
        self.endDate = endDate
    }

    func sumQuantity() -> HKQuantity? {
        guard hasSumQuantity else { return nil }

        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
        return quantity
    }
}
