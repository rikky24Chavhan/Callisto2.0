//
//  MealEventDetailsViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/31/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import SwiftDate
@testable import MealTrackingPilot

class MealEventDetailsViewModelTests: XCTestCase {

    let commonMealEvent = try! TestMealEventProvider.getCommonMealEvent()
    let testMealEvent = try! TestMealEventProvider.getTestMealEvent()
    lazy var dataController: MockMealDataController = MockMealDataController(mockMeals: [self.commonMealEvent.meal, self.testMealEvent.meal])
    let imageDownloader = MockImageDownloader()

    func testDateFormatStartsToday() {
        let meal = commonMealEvent.meal as! RealmMeal
        let newMealEvent = RealmMealEvent(meal: meal)
        let sut = MealEventDetailsViewModel(mealEvent: newMealEvent, dataController: dataController)
        let date = Date()
        let timeString = date.string(custom: "h:mm a").uppercased()
        XCTAssertEqual(sut.formattedDate.value.string, "TODAY AT \(timeString)")
    }

    func testDateFormat() {
        let commonSUT = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController)
        let testSUT = MealEventDetailsViewModel(mealEvent: testMealEvent, dataController: dataController)

        let date = Date(timeIntervalSince1970: 1483261200)
        commonSUT.currentLogDate = date
        let timeString = date.string(custom: "h:mm a").uppercased()
        XCTAssertEqual(commonSUT.formattedDate.value.string, "JAN 01 AT \(timeString)")

        XCTAssertEqual(commonSUT.formattedDateTextColor, UIColor.piTopaz)
        XCTAssertEqual(testSUT.formattedDateTextColor, UIColor.piLightOrange)
    }

    func testEditableProperties() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)

        commonMealEvent.date = Date()   // Set date within 48 hours to enable editing

        XCTAssert(sut.isDateContainerUserInteractionEnabled)

        // Image exists
        XCTAssert(sut.isPhotoImageViewUserInteractionEnabled)
        XCTAssertFalse(sut.isPhotoOptionsButtonHidden)

        // No image
        sut.image.value = nil
        XCTAssert(sut.isAddPhotoButtonEnabled)
        XCTAssertEqual(sut.addPhotoButtonBackgroundColor, UIColor.piPaleGreyTwo)
        XCTAssertEqual(sut.addPhotoButtonShadowOpacity, 0.06)
        XCTAssertEqual(sut.addPhotoButtonTitleFont, UIFont.openSansSemiboldFont(size: 18))

        // Note exists
        XCTAssert(sut.isAddNoteContainerViewHidden)
        XCTAssertFalse(sut.isNotesContainerViewHidden)
        XCTAssert(sut.isNoteSuggestionViewHidden)
        XCTAssert(sut.isNotesContainerViewUserInteractionEnabled)
        XCTAssertEqual(sut.notesContainerViewBackgroundColor, UIColor.piDenim.withAlphaComponent(0.05))

        // No note
        sut.notes.value = nil
        XCTAssertFalse(sut.isAddNoteContainerViewHidden)
        XCTAssert(sut.isAddNoteButtonEnabled)
        XCTAssert(sut.isNotesContainerViewHidden)
        XCTAssertFalse(sut.isNoteSuggestionViewHidden)
        XCTAssertEqual(sut.addNoteButtonBackgroundColor, UIColor.piPaleGreyTwo)
        XCTAssertEqual(sut.addNoteButtonShadowOpacity, 0.06)
        XCTAssertEqual(sut.addNoteButtonTitleFont, UIFont.openSansSemiboldFont(size: 18))
    }

    func testUneditableProperties() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)

        XCTAssertFalse(sut.isDateContainerUserInteractionEnabled)

        // Image exists
        XCTAssert(sut.isPhotoImageViewUserInteractionEnabled)
        XCTAssert(sut.isPhotoOptionsButtonHidden)

        // No image
        sut.image.value = nil
        XCTAssertFalse(sut.isAddPhotoButtonEnabled)
        XCTAssertEqual(sut.addPhotoButtonBackgroundColor, UIColor.white)
        XCTAssertEqual(sut.addPhotoButtonShadowOpacity, 0)
        XCTAssertEqual(sut.addPhotoButtonTitleFont, UIFont.openSansBoldFont(size: 18))

        // Note exists
        XCTAssert(sut.isNoteSuggestionViewHidden)
        XCTAssertEqual(sut.notesContainerViewBackgroundColor, UIColor.white)
        XCTAssertFalse(sut.isNotesContainerViewUserInteractionEnabled)

        // No note
        sut.notes.value = nil
        XCTAssertFalse(sut.isAddNoteButtonEnabled)
    }

    func testAddNoteButtonEmphasized() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        commonMealEvent.date = Date()   // Set date within 48 hours to enable editing

        sut.portion.value = .usual
        XCTAssertFalse(sut.isAddNoteButtonEmphasized)
        
        sut.portion.value = .more
        XCTAssertTrue(sut.isAddNoteButtonEmphasized)
    }

    func testMealNameTextValues() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController)
        XCTAssertEqual(sut.title, "Mark's Common Meal")
        XCTAssertEqual(sut.logButtonAttributedString.string, "Log Mark's Common Meal")
    }

    func testConfirmDetails() {
        let meal = commonMealEvent.meal as! RealmMeal
        let newMealEvent = RealmMealEvent(meal: meal)
        let sut = MealEventDetailsViewModel(mealEvent: newMealEvent, dataController: dataController)

        let date = Date(timeIntervalSince1970: 1483261200)
        let portion: MealEventPortion = .more
        let note = "Test note"
        sut.currentLogDate = date
        sut.portion.value = portion
        sut.notes.value = note

        sut.confirmDetails()

        // Test that confirmDetails sets the appropriate values on the MealEvent
        XCTAssertEqual(newMealEvent.date, date)
        XCTAssertEqual(newMealEvent.portion, portion)
        XCTAssertEqual(newMealEvent.note, note)
    }

    func testConfirmDetailsAfterRemovingImage() {
        let meal = commonMealEvent.meal as! RealmMeal
        let mealEvent = RealmMealEvent(meal: meal)
        mealEvent.imageURL = Bundle.main.bundleURL
        let sut = MealEventDetailsViewModel(mealEvent: mealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)

        XCTAssertNotNil(mealEvent.imageURL)
        XCTAssertNotNil(sut.image.value)

        sut.image.value = nil
        sut.confirmDetails()

        XCTAssertNil(mealEvent.imageURL)
    }

    func testEditNote() {
        commonMealEvent.date = Date()

        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.changesWereMade, false)

        sut.notes.value = "Updated Note"
        XCTAssertEqual(sut.changesWereMade, true)
    }

    func testEditPortion() {
        commonMealEvent.date = Date()

        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.changesWereMade, false)

        sut.portion.value = .less
        XCTAssertEqual(sut.changesWereMade, true)
    }

    func testEditImage() {
        commonMealEvent.date = Date()

        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.changesWereMade, false)

        sut.image.value = #imageLiteral(resourceName: "settingsButton")
        XCTAssertEqual(sut.changesWereMade, true)
    }

    func testEditDate() {
        commonMealEvent.date = Date()

        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.changesWereMade, false)

        sut.currentLogDate = Date() + 1.day
        XCTAssertEqual(sut.changesWereMade, true)
    }

    func testEditMeal() {
        commonMealEvent.date = Date()

        let meal = RealmMeal()
        meal.name = "Bobs Burger"

        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.confirmationButtonIsVisible.value, false)
        sut.meal.value = meal
        XCTAssertEqual(sut.confirmationButtonIsVisible.value, true)
    }

    func testCanEditMeal() {
        commonMealEvent.date = Date()
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.canEditMeal, true)
    }

    func testCanNotEditMeal() {
        commonMealEvent.date = Date() - 3.days
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.canEditMeal, false)
    }

    func testCanSwapMeal() {
        commonMealEvent.date = Date()
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, mode: .edit)
        XCTAssertEqual(sut.canSwapMeal, true)
    }

    func testCanNotSwapMeal() {
        commonMealEvent.date = Date() - 3.days
        var sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, mode: .edit)
        XCTAssertEqual(sut.canSwapMeal, false)

        commonMealEvent.date = Date()
        sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, mode: .create)
        XCTAssertEqual(sut.canSwapMeal, false)
    }

    func testHasImage() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.hasImage, true)

        sut.image.value = nil
        XCTAssertFalse(sut.hasImage)
    }

    func testHasNote() {
        let sut = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertEqual(sut.hasNote, true)
        sut.notes.value = nil
        XCTAssertEqual(sut.hasNote, false)
    }

    func testMessageContentDoesNotExist() {
        let commonMealSUT = MealEventDetailsViewModel(mealEvent: commonMealEvent, dataController: dataController)
        XCTAssertFalse(commonMealSUT.shouldDisplayTestMealMessages)

        let editTestMealSUT = MealEventDetailsViewModel(mealEvent: testMealEvent, dataController: dataController, imageDownloader: imageDownloader, mode: .edit)
        XCTAssertFalse(editTestMealSUT.shouldDisplayTestMealMessages)
    }

    func testTestMealMessageContent() {
        let sut = MealEventDetailsViewModel(mealEvent: testMealEvent, dataController: dataController, mode: .create)

        XCTAssert(sut.shouldDisplayTestMealMessages)

        let messageContentCount = sut.testMealMessageContent.count
        for expectedIndex in 0..<messageContentCount {
            XCTAssertEqual(sut.currentTestMealMessageIndex, expectedIndex)
            _ = sut.advanceToNextTestMealMessage()
        }

        XCTAssertEqual(sut.currentTestMealMessageIndex, 0, "Index should wrap around to 0")
    }
}
