//
//  LogMealEventViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift
import Intrepid
@testable import MealTrackingPilot

class LogMealEventViewModelTests: XCTestCase {
    private let mockMeals: [Meal] = [
        MockMeal(identifier: "mock-meal-0", name: "Apple", classification: .common, occasions: [.snack], carbGrams: 2, hasDosingRecommendation: false, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-1", name: "Baked Potato", classification: .common, occasions: [.dinner], carbGrams: 20, hasDosingRecommendation: true, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-2", name: "T-Bone Steak", classification: .common, occasions: [.snack, .dinner, .drink], carbGrams: 8, hasDosingRecommendation: true, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-3", name: "Kathy's Favorite Orange Soda", classification: .common, occasions: [.drink], carbGrams: 6, hasDosingRecommendation: false, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-4", name: "Pizza on a Bagel", classification: .common, occasions: [], carbGrams: 6, hasDosingRecommendation: false, loggingGoal: 0),
    ]

    private let bag = DisposeBag()

    func testNoFilter() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)

        XCTAssertNil(sut.selectedOccasion.value, "Default occasion filter set to nil")
        XCTAssertEqual(sut.mealSelectionCellViewModels.count, mockMeals.count)

        let expectedMealNames = mockMeals.map { $0.name }
        let viewModelNames = sut.mealSelectionCellViewModels.map { $0.mealName }
        XCTAssertEqual(viewModelNames, expectedMealNames, "Item view models correctly populated.")
    }

    func testFilterSnack() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)
        sut.selectedOccasion.value = .snack

        let expectedMealNames = [
            "Apple",
            "T-Bone Steak",
        ]
        let viewModelNames = sut.mealSelectionCellViewModels.map { $0.mealName }
        XCTAssertEqual(viewModelNames, expectedMealNames, "Item view models correctly populated.")
    }

    func testFilterDinner() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)
        sut.selectedOccasion.value = .dinner

        let expectedMealNames = [
            "Baked Potato",
            "T-Bone Steak",
        ]
        let viewModelNames = sut.mealSelectionCellViewModels.map { $0.mealName }
        XCTAssertEqual(viewModelNames, expectedMealNames, "Item view models correctly populated.")
    }

    func testFilterDrink() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)
        sut.selectedOccasion.value = .drink

        let expectedMealNames = [
            "T-Bone Steak",
            "Kathy's Favorite Orange Soda",
        ]
        let viewModelNames = sut.mealSelectionCellViewModels.map { $0.mealName }
        XCTAssertEqual(viewModelNames, expectedMealNames, "Item view models correctly populated.")
    }

    func testSelection() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)

        let buttonEnabledVariable = Variable(false)
        sut.nextStepButtonEnabled
            .bind(to: buttonEnabledVariable)
            .disposed(by: bag)

        XCTAssertEqual(sut.mealSelectionCellViewModels[0].selectionIconImageName, "radioOff", "Should have radio off image")
        XCTAssertFalse(buttonEnabledVariable.value, "Cannot continue with 0 meals selected")

        sut.didToggleSelectionForMeal(at: IndexPath(row: 0, section: 0))

        XCTAssertEqual(sut.mealSelectionCellViewModels[0].selectionIconImageName, "radioOn", "Should have radio on image")
        XCTAssertTrue(buttonEnabledVariable.value, "Can continue with 1 meal selected")

        sut.didToggleSelectionForMeal(at: IndexPath(row: 0, section: 0))

        XCTAssertEqual(sut.mealSelectionCellViewModels[0].selectionIconImageName, "radioOff", "Should have radio off image")
        XCTAssertFalse(buttonEnabledVariable.value, "Should deselect: Cannot continue with 0 meals selected")
    }

    func testOnlyAllowsSingleSelection() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)

        let buttonEnabledVariable = Variable(false)
        sut.nextStepButtonEnabled
            .bind(to: buttonEnabledVariable)
            .disposed(by: bag)

        XCTAssertFalse(sut.mealSelectionCellViewModels[0].mealSelection.selected, "Cell 0 should not be selected")
        XCTAssertFalse(sut.mealSelectionCellViewModels[1].mealSelection.selected, "Cell 1 should not be selected")
        XCTAssertFalse(buttonEnabledVariable.value, "Cannot continue with 0 meals selected")

        sut.didToggleSelectionForMeal(at: IndexPath(row: 0, section: 0))

        XCTAssert(sut.mealSelectionCellViewModels[0].mealSelection.selected, "Cell 0 should be selected")
        XCTAssertFalse(sut.mealSelectionCellViewModels[1].mealSelection.selected, "Cell 1 should not be selected")
        XCTAssertTrue(buttonEnabledVariable.value, "Can continue with 1 meal selected")

        sut.didToggleSelectionForMeal(at: IndexPath(row: 1, section: 0))

        XCTAssertFalse(sut.mealSelectionCellViewModels[0].mealSelection.selected, "Cell 0 should not be selected")
        XCTAssert(sut.mealSelectionCellViewModels[1].mealSelection.selected, "Cell 1 should be selected")
        XCTAssertTrue(buttonEnabledVariable.value, "Can continue with 1 meal selected")

        sut.didToggleSelectionForMeal(at: IndexPath(row: 1, section: 0))

        XCTAssertFalse(sut.mealSelectionCellViewModels[0].mealSelection.selected, "Cell 0 should not be selected")
        XCTAssertFalse(sut.mealSelectionCellViewModels[1].mealSelection.selected, "Cell 1 should not be selected")
        XCTAssertFalse(buttonEnabledVariable.value, "Cannot continue with 0 meals selected")
    }

    func testEditMode() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common, mode: .edit)

        XCTAssertEqual(sut.navigationTitle, "Edit Meal")
        XCTAssertEqual(sut.nextButtonTitle, "Update Meal")
    }

    func testClassificationProperties() {
        let commonSUT = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common, mode: .create)
        XCTAssert(commonSUT.allowsAddNewMeal)
        XCTAssertFalse(commonSUT.isOccasionPickerHidden)
        XCTAssertEqual(commonSUT.navigationTitle, "Log Common Meal")
        XCTAssertEqual(commonSUT.gradientStartColor, UIColor.piCommonMealGradientStartColor)
        XCTAssertEqual(commonSUT.gradientFinishColor, UIColor.piCommonMealGradientFinishColor)

        let testSUT = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .test, mode: .create)
        XCTAssertFalse(testSUT.allowsAddNewMeal)
        XCTAssert(testSUT.isOccasionPickerHidden)
        XCTAssertEqual(testSUT.navigationTitle, "Log Test Meal")
        XCTAssertEqual(testSUT.gradientStartColor, UIColor.piTestMealButtonGradientStartColor)
        XCTAssertEqual(testSUT.gradientFinishColor, UIColor.piTestMealButtonGradientFinishColor)
    }

    func testSelectedIndexPath() {
        let sut = LogMealEventViewModel(mealDataController: MockMealDataController(mockMeals: mockMeals), mealClassification: .common)

        XCTAssertNil(sut.selectedIndexPath, "Initially there should be no selection")

        let indexPath = IndexPath(row: 0, section: 0)
        sut.didToggleSelectionForMeal(at: indexPath)
        XCTAssertEqual(sut.selectedIndexPath, indexPath, "Selected index path should be correctly reflected")
    }
}
