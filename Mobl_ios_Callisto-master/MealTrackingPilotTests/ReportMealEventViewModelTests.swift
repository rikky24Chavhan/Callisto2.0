//
//  ReportMealEventViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift

@testable import MealTrackingPilot

class ReportMealEventViewModelTests: XCTestCase {

    let mealEvent = try! TestMealEventProvider.getCommonMealEvent()
    let dataController = MockMealDataController()

    lazy var sut: ReportMealEventViewModel = ReportMealEventViewModel(
        mealEvent: self.mealEvent,
        dataController: self.dataController)

    private let bag = DisposeBag()

    func testMealName() {
        var mealName: String?
        sut.mealName.subscribe(onNext: { mealName = $0 }) >>> bag
        XCTAssertEqual(mealName, "Mark's Common Meal")
    }

    func testDateString() {
        var dateString: String?
        sut.dateString.subscribe(onNext: { dateString = $0 }) >>> bag
        XCTAssertEqual(dateString, "Mar 23, 2017")
    }

    func testReport() {
        XCTAssertFalse(mealEvent.isFlagged)

        sut.report(completion: nil)

        XCTAssert(mealEvent.isFlagged)
    }
}
