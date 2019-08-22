//
//  DashboardViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 5/3/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import UIKit
import APIClient
import Intrepid
import SwiftDate
@testable import MealTrackingPilot
import RxSwift

class DashboardViewModelTests: XCTestCase {
    let mockKeychain = MockKeychain()
    let mockMealDataController = MockMealDataController()
    let mockLoginClient = MockLoginClient()
    let mockUserProvider = MockUserStorage(
        user: PilotUser(
            identifier: "test-user",
            userName: "Participant99",
            installedDate: Date().startOfDay.addingTimeInterval(-1)))   // Last second of previous day
    let mockAPIClient = MockPilotAPIClient()

    private let mockMeals: [Meal] = [
        MockMeal(identifier: "mock-meal-0", name: "Apple", classification: .common, occasions: [.snack], carbGrams: 2, hasDosingRecommendation: false, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-1", name: "Baked Potato", classification: .common, occasions: [.dinner], carbGrams: 20, hasDosingRecommendation: true, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-2", name: "T-Bone Steak", classification: .common, occasions: [.snack, .dinner, .drink], carbGrams: 8, hasDosingRecommendation: true, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-3", name: "Kathy's Favorite Orange Soda", classification: .common, occasions: [.drink], carbGrams: 6, hasDosingRecommendation: false, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-4", name: "Pizza on a Bagel", classification: .common, occasions: [], carbGrams: 6, hasDosingRecommendation: false, loggingGoal: 0),
        ]

    private lazy var mockMealEvents: [MealEvent] = [
        MockMealEvent(identifier: "mock-meal-event-0", meal: self.mockMeals[0], date: Date(), imageURL: nil, portion: .usual, note: ""),
        MockMealEvent(identifier: "mock-meal-event-1", meal: self.mockMeals[1], date: Date(), imageURL: nil, portion: .usual, note: "")
    ]

    lazy var sut: DashboardViewModel = DashboardViewModel(
        keychain: self.mockKeychain,
        mealDataController: self.mockMealDataController,
        userProvider: self.mockUserProvider,
        loginClient: self.mockLoginClient
    )

    let bag = DisposeBag()

    override func setUp() {
        super.setUp()

        // Just make sure something is subscribed to this observable
        sut.tableUpdateObservable.subscribe(onNext: nil) >>> bag
    }

    func testLogMessage() {
        var logMessage: String = ""

        sut.logMessage.subscribe(onNext: { attributedString in
            logMessage = attributedString.string
        }) >>> bag

        // Test initial empty state
        XCTAssertEqual(logMessage, "You haven't logged any meals today yet.")

        // 1 meal event
        mockMealDataController.saveMealEvent(mockMealEvents[0], completion: nil)
        XCTAssertEqual(logMessage, "You logged a meal today. Keep it up!")

        // 2 meal events
        mockMealDataController.saveMealEvent(mockMealEvents[1], completion: nil)
        XCTAssertEqual(logMessage, "You logged 2 meals today. Keep it up!")

        // Log message shouldn't change when we add a meal event logged more than 7 days ago
        let oldMealEvent = MockMealEvent(
            identifier: "old-meal-event",
            meal: self.mockMeals[0],
            date: Date() - 7.days,
            imageURL: nil,
            portion: .usual,
            note: "")
        mockMealDataController.saveMealEvent(oldMealEvent, completion: nil)
        XCTAssertEqual(logMessage, "You logged 2 meals today. Keep it up!")
    }

    func testSuggestionMessageFirstDayOfWeek() {
        var suggestionMessage: String = ""

        // Start at first day of the week
        sut.getCurrentDate = { Date().startWeek + 12.hours }

        sut.suggestionMessage.subscribe(onNext: { attributedString in
            suggestionMessage = attributedString.string
        }) >>> bag

        // Test initial empty state
        XCTAssertEqual(suggestionMessage, "You haven't logged any meals this week yet.")

        // 1 meal event today
        let todayMealEvent0 = MockMealEvent(
            identifier: "mock-meal-event-0",
            meal: self.mockMeals[0],
            date: Date().startWeek + 1.hour,
            imageURL: nil,
            portion: .usual,
            note: "")
        mockMealDataController.saveMealEvent(todayMealEvent0, completion: nil)
        XCTAssertEqual(suggestionMessage, "You logged 1 meal so far this week.")

        // 1 meal event today
        let todayMealEvent1 = MockMealEvent(
            identifier: "mock-meal-event-0",
            meal: self.mockMeals[0],
            date: Date().startWeek + 2.hour,
            imageURL: nil,
            portion: .usual,
            note: "")
        mockMealDataController.saveMealEvent(todayMealEvent1, completion: nil)
        XCTAssertEqual(suggestionMessage, "You logged 2 meals so far this week.")
    }

    func testSuggestionMessageLaterInWeek() {
        var suggestionMessage: String = ""

        // Start at first day of the week
        sut.getCurrentDate = { Date().startWeek + 36.hours }

        sut.suggestionMessage.subscribe(onNext: { attributedString in
            suggestionMessage = attributedString.string
        }) >>> bag

        // Test initial empty state
        XCTAssertEqual(suggestionMessage, "You seem to have missed logging yesterday. Great to have you back!\nYou haven't logged any meals this week yet.")

        // 1 meal event yesterday
        let yesterdayMealEvent = MockMealEvent(
            identifier: "mock-meal-event-0",
            meal: self.mockMeals[0],
            date: Date().startWeek + 1.hour,
            imageURL: nil,
            portion: .usual,
            note: "")
        mockMealDataController.saveMealEvent(yesterdayMealEvent, completion: nil)
        XCTAssertEqual(suggestionMessage, "You logged 1 meal so far this week.")

        // 1 meal event today
        let todayMealEvent1 = MockMealEvent(
            identifier: "mock-meal-event-0",
            meal: self.mockMeals[0],
            date: Date().startWeek + 2.hour,
            imageURL: nil,
            portion: .usual,
            note: "")
        mockMealDataController.saveMealEvent(todayMealEvent1, completion: nil)
        XCTAssertEqual(suggestionMessage, "You logged 2 meals so far this week.")
    }

    func testStartOfWeekIsMonday() {
        let startOfWeek = Date().startWeek
        XCTAssertEqual(startOfWeek.weekdayName, "Monday")
    }

    func testWeekdayName() {
        XCTAssertEqual(sut.weekdayName, Date().weekdayName)
    }

    func testEmptyStateProperties() {
        var emptyViewAlpha: CGFloat = 0
        var footerViewAlpha: CGFloat = 0

        sut.emptyViewAlpha.subscribe(onNext: {
            emptyViewAlpha = $0
        }) >>> bag

        sut.footerViewAlpha.subscribe(onNext: {
            footerViewAlpha = $0
        }) >>> bag

        // Empty state
        mockMealDataController.reset()

        XCTAssert(sut.mealJournalIsEmpty.value)
        XCTAssertEqual(emptyViewAlpha, 1)
        XCTAssertEqual(footerViewAlpha, 0)

        // Non-empty state
        for mealEvent in mockMealEvents {
            mockMealDataController.saveMealEvent(mealEvent, completion: nil)
        }

        XCTAssertFalse(sut.mealJournalIsEmpty.value)
        XCTAssertEqual(emptyViewAlpha, 0)
        XCTAssertEqual(footerViewAlpha, 1)
    }

    func testShouldDisplayActionButton() {
        var shouldDisplayActionButton: Bool = true

        sut.shouldDisplayActionButton.subscribe(onNext: {
            shouldDisplayActionButton = $0
        }) >>> bag

        XCTAssertFalse(shouldDisplayActionButton, "Should not display the action button")
    }

    func testShouldDisplayEndOfListView() {
        var shouldDisplayEndOfListView: Bool = false

        sut.shouldDisplayEndOfListView.subscribe(onNext: {
            shouldDisplayEndOfListView = $0
        }) >>> bag

        // Empty state
        mockMealDataController.reset()

        XCTAssertFalse(shouldDisplayEndOfListView, "Should not display the action button if meal journal is empty")

        // Non-empty state
        for mealEvent in mockMealEvents {
            mockMealDataController.saveMealEvent(mealEvent, completion: nil)
        }

        XCTAssert(shouldDisplayEndOfListView, "Should display the end of list view if meal events exist")
    }

    func testCanLogTestMeal() {
        var testCanLogTestMeal: Bool = false

        sut.canLogTestMeal.subscribe(onNext: {
            testCanLogTestMeal = $0
        }) >>> bag

        XCTAssertTrue(testCanLogTestMeal, "Should allow the logging of test meals")
    }

    func canLogCommonMeal() {
        var canLogCommonMeal: Bool = false

        sut.canLogCommonMeal.subscribe(onNext: {
            canLogCommonMeal = $0
        }) >>> bag

        XCTAssertTrue(canLogCommonMeal, "Should allow the logging of common meals")
    }

    func testAnimateReportFlagState() {
        guard let mealEvent = mockMealEvents.first else {
            XCTFail("Unable to get meal event to report")
            return
        }

        // Mock the report of the meal event
        sut.mealEventToAnimateReportCompletion = mealEvent

        // Add meal event (will trigger DashboardViewModel.updateAnimateReportCompletionState)
        mockMealDataController.saveMealEvent(mealEvent, completion: nil)

        guard let cellViewModel = sut.cellViewModel(at: IndexPath(row: 0, section: 0)) else {
            XCTFail("Unable to get view model for meal event")
            return
        }

        XCTAssert(cellViewModel.shouldAnimateReportCompletion, "Report UI update should be animated on next reload")
        XCTAssertNil(sut.mealEventToAnimateReportCompletion, "Pending state object should be cleared")
    }
}
