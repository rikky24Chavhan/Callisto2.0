//
//  OfflineMealSyncController.swift
//  MealTrackingPilot
//
//  Created by Colden Prime on 6/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RxSwift

final class OfflineMealSyncController {

    enum SyncResult {
        case nothingToSync
        case incomplete
        case complete
    }

    let dataController: MealDataController

    let bag = DisposeBag()

    init(dataController: MealDataController) {
        self.dataController = dataController
    }

    func start(completion: ((SyncResult) -> Void)? = nil) {
        dataController.loggedMealEvents
            .take(1)
            .map { mealEvents in
                return mealEvents.filter { $0.isDirty }
            }
            .subscribe(onNext: { [weak self] mealEvents in
                guard let welf = self, mealEvents.count > 0 else {
                    completion?(.nothingToSync)
                    return
                }

                let group = DispatchGroup()
                var syncResult: SyncResult = .complete

                mealEvents.forEach {
                    // Detatch from realm before syncing to avoid write transactions
                    guard let unmanagedMealEvent = $0.copy() as? MealEvent else { return }
                    group.enter()
                    welf.sync(unmanagedMealEvent) { result in
                        switch result {
                        case .synchronized:
                            break
                        default:
                            syncResult = .incomplete
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion?(syncResult)
                }
            })
            .disposed(by: bag)
    }

    func sync(_ mealEvent: MealEvent, completion: ((SaveResult<MealEvent>) -> Void)?) {
        dataController.saveMealEvent(mealEvent, completion: completion)
    }
}
