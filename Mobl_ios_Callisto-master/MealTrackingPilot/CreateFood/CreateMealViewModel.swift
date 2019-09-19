//
//  CreateMealViewModel.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

// MARK: - Parent View Model

protocol CreateMealViewModelDelegate: class {
    func createMealViewModel(_ viewModel: CreateMealViewModel, didCreateMeal meal: Meal)
}

final class CreateMealViewModel {

    lazy var nameViewModel: CreateMealNameViewModel = CreateMealNameViewModel(meal: self.meal)
    lazy var occasionsViewModel: CreateMealOccasionsViewModel = CreateMealOccasionsViewModel(meal: self.meal)
    lazy var carbsViewModel: CreateMealCarbsViewModel = CreateMealCarbsViewModel(meal: self.meal, isRequestInProgress: self.isRequestInProgress)

    lazy var childViewModels: [CreateMealChildViewModel] = [
        self.nameViewModel,
        self.occasionsViewModel,
        self.carbsViewModel
    ]

    lazy var childTitles: [String] = self.childViewModels.map { $0.title }

    let nextNavigationEnabledArray = Variable<[Bool]>([])

    let isRequestInProgress = Variable<Bool>(false)

    private let bag = DisposeBag()

    let meal: Meal
    let dataController: MealDataController

    weak var delegate: CreateMealViewModelDelegate?

    init(meal: Meal = RealmMeal(), dataController: MealDataController, delegate: CreateMealViewModelDelegate? = nil) {
        if meal.localIdentifier.isEmpty {
            meal.localIdentifier = RealmObjectIDGenerator.localIdentifier()
        }

        self.meal = meal
        self.dataController = dataController
        self.delegate = delegate
        setupNextNavigationEnabledBinding()
    }

    private func setupNextNavigationEnabledBinding() {
        let observables = childViewModels.map { $0.nextNavigationEnabled }
        let combinedObservable = Observable.combineLatest(observables) { $0 }
        combinedObservable.bind(to: nextNavigationEnabledArray) >>> bag
    }

    func createMeal(completion: ((SaveResult<Meal>) -> Void)?) {
        isRequestInProgress.value = true

        dataController.saveMeal(meal, shouldValidate: true) { [weak self] result in
            guard let welf = self else { return }

            welf.isRequestInProgress.value = false

            switch result {
            case .synchronized(let meal),
                 .localOnly(let meal, _):
                welf.delegate?.createMealViewModel(welf, didCreateMeal: meal)
            default:
                break
            }
            completion?(result)
        }
    }

    func canSelectSegment(at index: Int, currentIndex: Int) -> Bool {
        if index < 0 || index >= nextNavigationEnabledArray.value.count { return false }
        if index > currentIndex {
            var nextNavigationEnabled = true
            var counterIndex = currentIndex
            while counterIndex < index {
                nextNavigationEnabled = nextNavigationEnabled && nextNavigationEnabledArray.value[counterIndex]
                counterIndex = counterIndex + 1
            }
            return nextNavigationEnabled
        } else {
            return true
        }
    }
}

// MARK: - Child View Models

protocol CreateMealChildViewModel {
    var title: String { get }
    var meal: Meal { get }
    var viewController: CreateMealChildViewController { get }
    var nextNavigationEnabled: Observable<Bool> { get }
    var indicatorPosition: Observable<Int?> { get }
}

// MARK: Meal Name

final class CreateMealNameViewModel: CreateMealChildViewModel {

    struct Constants {
        static let nameMaxCharacterCount = 65
    }

    let title: String = "MEAL NAME"

    let meal: Meal
    lazy var viewController: CreateMealChildViewController = CreateMealNameViewController(viewModel: self)

    var nextNavigationEnabled: Observable<Bool> {
        return validatedName.map { name in
            guard let name = name else { return false }
            return name.count > 0
        }
    }

    var indicatorPosition: Observable<Int?> {
        return validatedName.map { name in
            let isNameValid = (name?.count ?? 0) > 0
            return [isNameValid].firstIndex(where: { !$0 })
        }
    }

    lazy var name: Variable<String?> = Variable(self.meal.name)

    var validatedName: Observable<String?> {
        return name.asObservable().map { name in
            guard let name = name else { return nil }

            if name.count > Constants.nameMaxCharacterCount {
                let endIndex = name.index(name.startIndex, offsetBy: Constants.nameMaxCharacterCount)
                return String(name[..<endIndex])
            } else {
                return name
            }
        }
    }

    private let bag = DisposeBag()

    init(meal: Meal) {
        self.meal = meal
        setupObservers()
    }

    private func setupObservers() {
        validatedName.subscribe(onNext: { [weak self] name in
            guard let name = name else { return }
            self?.meal.name = name
        }) >>> bag
    }
}

// MARK: Occasions

final class CreateMealOccasionsViewModel: CreateMealChildViewModel {

    let title: String = "MEAL TYPE"

    let meal: Meal
    lazy var viewController: CreateMealChildViewController = CreateMealOccasionsViewController(viewModel: self)

    var nextNavigationEnabled: Observable<Bool> {
        return isOccasionSelected
    }

    var indicatorPosition: Observable<Int?> {
        return isOccasionSelected.map { isOccasionSelected in
            return [isOccasionSelected].firstIndex(where: { !$0 })
        }
    }

    private var isOccasionSelected: Observable<Bool> {
        let isSelectedObservables = occasionTableViewCellViewModels.map { $0.isSelectedObservable }
        return Observable.combineLatest(isSelectedObservables) { isSelectedArray in
            return isSelectedArray.contains(true)
        }
    }

    lazy var occasionTableViewCellViewModels: [MealOccasionTableViewCellViewModel] = MealOccasion.orderedValues.map {
        MealOccasionTableViewCellViewModel(occasion: $0, selected: self.meal.occasions.contains($0))
    }

    private let bag = DisposeBag()

    init(meal: Meal) {
        self.meal = meal
        setupObservers()
    }

    func setupObservers() {
        // Subscribe to each `isSelected` observable individually
        occasionTableViewCellViewModels.forEach { viewModel in
            viewModel.isSelectedObservable.subscribe(onNext: { [weak self] isSelected in
                guard let welf = self else { return }
                let occasion = viewModel.occasion
                if !isSelected {
                    welf.meal.occasions.remove(object: occasion)
                } else if !welf.meal.occasions.contains(occasion) {
                    welf.meal.occasions.append(occasion)
                }
            }) >>> bag
        }
    }

    func numberOfOccasionRows(for section: Int) -> Int {
        return occasionTableViewCellViewModels.count
    }

    func occasionTableViewCellViewModel(for indexPath: IndexPath) -> MealOccasionTableViewCellViewModel {
        return occasionTableViewCellViewModels[indexPath.row]
    }

    func selectOccasion(at indexPath: IndexPath) {
        occasionTableViewCellViewModel(for: indexPath).setSelected(true)
    }

    func deselectOccasion(at indexPath: IndexPath) {
        occasionTableViewCellViewModel(for: indexPath).setSelected(false)
    }
}

final class MealOccasionTableViewCellViewModel: CheckmarkTableViewCellViewModel {

    let occasion: MealOccasion

    lazy var text: String = self.occasion.displayValue

    private let _isSelected = Variable<Bool>(false)
    lazy var isSelectedObservable: Observable<Bool> = self._isSelected.asObservable()
    var isSelected: Bool {
        return _isSelected.value
    }

    init(occasion: MealOccasion, selected: Bool = false) {
        self.occasion = occasion
        setSelected(selected)
    }

    func setSelected(_ selected: Bool) {
        self._isSelected.value = selected
    }
}

// MARK: - Carbs

final class CreateMealCarbsViewModel: CreateMealChildViewModel {

    let title: String = "TOTAL CARBS"

    let meal: Meal
    lazy var viewController: CreateMealChildViewController = CreateMealCarbsViewController(viewModel: self)

    let isRequestInProgress: Observable<Bool>
    var nextNavigationEnabled: Observable<Bool> {
        return isRequestInProgress.map { !$0 }    // Carb entry is optional
    }

    var indicatorPosition: Observable<Int?> {
        return carbsString.asObservable().map { carbsString in
            let carbsNumber = numberFormatter.number(from: carbsString ?? "")?.doubleValue ?? 0
            return (carbsNumber > 0 && carbsNumber < 10000) ? nil : 0
        }
    }

    lazy var carbsString: Variable<String?> = Variable(numberFormatter.string(from: NSNumber(value: self.meal.carbGrams)))

    private let bag = DisposeBag()

    init(meal: Meal, isRequestInProgress: Variable<Bool>) {
        self.meal = meal
        self.isRequestInProgress = isRequestInProgress.asObservable()
        setupObservers()
    }

    func setupObservers() {
        carbsString.asObservable().subscribe(onNext: { [weak self] carbsString in
            self?.meal.carbGrams = numberFormatter.number(from: carbsString ?? "")?.doubleValue ?? 0
        }) >>> bag
    }
}

fileprivate let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.zeroSymbol = ""
    return formatter
}()
