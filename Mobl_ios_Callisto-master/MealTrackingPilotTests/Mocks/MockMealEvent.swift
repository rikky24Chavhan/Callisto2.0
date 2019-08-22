//
//  MockMealEvent.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/11/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

class MockMealEvent: MealEvent {
    var identifier: String
    var localIdentifier: String
    var createdDate: Date
    var updatedDate: Date
    var isDirty: Bool
    var meal: Meal
    var date: Date
    var imageURL: URL?
    var imageData: Data?
    var imageURLRequest: URLRequest?
    var portion: MealEventPortion
    var note: String
    var isFlagged: Bool
    var isInvalidated: Bool

    var json: [String : Any]? {
        return nil
    }

    var classification: MealClassification {
        return meal.classification
    }

    init(
        identifier: String = UUID().uuidString,
        meal: Meal,
        date: Date = Date(),
        imageURL: URL? = nil,
        imageData: Data? = nil,
        portion: MealEventPortion = .usual,
        note: String = ""
    ) {
        self.identifier = identifier
        self.localIdentifier = identifier
        self.createdDate = Date()
        self.updatedDate = Date()
        self.isDirty = false
        self.meal = meal
        self.date = date
        self.imageURL = imageURL
        self.imageData = imageData
        self.portion = portion
        self.note = note
        self.isFlagged = false
        self.isInvalidated = false
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return MockMealEvent(
            identifier: identifier,
            meal: meal,
            date: date,
            imageURL: imageURL,
            imageData: imageData,
            portion: portion,
            note: note)
    }
}
