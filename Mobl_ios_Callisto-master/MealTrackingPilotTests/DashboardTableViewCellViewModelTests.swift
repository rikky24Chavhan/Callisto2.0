//
//  DashboardTableViewCellViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/4/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
@testable import MealTrackingPilot

class DashboardTableViewCellViewModelTests: XCTestCase {

    let commonMealEvent = try! TestMealEventProvider.getCommonMealEvent()
    let testMealEvent = try! TestMealEventProvider.getTestMealEvent()
    lazy var mealStatistics: MealStatistics = MealStatistics(mealEvents: [self.commonMealEvent, self.testMealEvent])

    func testDashboardTableViewCellViewModelCommonMealEvent() {
        let sut = DashboardTableViewCellViewModel(mealEvent: commonMealEvent, stats: mealStatistics)
        XCTAssertEqual(sut.mealName, "Mark's Common Meal")
        XCTAssertEqual(sut.mealLocation, nil)
        XCTAssertEqual(sut.mealLogGoal, 0)
        XCTAssertEqual(sut.isCommon, true)
        XCTAssertEqual(sut.imageURL?.absoluteString, "http://www.intrepid.io/hs-fs/hubfs/Intrepid_Mar2016/nav_bg-8e68a1795ce5f354797aad6e45b566b9.png?t=1489432679175&width=5779&name=nav_bg-8e68a1795ce5f354797aad6e45b566b9.png")
        XCTAssertEqual(sut.noteIndicatorHidden, false)
        XCTAssertEqual(sut.numberOfTimesMealLogged, 1)
        XCTAssertEqual(sut.portionDescription, "USUAL")
        XCTAssertEqual(sut.tintColor, UIColor.piTopaz)
        XCTAssertEqual(sut.circleProgressInnerCircleColor, UIColor.piTopaz)
        XCTAssertEqual(sut.circleProgressOuterCircleTrackColor, UIColor.piTopaz40)
        XCTAssertEqual(sut.circleProgressRingColor, nil)
        XCTAssertEqual(sut.flagIndicatorHidden, true)
        XCTAssertEqual(sut.reportButtonHidden, false)
        XCTAssertEqual(sut.dosageRecommendationHidden, true)
    }

    func testDashboardTableViewCellViewModelTestMealEvent() {
        let sut = DashboardTableViewCellViewModel(mealEvent: testMealEvent, stats: mealStatistics)
        XCTAssertEqual(sut.mealName, "Mark's Test Meal")
        XCTAssertEqual(sut.mealLocation, "Trader Joe's")
        XCTAssertEqual(sut.mealLogGoal, 5)
        XCTAssertEqual(sut.isCommon, false)
        XCTAssertEqual(sut.imageURL?.absoluteString, "http://www.intrepid.io/hs-fs/hubfs/Intrepid_Mar2016/nav_bg-8e68a1795ce5f354797aad6e45b566b9.png?t=1489432679175&width=5779&name=nav_bg-8e68a1795ce5f354797aad6e45b566b9.png")
        XCTAssertEqual(sut.noteIndicatorHidden, false)
        XCTAssertEqual(sut.numberOfTimesMealLogged, 1)
        XCTAssertEqual(sut.tintColor, UIColor.piLightOrange)
        XCTAssertEqual(sut.circleProgressInnerCircleColor, UIColor.piLightOrange)
        XCTAssertEqual(sut.circleProgressOuterCircleTrackColor, UIColor(white: 1.0, alpha: 0.4))
        XCTAssertEqual(sut.circleProgressRingColor, UIColor.white)
        XCTAssertEqual(sut.dosageRecommendationHidden, false)
    }
}
