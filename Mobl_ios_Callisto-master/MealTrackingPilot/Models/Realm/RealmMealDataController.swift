//
//  RealmMealDataController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm
import Intrepid


enum MealSaveError: Error {
    case invalidMealClassType
    case mealContainsEmptyPortion
    case mealContainsUnsynchronizedMeal(meal: Meal)
    case nameExists
}

enum ImageSaveError: Error {
    case invalidURL
}

enum ReportMealEventError: Error {
    case alreadyReported
    case invalidResponse
    case unableToPersist
}

class RealmMealDataController: MealDataController {

    let realm: Realm    // Main queue realm
    let realmConfiguration: Realm.Configuration // Used to create realm instances on background queues
    let apiClient: PilotAPIClient

    private let bag = DisposeBag()

    init(
        realmConfiguration: Realm.Configuration = Realm.Configuration(deleteRealmIfMigrationNeeded: true),
        apiClient: PilotAPIClient) throws {

        realm = try Realm(configuration: realmConfiguration)
        self.realmConfiguration = realmConfiguration
        self.apiClient = apiClient
    }

    // MARK: - Meals

    var loggedMealEvents: Observable<[MealEvent]> {
        let sortedMealEvents = realm.objects(RealmMealEvent.self).sorted(byKeyPath: "date", ascending: false)
        return Observable.collection(from: sortedMealEvents)
            .map { $0.toArray() }
    }

    func getLoggedMealEvents(completion: voidRequestCompletion?) {
        apiClient.getMealEvents { [weak self] result in
            guard let welf = self else {
                return
            }
            DispatchQueue.global().async {
                switch result {
                case .success(let mealEvents):
                    do {
                        let realm = try Realm(configuration: welf.realmConfiguration)
                        try realm.write {
                            mealEvents.forEach { mealEvent in
                                // Don't overwrite meals that have local changes
                                if let savedMealEvent = realm.object(ofType: RealmMealEvent.self, forPrimaryKey: mealEvent.localIdentifier),
                                    !savedMealEvent.isLocalOnly,
                                    savedMealEvent.isDirty {
                                    return
                                }
                                realm.add(mealEvent, update: .all)
                            }
                        }
                        completion?(.success(()))
                    } catch(let error) {
                        completion?(.failure(error))
                    }
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        }
    }

    // NOTE: MealEvent argument must be unmanaged by a Realm
    func saveMealEvent(_ mealEvent: MealEvent, completion: ((SaveResult<MealEvent>) -> Void)?) {
        guard let realmMealEvent = mealEvent as? RealmMealEvent else {
            completion?(.failure(MealSaveError.invalidMealClassType))
            return
        }

        let apiCallCompletion: relamMealEventCompletion = { [weak self] result in
            guard let welf = self else {
                return
            }

            switch result {
            case .success(let resultMealEvent):
                // Ensure that meal and portions are not marked dirty
                resultMealEvent.isDirty = false

                welf.asyncSave(resultMealEvent, completion: { realmResult in
                    switch realmResult {
                    case .success(let savedMealEvent):
                        completion?(.synchronized(savedMealEvent))
                    case .failure(let realmError):
                        completion?(.remoteOnly(resultMealEvent, realmError))
                    }
                })
            case .failure(let remoteError):
                welf.saveLocalOnly(mealEvent: realmMealEvent, remoteError: remoteError, completion: completion)
            }
        }

        do {
            try realmMealEvent.validateBeforeSave()
            performSaveMealEventAPICall(mealEvent: realmMealEvent, completion: apiCallCompletion)
        } catch let error as RealmMealEvent.ValidationError {
            switch error {
            case .mealEventContainsLocalOnlyMeal(_):
                saveMeal(realmMealEvent.meal) { [weak self] mealSaveResult in
                    switch mealSaveResult {
                    case .synchronized(let savedMeal):
                        mealEvent.meal = savedMeal
                        self?.performSaveMealEventAPICall(mealEvent: realmMealEvent, completion: apiCallCompletion)
                    case .failure(let mealError):
                        self?.removeLocalOnly(realmMealEvent)
                        completion?(.failure(mealError))
                    default:
                        self?.saveLocalOnly(mealEvent: realmMealEvent, remoteError: error, completion: completion)
                    }
                }
            }
        } catch let error {
            completion?(.failure(error))
        }
    }

    private func performSaveMealEventAPICall(mealEvent: RealmMealEvent, completion: relamMealEventCompletion?) {
        if mealEvent.isLocalOnly {
            apiClient.createMealEvent(mealEvent, completion: completion)
        } else {
            apiClient.updateMealEvent(mealEvent, completion: completion)
        }
    }

    func reportMealEvent(_ mealEvent: MealEvent, completion: mealEventCompletion?) {
        guard !mealEvent.isFlagged else {
            completion?(.failure(ReportMealEventError.alreadyReported))
            return
        }

        apiClient.reportMealEvents([mealEvent]) { [weak self] result in
            guard let welf = self else { return }

            switch result {
            case .success(let mealEvents):
                guard let newMealEvent = mealEvents.first else {
                    completion?(.failure(ReportMealEventError.invalidResponse))
                    return
                }

                do {
                    try welf.realm.write {
                        welf.realm.add(newMealEvent, update: .all)
                    }
                } catch {
                    completion?(.failure(ReportMealEventError.unableToPersist))
                }

                completion?(.success(newMealEvent))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    // MARK: - Meals

    func observableMeals(forClassification classification: MealClassification) -> Observable<[Meal]> {
        let result = realm.objects(RealmMeal.self)
            .filter("classificationRawValue == %@ && isHidden == false", classification.rawValue)
            .sorted(byKeyPath: "name", ascending: false)
        return Observable.collection(from: result)
            .map { $0.toArray() }
    }

    func getMeals(forClassification classification: MealClassification, completion: voidRequestCompletion?) {
        apiClient.getMeals(forClassification: classification) { [weak self] result in
            guard let welf = self else { return }
            switch result {
            case .success(let meals):
                try! welf.realm.write {
                    welf.realm.add(meals, update: .all)
                }

                let existingMeals = welf.realm.objects(RealmMeal.self).toArray().filter { $0.classification == .test && $0.isHidden == false }
                let mealsHidden = existingMeals.removingObjectsInArray(meals)
                if !mealsHidden.isEmpty {
                    try! welf.realm.write {
                        mealsHidden.forEach { $0.isHidden = true }
                        welf.realm.add(mealsHidden, update: .all)
                    }
                }

                completion?(.success(()))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    // Only set shouldValidate = true when creating a meal, don't validate during sync process
    func saveMeal(_ meal: Meal, shouldValidate: Bool = false, completion: ((SaveResult<Meal>) -> Void)?) {
        guard let realmMeal = meal as? RealmMeal else {
            completion?(.failure(MealSaveError.invalidMealClassType))
            return
        }

        apiClient.createMeal(meal) { [weak self] result in
            guard let welf = self else { return }

            switch result {
            case .success(let resultMeal):
                realmMeal.isDirty = false

                welf.asyncSave(resultMeal, completion: { realmResult in
                    switch realmResult {
                    case .success(let savedMeal):
                        completion?(.synchronized(savedMeal))
                    case .failure(let realmError):
                        completion?(.remoteOnly(realmMeal, realmError))
                    }
                })
            case .failure(let remoteError):
                welf.saveLocalOnly(meal: realmMeal, remoteError: remoteError, shouldValidate: shouldValidate, completion: completion)
            }
        }
    }

    var mealStatistics: Observable<MealStatistics> {
        return loggedMealEvents.map { mealEvents in
            return MealStatistics(mealEvents: mealEvents)
        }
    }

    // MARK: - Local Only Save

    private func saveLocalOnly(meal: RealmMeal, remoteError: Error, shouldValidate: Bool, completion: ((SaveResult<Meal>) -> Void)?) {
        // Validate that meal with the same name doesn't already exist
        guard !shouldValidate ||
            realm.objects(RealmMeal.self)
            .filter({ $0.name == meal.name })
            .isEmpty
        else {
            completion?(.failure(MealSaveError.nameExists))
            return
        }

        saveLocalOnly(meal, remoteError: remoteError) { saveResult in
            switch saveResult {
            case .synchronized(let savedMeal):
                completion?(.synchronized(savedMeal))
            case .localOnly(let savedMeal, let error):
                completion?(.localOnly(savedMeal, error))
            case .remoteOnly(let savedMeal, let error):
                completion?(.remoteOnly(savedMeal, error))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    private func saveLocalOnly(mealEvent: RealmMealEvent, remoteError: Error, completion: ((SaveResult<MealEvent>) -> Void)?) {
        saveLocalOnly(mealEvent, remoteError: remoteError) { saveResult in
            switch saveResult {
            case .synchronized(let savedMealEvent):
                completion?(.synchronized(savedMealEvent))
            case .localOnly(let savedMealEvent, let error):
                completion?(.localOnly(savedMealEvent, error))
            case .remoteOnly(let savedMealEvent, let error):
                completion?(.remoteOnly(savedMealEvent, error))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    private func saveLocalOnly<T: RealmSynchronizable>(_ object: T, remoteError: Error, completion: ((SaveResult<T>) -> Void)?) {
        // If object could not be saved due to unprocessable entity, do not save locally
        switch remoteError {
        case APIClientError.httpError(let statusCode, _, _):
            if statusCode == 422 {
                // If we previously saved the object locally, remove it
                removeLocalOnly(object)
                completion?(.failure(remoteError))
                return
            }
        default:
            break
        }

        object.isDirty = true

        asyncSave(object, completion: { realmResult in
            switch realmResult {
            case .success(let savedObject):
                completion?(.localOnly(savedObject, remoteError))
            case .failure(let realmError):
                completion?(.failure(realmError))
            }
        })
    }

    private func removeLocalOnly<T: RealmSynchronizable>(_ object: T) {
        guard
            let managedObject = object.realm == realm ? object : realm.object(ofType: T.self, forPrimaryKey: object.localIdentifier),
            managedObject.isLocalOnly
        else { return }

        do {
            try realm.write {
                realm.delete(managedObject)
            }
        } catch {
            print("Error deleting Realm object: \(error)")
        }
    }

    // MARK: - Background Thread Writing

    // TODO: Eventually this may dispatch to a background thread
    func asyncSave<T: Object>(_ object: T, completion: ((Result<T,Error>) -> Void)?) {
        do {
            try realm.write {
                realm.add(object, update: .all)
            }
            completion?(.success(object))
        } catch(let error) {
            completion?(.failure(error))
        }
    }

    // MARK: - Reset

    func reset() {
        try! realm.write {
            realm.deleteAll()
        }
    }
}
