//
//  OfflineMealSyncControllerTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 6/7/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

class OfflineMealSyncControllerTests: XCTestCase {

    private let mockMeals: [MockMeal] = [
        MockMeal(identifier: "mock-meal-0", name: "Apple", classification: .common, occasions: [.snack], carbGrams: 2, hasDosingRecommendation: false, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-1", name: "Baked Potato", classification: .common, occasions: [.dinner], carbGrams: 20, hasDosingRecommendation: true, loggingGoal: 0),
        MockMeal(identifier: "mock-meal-2", name: "T-Bone Steak", classification: .common, occasions: [.snack, .dinner, .drink], carbGrams: 8, hasDosingRecommendation: true, loggingGoal: 0)
    ]

    private lazy var mockMealEvents: [MockMealEvent] = [
        MockMealEvent(identifier: "mock-meal-event-0", meal: self.mockMeals[0], date: Date(), imageURL: nil, portion: .usual, note: ""),
        MockMealEvent(identifier: "mock-meal-event-1", meal: self.mockMeals[1], date: Date(), imageURL: nil, portion: .usual, note: ""),
        MockMealEvent(identifier: "mock-meal-event-2", meal: self.mockMeals[2], date: Date(), imageURL: nil, portion: .usual, note: "")
    ]

    lazy var mockMealDataController: MockMealDataController = MockMealDataController(mockMeals: self.mockMeals, mockMealEvents: self.mockMealEvents)

    lazy var sut: OfflineMealSyncController = OfflineMealSyncController(dataController: self.mockMealDataController)

    func testNoMealEventsToSync() {
        var result: OfflineMealSyncController.SyncResult?

        let asyncExpectation = expectation(description: "Sync result should be 'nothingToSync'")

        sut.start { syncResult in
            result = syncResult
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)

            XCTAssertEqual(result, .nothingToSync)
        }
    }

    func testSyncMealAndMealEvent() {
        let mealToSync = mockMeals[0]
        let mealEventToSync = mockMealEvents[0]

        mealToSync.isDirty = true
        mealToSync.identifier = ""

        mealEventToSync.isDirty = true
        mealEventToSync.identifier = ""

        let initialMealCount = mockMealDataController.mockMeals.count
        let initialMealEventCount = mockMealDataController.mockMealEvents.count

        var result: OfflineMealSyncController.SyncResult?

        let asyncExpectation = expectation(description: "Sync result should be 'complete' with updated meal and meal event")

        sut.start { syncResult in
            result = syncResult
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)

            XCTAssertEqual(result, .complete)

            // Mock data controller appends to internal array when meal or meal event is saved
            XCTAssertEqual(self.mockMealDataController.mockMeals.count, initialMealCount + 1)
            XCTAssertEqual(self.mockMealDataController.mockMealEvents.count, initialMealEventCount + 1)
        }
    }
}
