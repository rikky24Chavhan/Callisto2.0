//
//  MealOccasionPickerItemViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

class MealOccasionPickerItemViewModelTests: XCTestCase {

    func testEmptyItem() {
        let sut = MealOccasionPickerItemViewModel(occasion: nil)
        XCTAssertEqual(sut.title, "All")
    }

    func testDinnerItemUnhighlighted() {
        let sut = MealOccasionPickerItemViewModel(occasion: .dinner)
        XCTAssertEqual(sut.title, "Dinner")
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.alpha, 0.5)
        XCTAssertFalse(sut.highlighted)
    }

    func testDinnerItemHighlighted() {
        let sut = MealOccasionPickerItemViewModel(occasion: .dinner, highlighted: true)
        XCTAssertEqual(sut.title, "Dinner")
        XCTAssertNotNil(sut.icon)
        XCTAssertEqual(sut.alpha, 1.0)
        XCTAssertTrue(sut.highlighted)
    }
}
