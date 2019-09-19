//
//  HealthKitController.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 2/28/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import HealthKit
import RealmSwift


public final class HealthKitController: RealmSyncController {

    private struct UserDefaultsKey {
        static let stepQueryAnchorDate = "stepQueryAnchorDate"
    }

    // MARK: - Properties

    let healthStore: HKHealthStore
    let realm: Realm
    let apiClient: PilotAPIClient
    let userDefaults: UserDefaults
    private let isHealthDataAvailable: () -> Bool
    let loginUserProvider: LoginUserProviding

    private let healthKitPermissions: Set<HKSampleType>

    private(set) var anchorDate: Date {
        get {
            let timeInterval = userDefaults.double(forKey: UserDefaultsKey.stepQueryAnchorDate)
            if timeInterval == 0 {
                return Date()
            } else {
                return Date(timeIntervalSince1970: timeInterval)
            }
        } set {
            userDefaults.set(newValue.timeIntervalSince1970, forKey: UserDefaultsKey.stepQueryAnchorDate)
        }
    }

    enum HealthKitType: Int {
        case steps
        var sampleType: HKQuantityType? {
            switch self {
            case .steps:
                return HKObjectType.quantityType(forIdentifier: .stepCount)
            }
        }
        static var allSampleTypes: [HKQuantityType] {
            var sampleTypes: [HKQuantityType] = []
            var currentIndex = 0
            while let hkType = HealthKitType(rawValue: currentIndex) {
                if let sampleType = hkType.sampleType {
                    sampleTypes.append(sampleType)
                }
                currentIndex += 1
            }
            return sampleTypes
        }
    }

    enum HealthKitError: Error {
        case healthKitUnavailable
        case primaryLoginRequired
        case syncNotNeeded
        case failedToSave
    }

    // MARK: - Lifecycle

    init(
        healthStore: HKHealthStore = HKHealthStore(),
        realm: Realm = try! Realm(configuration: Realm.Configuration(deleteRealmIfMigrationNeeded: true)),
        apiClient: PilotAPIClient,
        loginUserProvider: LoginUserProviding,
        userDefaults: UserDefaults = .standard,
        healthDataAvailableGetter: @escaping (() -> Bool) = HKHealthStore.isHealthDataAvailable) {

        self.healthStore = healthStore
        self.realm = realm
        self.apiClient = apiClient
        self.loginUserProvider = loginUserProvider
        self.userDefaults = userDefaults
        self.isHealthDataAvailable = healthDataAvailableGetter

        healthKitPermissions = Set(HealthKitType.allSampleTypes)
    }

    // MARK: - Actions

    func queryNewHourlyStepSamples() {
        var hourComponent = DateComponents()
        hourComponent.hour = 1
        queryCumulativeSum(.steps, startDate: anchorDate, intervalComponents: hourComponent) { [weak self] result in
            switch result {
                case .success:
                    self?.anchorDate = Date()
                default:
                    return
            }
        }
    }

    // MARK: Authorization

    func requestAuthorization(completion: boolResultCompletion? = nil) {
        guard isHealthDataAvailable() else {
            completion?(.failure(HealthKitError.healthKitUnavailable))
            return
        }
        guard loginUserProvider.isLoggedInAsPrimaryUser() else {
            completion?(.failure(HealthKitError.primaryLoginRequired))
            return
        }
        healthStore.requestAuthorization(toShare: nil, read: healthKitPermissions) { [weak self] authorizationCompleted, error in
            guard let welf = self else { return }

            if let error = error {
                switch error {
                    case HKError.errorAuthorizationNotDetermined:
                        if #available(iOS 11, *) {
                            welf.requestAuthorization(completion: completion)
                        } else {
                            After(1) { // iOS 9 and 10 need a delay before presenting the request again.
                                welf.requestAuthorization(completion: completion)
                            }
                        }
                    default:
                        completion?(.failure(error))
                }
            } else {
                completion?(.success(authorizationCompleted))
            }
        }
    }

    // MARK: Query Data

    func queryCumulativeSum(_ healthKitType: HealthKitType, startDate: Date, intervalComponents: DateComponents, completion: voidRequestCompletion? = nil) {
        guard isHealthDataAvailable(), let sampleType = healthKitType.sampleType else {
            completion?(.failure(HealthKitError.healthKitUnavailable))
            return
        }
        guard loginUserProvider.isLoggedInAsPrimaryUser() else {
            completion?(.failure(HealthKitError.primaryLoginRequired))
            return
        }
        let anchorDate = Date().startOfDay  // Actual date doesn't matter, we just want to anchor the query to the top of the hour
        let query = HKStatisticsCollectionQuery(quantityType: sampleType, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: intervalComponents)
            query.initialResultsHandler = { (query, collection, error) in
                guard error == nil else {
                    print("HKStatisticsCollectionQuery error: \(error!)")
                    return
                }

                // Don't include steps from current incomplete hour, they will be included in next query
                /* MIGRATION-COMMENT-NEED-TO-FIX
                 let startOfCurrentHour = Date().startOf(component: .hour)
                 */

                // Get statistics until the last second of the previous hour
                let endDate = Date().addingTimeInterval(-1)

                // Only collect statistics for a valid date range
                if startDate < endDate && collection != nil {
                    collection?.enumerateStatistics(from: startDate, to: endDate) { [weak self] (statistics, stop) in
                        guard let sample = RealmStepSample(sumStatistics: statistics) else { return }
                        do {
                            try self?.saveObject(sample)
                            completion?(.success(()))
                        } catch(let error) {
                            print("Failed to save object: \(error)")
                            completion?(.failure(HealthKitError.failedToSave))
                        }
                    }
                } else {
                    completion?(.failure(HealthKitError.syncNotNeeded))
                }
            }
            healthStore.execute(query)
    }

    // MARK: - RealmSyncController

    typealias SyncableObject = RealmStepSample

    func createObject(_ object: RealmStepSample, completion: voidRequestCompletion?) {
        apiClient.createStepSample(object, completion: completion)
    }

    func hasDataAccessPermissions() -> Bool {
        return loginUserProvider.isLoggedInAsPrimaryUser()
    }
}

extension HealthKitController: PermissionRequestController {
    func requestPermissions(completion: @escaping () -> Void) {
        // Set anchorDate to current date and time so step tracking starts on next launch
        anchorDate = Date()
        requestAuthorization(completion: { _ in
            completion()
        })
    }
}
