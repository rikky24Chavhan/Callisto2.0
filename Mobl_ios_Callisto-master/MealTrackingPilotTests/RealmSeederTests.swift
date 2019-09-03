//
//  RealmSeederTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/28/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class RealmSeederTests: XCTestCase {
    func testSeededData() {
        let realmConfiguration = Realm.Configuration(inMemoryIdentifier: self.name)
        guard let realm = try? Realm(configuration: realmConfiguration) else {
            XCTFail("Can create in-memory test Realm")
            return
        }

        RealmSeeder.seedRealm(realm: realm)

        let mealEvents = realm.objects(RealmMealEvent.self)
        let meals = realm.objects(RealmMeal.self)

        XCTAssertEqual(mealEvents.count, 5, "Should seed with meal events.")
        XCTAssertEqual(meals.count, 4, "Should seed with meals.")

        for mealEvent in mealEvents {
            XCTAssert(mealEvent.meal.identifier.ip_length > 0, "Each meal event should have a valid meal")
        }
    }
}
