//
//  MealOccasionPickerViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift

@testable import MealTrackingPilot

class MealOccasionPickerViewModelTests: XCTestCase {

    private let bag = DisposeBag()

    func testItems() {
        let occasions: [MealOccasion] = [
            .breakfast,
            .lunch,
            .dinner
        ]
        let sut = MealOccasionPickerViewModel(occasions: occasions)
        let pickerView = OccasionPicker()

        XCTAssertEqual(sut.occasionPickerNumberOfItems(pickerView), 4)

        let itemViews = (0..<4).map {
            return sut.occasionPicker(pickerView, viewForItem: $0, index: $0, highlighted: false, reusingView: nil) as? MealOccasionPickerItemView
        }
        XCTAssertEqual(itemViews[0]?.titleLabel.text, "All")
        XCTAssertEqual(itemViews[1]?.titleLabel.text, "Breakfast")
        XCTAssertEqual(itemViews[2]?.titleLabel.text, "Lunch")
        XCTAssertEqual(itemViews[3]?.titleLabel.text, "Dinner")
    }

    func testSelection() {
        let occasions: [MealOccasion] = [
            .breakfast,
            .lunch,
            .dinner
        ]
        let sut = MealOccasionPickerViewModel(occasions: occasions)
        let pickerView = OccasionPicker()

        let selectedOccasion: Variable<MealOccasion?> = Variable(nil)
        sut.selectedOccasion
            .bind(to: selectedOccasion)
            .disposed(by: bag)

        XCTAssertEqual(sut.selectedIndex.value, 0)
        XCTAssertNil(selectedOccasion.value)

        sut.occasionPicker(pickerView, didSelectItem: 1, index: 1)

        XCTAssertEqual(sut.selectedIndex.value, 1)
        XCTAssertEqual(selectedOccasion.value, .breakfast)

        sut.occasionPicker(pickerView, didSelectItem: 2, index: 2)

        XCTAssertEqual(sut.selectedIndex.value, 2)
        XCTAssertEqual(selectedOccasion.value, .lunch)

        sut.occasionPicker(pickerView, didSelectItem: 3, index: 3)

        XCTAssertEqual(sut.selectedIndex.value, 3)
        XCTAssertEqual(selectedOccasion.value, .dinner)

        sut.occasionPicker(pickerView, didSelectItem: 0, index: 0)

        XCTAssertEqual(sut.selectedIndex.value, 0)
        XCTAssertNil(selectedOccasion.value)
    }
}

