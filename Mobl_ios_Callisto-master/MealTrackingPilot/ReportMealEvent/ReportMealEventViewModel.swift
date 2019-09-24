//
//  ReportMealEventViewModel.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/25/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift

protocol ReportMealEventViewModelDelegate: class {
    func reportMealEventViewModelDidReport(_ viewModel: ReportMealEventViewModel)
}

class ReportMealEventViewModel {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()

    weak var delegate: ReportMealEventViewModelDelegate?

    let mealEvent: MealEvent
    let dataController: MealDataController

    init(mealEvent: MealEvent, dataController: MealDataController, delegate: ReportMealEventViewModelDelegate? = nil) {
        self.mealEvent = mealEvent
        self.dataController = dataController
        self.delegate = delegate
    }

    // MARK: - Observables

    lazy var mealName: Observable<String?> = Observable.just(self.mealEvent.meal.name)
    lazy var dateString: Observable<String?> = Observable.just(ReportMealEventViewModel.dateFormatter.string(from: self.mealEvent.date))

    let isRequestInProgress = Variable<Bool>(false)
    
    // MARK: - Actions

    func report(completion: mealEventCompletion?) {
        isRequestInProgress.value = true
        dataController.reportMealEvent(mealEvent) { [weak self] result in
            defer { completion?(result) }

            guard let welf = self else { return }
            welf.isRequestInProgress.value = false
            welf.delegate?.reportMealEventViewModelDidReport(welf)
        }
    }
}
