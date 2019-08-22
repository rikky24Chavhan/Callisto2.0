//
//  TestMealProvider.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/5/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
@testable import MealTrackingPilot

enum TestMealProviderError: Error {
    case couldNotMapMealsFromJson
}

struct TestMealProvider {
    static func getMeals() throws -> [RealmMeal] {
        let bundle = Bundle(for: MealEventTests.self)
        let path = bundle.path(forResource: "test_meals", ofType: "json")!
        let data = try Data(contentsOf: URL(fileURLWithPath: path))

        let decoder = JSONDecoder.CallistoJSONDecoder()
        return try decoder.decode([RealmMeal].self, from: data)
    }
}
