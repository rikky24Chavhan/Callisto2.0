//
//  MealSelectionCellViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift
@testable import MealTrackingPilot

class MealSelectionCellViewModelTests: XCTestCase {
    private let commonMealWithoutRecommendation = MockMeal(
        identifier: "TEST_FOOD_1",
        name: "Beef Graprow",
        classification: .common,
        occasions: [.snack],
        carbGrams: 42,
        hasDosingRecommendation: false,
        loggingGoal: 5
    )

    private let commonMealWithRecommendation = MockMeal(
        identifier: "TEST_FOOD_2",
        name: "Fancy Ramen",
        classification: .common,
        occasions: [.lunch],
        carbGrams: 10,
        hasDosingRecommendation: true,
        loggingGoal: 2
    )

    private let testMealWithoutRecommendation = MockMeal(
        identifier: "TEST_FOOD_3",
        name: "Turkey Burger",
        classification: .test,
        occasions: [],
        carbGrams: 0,
        hasDosingRecommendation: false,
        location: "Trader Joe's",
        portionOunces: 5,
        loggingGoal: 10
    )

    func testCommonMealNoRecommendationNoSelection() {
        let selection = MealSelection(meal: commonMealWithoutRecommendation, selected: false, timesLogged: 0)
        let sut = MealSelectionCellViewModel(mealSelection: selection)

        XCTAssertEqual(sut.mealName, "Beef Graprow")
        XCTAssertEqual(sut.selectionIconImageName, "radioOff", "Should have radio off image")
        XCTAssertTrue(sut.doseIconHidden, "No dose icon")
        XCTAssertNil(sut.dosageRecommendationText)
        XCTAssertEqual(sut.numberOfTimesMealLogged, 0)
        XCTAssertEqual(sut.mealClassification, .common)
        XCTAssertFalse(sut.mealNameFont.fontName.contains("Semibold"))
    }

    func testCommonMealNoRecommendationWithSelection() {
        let selection = MealSelection(meal: commonMealWithoutRecommendation, selected: true, timesLogged: 2)
        let sut = MealSelectionCellViewModel(mealSelection: selection)

        XCTAssertEqual(sut.mealName, "Beef Graprow")
        XCTAssertEqual(sut.selectionIconImageName, "radioOn", "Should have radio on image")
        XCTAssertTrue(sut.doseIconHidden, "No dose icon")
        XCTAssertEqual(sut.numberOfTimesMealLogged, 2)
        XCTAssert(sut.mealNameFont.fontName.contains("Semibold"))
    }

    func testMealWithRecommendationNoSelection() {
        let selection = MealSelection(meal: commonMealWithRecommendation, selected: false, timesLogged: 0)
        let sut = MealSelectionCellViewModel(mealSelection: selection)

        XCTAssertEqual(sut.mealName, "Fancy Ramen")
        XCTAssertEqual(sut.selectionIconImageName, "radioOff", "Should have radio off image")
        XCTAssertFalse(sut.doseIconHidden, "Should show dose icon")
        XCTAssertEqual(sut.dosageRecommendationText, "Dosage recommendation")
        XCTAssertEqual(sut.numberOfTimesMealLogged, 0)
    }

    func testMealWithRecommendationWithSelection() {
        let selection = MealSelection(meal: commonMealWithRecommendation, selected: true, timesLogged: 1)
        let sut = MealSelectionCellViewModel(mealSelection: selection)

        XCTAssertEqual(sut.mealName, "Fancy Ramen")
        XCTAssertEqual(sut.selectionIconImageName, "radioOn", "Should have radio on image")
        XCTAssertFalse(sut.doseIconHidden, "Should show dose icon")
        XCTAssertEqual(sut.numberOfTimesMealLogged, 1)
    }

    func testTestMealNoRecommendationNoSelection() {
        let selection = MealSelection(meal: testMealWithoutRecommendation, selected: false, timesLogged: 1)
        let sut = MealSelectionCellViewModel(mealSelection: selection)

        XCTAssertEqual(sut.mealName, "Turkey Burger")
        XCTAssertEqual(sut.selectionIconImageName, "radioOff", "Should have radio off image")
        XCTAssertTrue(sut.doseIconHidden, "No dose icon")
        XCTAssertEqual(sut.numberOfTimesMealLogged, 1)
        XCTAssertNil(sut.dosageRecommendationText)
        XCTAssertEqual(sut.mealClassification, .test)
        XCTAssertEqual(sut.mealLocationAndPortion, "Trader Joe's • 5oz")
        XCTAssertEqual(sut.mealLogGoal, 10)
    }
}
