//
//  DemoPilotAPIClientTests.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 5/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Intrepid
import XCTest
@testable import MealTrackingPilot

class DemoPilotAPIClientTests: XCTestCase {
    let sut = DemoPilotAPIClient()

    func testCreateMealSuccess() {
        let meal = RealmMeal()
        var mealResult: Result<RealmMeal>?

        let asyncExpectation = expectation(description: "Meal Creation")
        sut.createMeal(meal) { result in
            mealResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let mealResult = mealResult {
                XCTAssertTrue(mealResult.isSuccess, "Should return a successful result")
                XCTAssertNotNil(mealResult.value?.identifier, "Should set the identifier of the resulting meal")
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testGetMealEvents() {
        var mealEventsResult: Result<[RealmMealEvent]>?

        let asyncExpectation = expectation(description: "Meal Event Retrieval")
        sut.getMealEvents { result in
            mealEventsResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let mealEventsResult = mealEventsResult, mealEventsResult.isSuccess, let resultEvents = mealEventsResult.value {
                XCTAssertEqual(resultEvents, [], "Should return an empty result")
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testCreateMealEventSuccess() {
        let realmMealEvent = RealmMealEvent()
        var mealEventResult: Result<RealmMealEvent>?

        let asyncExpectation = expectation(description: "Meal Event Creation")
        sut.createMealEvent(realmMealEvent) { result in
            mealEventResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let mealEventResult = mealEventResult {
                XCTAssertTrue(mealEventResult.isSuccess, "Should return a successful result")
                XCTAssertNotNil(mealEventResult.value?.identifier, "Should set the identifier of the resulting meal event")
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testUpdateMealEventSuccess() {
        let realmMealEvent = RealmMealEvent()
        realmMealEvent.identifier = "id"
        var mealEventResult: Result<RealmMealEvent>?

        let asyncExpectation = expectation(description: "Meal Event Creation")
        sut.updateMealEvent(realmMealEvent) { result in
            mealEventResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let mealEventResult = mealEventResult {
                XCTAssertTrue(mealEventResult.isSuccess, "Should return a successful result")
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }

    func testReportMealEvents() {
        let realmMealEvent = RealmMealEvent()
        var reportResult: Result<[RealmMealEvent]>?

        let asyncExpectation = expectation(description: "Report Meal Event")
        sut.reportMealEvents([realmMealEvent]) { result in
            reportResult = result
            asyncExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0) { error in
            if let reportResult = reportResult {
                XCTAssert(reportResult.isSuccess, "Should return a successful result")
                XCTAssert(realmMealEvent.isFlagged, "Meal Event should be flagged")
            } else {
                XCTFail("Failed to generate a request result")
            }
        }
    }
}
