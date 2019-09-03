//
//  MealStatisticsTests.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class MealStatisticsTests: XCTestCase {
    func testSeedStatistics() {
        struct Constants {
            static let turkeyBurgerId = "local-TJTB"
            static let baconAndWafflesId = "local-Bacon-and-Waffles"
        }
        let realmConfiguration = Realm.Configuration(inMemoryIdentifier: self.name)
        guard let realm = try? Realm(configuration: realmConfiguration) else {
            XCTFail("Can create in-memory test Realm")
            return
        }

        RealmSeeder.seedRealm(realm: realm)

        let mealEvents = Array(realm.objects(RealmMealEvent.self))
        let mealStatistics = MealStatistics(mealEvents: mealEvents)

        guard
            let baconAndWaffles = realm.object(ofType: RealmMeal.self, forPrimaryKey: Constants.baconAndWafflesId),
            let turkeyBurger = realm.object(ofType: RealmMeal.self, forPrimaryKey: Constants.turkeyBurgerId)
        else {
            XCTFail("Could not find expected meals in seed data.")
            return
        }

        XCTAssertEqual(mealStatistics.totalCountForMeal(baconAndWaffles), 1, "Bacon and waffles should be logged 1 time")
        XCTAssertEqual(mealStatistics.totalCountForMeal(turkeyBurger), 2, "Turkey burger should be logged 2 times")
    }
}
