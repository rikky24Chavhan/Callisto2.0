//
//  MockMeal.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/23/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

class MockMeal: Meal {
    var identifier: String
    var localIdentifier: String
    var createdDate: Date
    var updatedDate: Date
    var isDirty: Bool
    var name: String
    var classification: MealClassification
    var occasions: [MealOccasion]
    var carbGrams: Double
    var hasDosingRecommendation: Bool
    var location: String?
    var portionOunces: Double
    var loggingGoal: Int
    var isHidden: Bool
    var isInvalidated: Bool

    var json: [String : Any]? {
        return nil
    }

    init(
        identifier: String = UUID().uuidString,
        name: String,
        classification: MealClassification,
        occasions: [MealOccasion] = [],
        carbGrams: Double = 0,
        hasDosingRecommendation: Bool = false,
        location: String? = nil,
        portionOunces: Double = 0,
        loggingGoal: Int = 0
    ) {
        self.identifier = identifier
        self.localIdentifier = identifier
        self.createdDate = Date()
        self.updatedDate = Date()
        self.isDirty = false
        self.name = name
        self.classification = classification
        self.occasions = occasions
        self.carbGrams = carbGrams
        self.hasDosingRecommendation = hasDosingRecommendation
        self.location = location
        self.portionOunces = portionOunces
        self.loggingGoal = loggingGoal
        self.isHidden = false
        self.isInvalidated = false
    }
}
