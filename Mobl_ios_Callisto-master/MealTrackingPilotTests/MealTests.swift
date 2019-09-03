//
//  MealTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/5/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class MealTests: XCTestCase {
    lazy var meals: [Meal] = try! TestMealProvider.getMeals()

    private func testMeal(at index: Int) -> Meal? {
        guard index < meals.count && index >= 0 else {
            return nil
        }
        return meals[index]
    }

    func testMealInitWithJsonWithOneOccasion() {
        guard let sut = testMeal(at: 0) else {
            XCTFail("Failed to create Meal")
            return
        }
        XCTAssertEqual(sut.identifier, "test-meal-id-0")
        XCTAssertEqual(sut.name, "Mark's Test Meal")
        XCTAssertEqual(sut.classification, .common)
        XCTAssertEqual(sut.occasions, [.breakfast])
    }

    func testMealInitWithJsonWithMultipleOccasions() {
        guard let sut = testMeal(at: 1) else {
            XCTFail("Failed to create Meal")
            return
        }
        XCTAssertEqual(sut.identifier, "test-meal-id-1")
        XCTAssertEqual(sut.name, "Andrew's Test Meal 1")
        XCTAssertEqual(sut.classification, .common)
        XCTAssertEqual(sut.occasions, [.breakfast, .lunch])
    }

    func testMealInitWithJsonWithNoOccasions() {
        guard let sut = testMeal(at: 2) else {
            XCTFail("Failed to create Meal")
            return
        }
        XCTAssertEqual(sut.identifier, "test-meal-id-2")
        XCTAssertEqual(sut.name, "Andrew's Test Meal 2")
        XCTAssertEqual(sut.classification, .common)
        XCTAssertEqual(sut.occasions, [])
    }
}
