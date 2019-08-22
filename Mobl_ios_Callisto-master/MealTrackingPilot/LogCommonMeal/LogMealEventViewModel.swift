//
//  LogMealEventViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/17/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit
import RxSwift
import Intrepid

public final class LogMealEventViewModel: CreateMealViewModelDelegate {

    // MARK: - Properties

    let dataController: MealDataController
    let mealClassification: MealClassification

    private var allMeals = Variable<[MealSelection]>([])
    private(set) var selectedMeal = Variable<Meal?>(nil)
    private var pendingSelectedMeal: Meal?

    private(set) var selectedOccasion: Variable<MealOccasion?> = Variable(nil)

    private var mealSelectionCellViewModelsVariable = Variable<[MealSelectionCellViewModel]>([])

    private(set) var pickerViewModel = MealOccasionPickerViewModel()

    private var bag = DisposeBag()

    private(set) var mode: LogMealEventMode

    var navigationTitle: String {
        switch mode {
        case .create:
            let classificationText = mealClassification.rawValue.capitalized
            return "Log \(classificationText) Meal"
        case .edit:
            return "Edit Meal"
        }
    }

    var nextButtonTitle: String {
        switch mode {
        case .create:
            return "Next Step"
        case .edit:
            return "Update Meal"
        }
    }

    // MARK: - Lifecycle

    init(mealDataController: MealDataController, mealClassification: MealClassification, mode: LogMealEventMode = .create, selectedMeal: Meal? = nil) {
        self.dataController = mealDataController
        self.mealClassification = mealClassification
        self.mode = mode
        self.pendingSelectedMeal = selectedMeal

        bindAllMeals()
        bindCellViewModels()
        bindSelectedOccasion()
        bindSelectedMeal()
    }

    // MARK: Common Meals

    func getMeals(completion: ((Result<Void>) -> Void)?) {
        dataController.getMeals(forClassification: mealClassification, completion: completion)
    }

    // MARK: Meal Selection Table

    private var visibleMeals: Observable<[MealSelection]> {
        return Observable.combineLatest(allMeals.asObservable(), selectedOccasion.asObservable(), resultSelector: { (meals, occasion) -> [MealSelection] in
            guard let occasion = occasion else {
                return meals
            }
            return meals.filter { mealSelection in
                return mealSelection.meal.occasions.contains(occasion)
            }
        })
    }

    var mealSelectionCellViewModels: [MealSelectionCellViewModel] {
        return mealSelectionCellViewModelsVariable.value
    }

    var mealSelectionCellViewModelsObservable: Observable<[MealSelectionCellViewModel]> {
        return mealSelectionCellViewModelsVariable.asObservable()
    }

    private func bindCellViewModels() {
        visibleMeals
            .map { meals in
                return meals
                    .sorted { $0.timesLogged > $1.timesLogged}
                    .map { MealSelectionCellViewModel(mealSelection: $0) }
            }
            .bind(to: mealSelectionCellViewModelsVariable)
            .disposed(by: bag)
    }

    private func bindAllMeals() {
        Observable.combineLatest(
            dataController.observableMeals(forClassification: mealClassification),
            dataController.mealStatistics
        ) { (meals, statistics) -> [MealSelection] in
            defer {
                self.pendingSelectedMeal = nil
            }
            return meals.map { meal in
                // Determine selected state of meal
                let existingMealSelection = self.allMeals.value.filter({ !$0.meal.isInvalidated }).first(where: { $0.meal == meal })
                let existingMealSelected = existingMealSelection?.selected ?? false

                // If there is a pending selected meal, deselect everything else
                var selected: Bool
                if let pendingSelectedMeal = self.pendingSelectedMeal {
                    selected = pendingSelectedMeal == meal
                } else {
                    selected = existingMealSelected
                }
                return MealSelection(meal: meal, selected: selected, timesLogged: statistics.totalCountForMeal(meal))
            }
        }
        .bind(to: allMeals)
            .disposed(by: bag)
    }

    private func bindSelectedMeal() {
        allMeals.asObservable()
            .map { mealSelections in
                return mealSelections.first(where: {
                    $0.selected
                }).map {
                    $0.meal
                }
            }
            .bind(to: selectedMeal)
            .disposed(by: bag)
    }

    // MARK: Occasion Picker

    var isOccasionPickerHidden: Bool {
        return mealClassification == .test
    }

    private func bindSelectedOccasion() {
        pickerViewModel.selectedOccasion
            .bind(to: selectedOccasion)
            .disposed(by: bag)
    }

    // MARK: Add Meal Footer

    var allowsAddNewMeal: Bool {
        return mealClassification == .common
    }

    // MARK: Background

    var gradientStartColor: UIColor {
        switch mealClassification {
        case .common:
            return UIColor.piCommonMealGradientStartColor
        case .test:
            return UIColor.piTestMealButtonGradientStartColor
        }
    }

    var gradientFinishColor: UIColor {
        switch mealClassification {
        case .common:
            return UIColor.piCommonMealGradientFinishColor
        case .test:
            return UIColor.piTestMealButtonGradientFinishColor
        }
    }

    var backgroundView: UIView? {
        return GradientView(colors: [gradientStartColor, gradientFinishColor], direction: .horizontal)
    }

    // MARK: Actions

    func didToggleSelectionForMeal(at indexPath: IndexPath) {
        if indexPath.section < 1 {
            let toggledSelection = mealSelectionCellViewModels[indexPath.row].mealSelection

            let updatedMeals: [MealSelection] = allMeals.value.map {
                var mutableSelection = $0
                if mutableSelection.meal == toggledSelection.meal {
                    mutableSelection.selected = !toggledSelection.selected
                } else {
                    mutableSelection.selected = false
                }
                return mutableSelection
            }

            allMeals.value = updatedMeals
        }
    }

    var selectedIndexPath: IndexPath? {
        guard let index = mealSelectionCellViewModels.index(where: { $0.mealSelection.selected }) else {
            return nil
        }

        return IndexPath(row: index, section: 0)
    }

    var nextStepButtonEnabled: Observable<Bool> {
        return selectedMeal.asObservable().map { $0 != nil }
    }

    // MARK: Meal Creation VM

    var createMealViewModel: CreateMealViewModel {
        return CreateMealViewModel(dataController: dataController, delegate: self)
    }

    // MARK: Meal Creation

    func mealEventDetailsViewModel() -> MealEventDetailsViewModel? {
        guard let mealEvent = createMealEvent() else { return nil }
        return MealEventDetailsViewModel(mealEvent: mealEvent, dataController: dataController, mode: mode)
    }

    private func createMealEvent() -> MealEvent? {
        guard let selectedMeal = selectedMeal.value as? RealmMeal else { return nil }

        let realmMealEvent = RealmMealEvent(meal: selectedMeal)
        realmMealEvent.localIdentifier = RealmObjectIDGenerator.localIdentifier()
        realmMealEvent.isDirty = true
        realmMealEvent.date = Date()

        return realmMealEvent
    }

    // MARK: CreateMealViewModelDelegate

    func createMealViewModel(_ viewModel: CreateMealViewModel, didCreateMeal meal: Meal) {
        guard let index = allMeals.value.index(where: {
            $0.meal == meal
        }) else {
            pendingSelectedMeal = meal
            return
        }
        allMeals.value[index].selected = true
    }
}

struct MealSelection {
    let meal: Meal
    var selected: Bool
    var timesLogged: Int
}
