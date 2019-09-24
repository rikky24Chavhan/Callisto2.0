//
//  CreateMealViewModelTests.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/20/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import RxSwift
import RealmSwift
@testable import MealTrackingPilot

class CreateMealViewModelTests: XCTestCase {

    var meal: Meal!

    let dataController = MockMealDataController(mockMeals: [])
    let realmDataController = try! RealmMealDataController(realmConfiguration: Realm.Configuration(inMemoryIdentifier: "PilotTests"), apiClient: MockPilotAPIClient())

    let bag = DisposeBag()

    override func setUp() {
        super.setUp()

        let meals = try! TestMealProvider.getMeals()
        meal = meals.first
    }

    override func tearDown() {
        meal = nil
        let realm = realmDataController.realm
        try! realm.write {
            realm.deleteAll()
        }
        super.tearDown()
    }

    func testMealName() {
        // Test initial value (model -> VM)
        let sut = CreateMealNameViewModel(meal: meal)
        XCTAssertEqual(sut.name.value, meal.name)

        // Test updated value (VM -> model)
        let newValue = "A new name"
        sut.name.value = newValue
        XCTAssertEqual(meal.name, newValue)
    }

    func testMealNameMaxCharacterCount() {
        let sut = CreateMealNameViewModel(meal: meal)

        var validatedName: String?
        sut.validatedName.subscribe(onNext: {
            validatedName = $0
        }) >>> bag

        sut.name.value = "A really long meal name that will eventually be truncated after 65 characters"
        XCTAssertEqual(validatedName, "A really long meal name that will eventually be truncated after 6")
        XCTAssertEqual(meal.name, validatedName, "Validated name should be bound to model property")
    }

    func testMealOccasions() {
        // Test initial value (model -> VM)
        let sut = CreateMealOccasionsViewModel(meal: meal)
        sut.occasionTableViewCellViewModels.forEach { viewModel in
            XCTAssertEqual(viewModel.isSelected, meal.occasions.contains(viewModel.occasion))
        }

        // Test updated value (VM -> model)
        sut.occasionTableViewCellViewModels.forEach { viewModel in
            switch viewModel.occasion {
            case .lunch, .dinner, .drink:
                viewModel.setSelected(true)
            default:
                viewModel.setSelected(false)
            }
        }
        XCTAssertEqual(meal.occasions, [.lunch, .dinner, .drink])
    }

    func testNextNavigationEnabled() {
        let meal = RealmMeal()
        let sut = CreateMealViewModel(meal: meal, dataController: dataController)

        func enabled(index: Int) -> Bool {
            return sut.nextNavigationEnabledArray.value[index]
        }

        // Test name view model
        let nameIndex = 0
        let nameViewModel = sut.nameViewModel

        // Should only be enabled when name is valid
        nameViewModel.name.value = nil
        XCTAssertFalse(enabled(index: nameIndex))

        nameViewModel.name.value = "Test"
        XCTAssert(enabled(index: nameIndex))

        // Test occasions view model
        let occasionsIndex = 1
        let occasionsViewModel = sut.occasionsViewModel
        let breakfastOccasionViewModel = occasionsViewModel.occasionTableViewCellViewModels.first!

        // Should only be enabled when name is valid
        breakfastOccasionViewModel.setSelected(false)
        XCTAssertFalse(enabled(index: occasionsIndex))

        breakfastOccasionViewModel.setSelected(true)
        XCTAssert(enabled(index: occasionsIndex))
    }

    func testCreateMeal() {
        let sut = CreateMealViewModel(meal: meal, dataController: realmDataController)
        sut.createMeal { result in
            let realm = self.realmDataController.realm
            let realmMeals = realm.objects(RealmMeal.self)
            XCTAssertEqual(realmMeals.count, 1)
        }
    }

    func testCanSelectSegment() {
        let sut = CreateMealViewModel(meal: RealmMeal(), dataController: dataController)
        let nameViewModel = sut.nameViewModel
        let occasionsViewModel = sut.occasionsViewModel

        // Empty data model state
        XCTAssertEqual(sut.canSelectSegment(at: 1, currentIndex: 0), false)
        XCTAssertEqual(sut.canSelectSegment(at: 2, currentIndex: 0), false)

        // First step valid
        nameViewModel.name.value = "A value"
        XCTAssertEqual(sut.canSelectSegment(at: 1, currentIndex: 0), true)
        XCTAssertEqual(sut.canSelectSegment(at: 2, currentIndex: 0), false)

        // Second step valid
        occasionsViewModel.selectOccasion(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(sut.canSelectSegment(at: 0, currentIndex: 1), true)
    }

    func testIndicatorPosition() {
        let sut = CreateMealViewModel(meal: RealmMeal(), dataController: dataController)

        // Name VM
        let nameViewModel = sut.nameViewModel
        var namePosition: Int?
        nameViewModel.indicatorPosition.subscribe(onNext: {
            namePosition = $0
        }) >>> bag

        XCTAssertEqual(namePosition, 0)

        nameViewModel.name.value = "A value"
        XCTAssertNil(namePosition)

        // Occasions VM
        let occasionsViewModel = sut.occasionsViewModel
        var occasionsPosition: Int?
        occasionsViewModel.indicatorPosition.subscribe(onNext: {
            occasionsPosition = $0
        }) >>> bag

        XCTAssertEqual(occasionsPosition, 0)

        occasionsViewModel.selectOccasion(at: IndexPath(row: 0, section: 0))
        XCTAssertNil(occasionsPosition)
    }
}
