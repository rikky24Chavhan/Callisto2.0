//
//  MockHealthStore.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import HealthKit

enum MockHealthStoreError: Error {
    case authorizationFailure
}

class MockHealthStore: HKHealthStore {

    var requestAuthorizationShouldSucceed = true

    var readTypesRequested = Set<HKObjectType>()
    var lastQuery: HKQuery?

    override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        if let typesToRead = typesToRead {
            readTypesRequested = readTypesRequested.union(typesToRead)
        }

        let error = requestAuthorizationShouldSucceed ? nil : MockHealthStoreError.authorizationFailure
        completion(requestAuthorizationShouldSucceed, error)
    }

    override func execute(_ query: HKQuery) {
        if let statisticsCollectionQuery = query as? HKStatisticsCollectionQuery {
            // TODO: find a way to mock/create HKStatisticsCollection
            statisticsCollectionQuery.initialResultsHandler?(statisticsCollectionQuery, nil, nil)
        }
        lastQuery = query
    }
}
