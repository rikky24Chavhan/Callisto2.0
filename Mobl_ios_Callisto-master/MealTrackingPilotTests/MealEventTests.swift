//
//  MealEventTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/13/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RealmSwift
@testable import MealTrackingPilot

class MealEventTests: XCTestCase {

    lazy var commonMealEvent: MealEvent = try! TestMealEventProvider.getCommonMealEvent()
    lazy var testMealEvent: MealEvent = try! TestMealEventProvider.getTestMealEvent()

    func testCommonMealInitWithJson() {
        let sut = commonMealEvent
        XCTAssertEqual(sut.identifier, "common-meal-event-id")
        XCTAssertEqual(sut.date, Date(timeIntervalSince1970: 1490287551.794))
        XCTAssertEqual(sut.imageURL, URL(string: "http://www.intrepid.io/hs-fs/hubfs/Intrepid_Mar2016/nav_bg-8e68a1795ce5f354797aad6e45b566b9.png?t=1489432679175&width=5779&name=nav_bg-8e68a1795ce5f354797aad6e45b566b9.png"))
        XCTAssertEqual(sut.note, "This meal was delicious")
        XCTAssertEqual(sut.classification, .common)
        XCTAssertEqual(sut.portion, .usual)
    }

    func testTestMealInitWithJson() {
        let sut = testMealEvent
        XCTAssertEqual(sut.identifier, "test-meal-event-id")
        XCTAssertEqual(sut.date, Date(timeIntervalSince1970: 1490287551.794))
        XCTAssertEqual(sut.imageURL, URL(string: "http://www.intrepid.io/hs-fs/hubfs/Intrepid_Mar2016/nav_bg-8e68a1795ce5f354797aad6e45b566b9.png?t=1489432679175&width=5779&name=nav_bg-8e68a1795ce5f354797aad6e45b566b9.png"))
        XCTAssertEqual(sut.note, "This meal was delicious")
        XCTAssertEqual(sut.classification, .test)
    }

    func testMealEventInitWithNullStringsInJson() {
        guard let sut = try? TestMealEventProvider.getNullMappingsMealEvent() else {
            XCTFail("Should map meal")
            return
        }
        XCTAssertEqual(sut.note, "", "Should map empty notes")
        XCTAssertNil(sut.imageURL, "Should map nil image URL")
    }

    // MARK: - To JSON

    func testCommonMealEventToJson() {
        compareJsonForMealEvent(commonMealEvent, toExpected: TestMealEventProvider.expectedCommonMealEventPostJson())
    }

    func testTestMealEventToJson() {
        compareJsonForMealEvent(testMealEvent, toExpected: TestMealEventProvider.expectedTestMealEventPostJson())
    }

    private func compareJsonForMealEvent(_ mealEvent: MealEvent, toExpected expectedJson: [String: Any]) {
        guard
            let json = mealEvent.json
            else {
                XCTFail("Should serialize into valid JSON")
                return
        }

        let jsonDict = NSDictionary(dictionary: json)
        let expectedDict = NSDictionary(dictionary: expectedJson)

        XCTAssertEqual(jsonDict, expectedDict, "Should match expected JSON for POST request")

    }
}
