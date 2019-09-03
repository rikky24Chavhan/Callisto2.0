//
//  DemoDashboardViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import XCTest
import UIKit
import Intrepid
import RxSwift

@testable import MealTrackingPilot

class DemoDashboardViewModelTests: XCTestCase {
    let mockKeychain = MockKeychain()
    let mockMealDataController = MockMealDataController()
    let mockLoginClient = MockLoginClient()
    let mockUserProvider = MockUserStorage(user: PilotUser(identifier: "test-user", userName: "Participant99", installedDate: Date() - 5.days))
    let mockAPIClient = MockPilotAPIClient()

    lazy var sut: DemoDashboardViewModel = DemoDashboardViewModel(
        keychain: self.mockKeychain,
        mealDataController: self.mockMealDataController,
        userProvider: self.mockUserProvider,
        loginClient: self.mockLoginClient
    )

    let testMealEvent = MockMealEvent(meal: MockMeal(name: "test-meal", classification: .test))
    let commonMealEvent1 = MockMealEvent(meal: MockMeal(name: "common-meal-1", classification: .common))
    let commonMealEvent2 = MockMealEvent(meal: MockMeal(name: "common-meal-2", classification: .common))

    let bag = DisposeBag()

    var logMessage: String = ""
    var suggestionMessage: String = ""
    var canLogTestMeal: Bool = false
    var canLogCommonMeal: Bool = false
    var shouldDisplayActionButton: Bool = true

    // MARK: Setup Methods

    private func showAndHideMealJournal() {
        sut.mealJournalIsDocked.value = false
        sut.mealJournalIsDocked.value = true
    }

    override func setUp() {
        super.setUp()

        sut.logMessage.subscribe(onNext: {
            self.logMessage = $0.string
        }) >>> bag
        sut.suggestionMessage.subscribe(onNext: {
            self.suggestionMessage = $0.string
        }) >>> bag
        sut.canLogTestMeal.subscribe(onNext: {
            self.canLogTestMeal = $0
        }) >>> bag
        sut.canLogCommonMeal.subscribe(onNext: {
            self.canLogCommonMeal = $0
        }) >>> bag
        sut.shouldDisplayActionButton.subscribe(onNext: {
            self.shouldDisplayActionButton = $0
        }) >>> bag

        sut.mealJournalIsDocked.value = true
    }

    // MARK: Test Methods

    func testDemoFlow() {
        // Step 0: Welcome and Enter Test Meal
        XCTAssertEqual(logMessage, "Let’s get started!")
        XCTAssertEqual(suggestionMessage, "Let’s log a Test Meal for practice. Your coordinator will help you out.")
        XCTAssertTrue(canLogTestMeal)
        XCTAssertFalse(canLogCommonMeal)
        XCTAssertFalse(shouldDisplayActionButton)

        mockMealDataController.saveMealEvent(testMealEvent, completion: nil)

        // Step 1: Reveal Meal Journal
        XCTAssertEqual(logMessage, "You have logged 1 meal for practice.")
        XCTAssertEqual(suggestionMessage, "You are doing great! Swipe up to see the meal you just logged.")
        XCTAssertFalse(canLogTestMeal)
        XCTAssertFalse(canLogCommonMeal)
        XCTAssertFalse(shouldDisplayActionButton)

        showAndHideMealJournal()

        // Step 2: Enter Common Meal
        XCTAssertEqual(logMessage, "You have logged 1 meal for practice.")
        XCTAssertEqual(suggestionMessage, "Great! Now let’s log a Common Meal.")
        XCTAssertFalse(canLogTestMeal)
        XCTAssertTrue(canLogCommonMeal)
        XCTAssertFalse(shouldDisplayActionButton)

        mockMealDataController.saveMealEvent(commonMealEvent1, completion: nil)

        // Step 3: Freeform Meal Entry
        XCTAssertEqual(logMessage, "You have logged 2 meals for practice.")
        XCTAssertEqual(suggestionMessage, "Feel free to keep logging meals for practice. Let me know when you are ready to end the demo.")
        XCTAssertTrue(canLogTestMeal)
        XCTAssertTrue(canLogCommonMeal)
        XCTAssertTrue(shouldDisplayActionButton)

        mockMealDataController.saveMealEvent(commonMealEvent2, completion: nil)

        // Step N: Etc.
        XCTAssertEqual(logMessage, "You have logged 3 meals for practice.")
        XCTAssertEqual(suggestionMessage, "Feel free to keep logging meals for practice. Let me know when you are ready to end the demo.")
        XCTAssertTrue(canLogTestMeal)
        XCTAssertTrue(canLogCommonMeal)
        XCTAssertTrue(shouldDisplayActionButton)
    }

    func testPrematureDockingDemoFlow() {
        // Step 0: Welcome and Enter Test Meal
        XCTAssertEqual(suggestionMessage, "Let’s log a Test Meal for practice. Your coordinator will help you out.")

        showAndHideMealJournal()
        mockMealDataController.saveMealEvent(testMealEvent, completion: nil)

        // Step 1: Reveal Meal Journal
        XCTAssertEqual(suggestionMessage, "You are doing great! Swipe up to see the meal you just logged.", "Premature Docking should not skip the reveal step")
    }
}
