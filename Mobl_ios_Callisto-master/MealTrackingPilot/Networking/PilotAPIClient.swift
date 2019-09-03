//
//  PilotAPIClient.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/9/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

class PilotAPIClient: APIClient {
    var accessCredentialsProvider: AccessCredentialProviding?

    private var accessCredentials: AccessCredentials? {
        return accessCredentialsProvider?.accessCredentials
    }

    func getCurrentUser(completion: currentUserCompletion?) {
        let request = PilotRequest.getCurrentUser(accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "user", completion: completion)
    }

    func getMeals(forClassification classification: MealClassification, completion: relamMealsCompletion?) {
        let request = PilotRequest.getMeals(classification: classification, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meals", completion: completion)
    }

    func createMeal(_ meal: Meal, completion: relamMealCompletion?) {
        let request = PilotRequest.createMeal(meal, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meal", completion: completion)
    }

    func getMealEvents(completion: relamMealEventsCompletion?) {
        let request = PilotRequest.getMealEvents(accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meal_events", completion: completion)
    }

    func createMealEvent(_ mealEvent: MealEvent, completion: relamMealEventCompletion?) {
        let request = PilotRequest.createMealEvent(mealEvent, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meal_event", completion: completion)
    }

    func createLocation(_ location: Location, completion: voidRequestCompletion?) {
        let request = PilotRequest.createLocation(location, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, completion: completion)
    }

    func createStepSample(_ stepSample: StepSample, completion: voidRequestCompletion?) {
        let request = PilotRequest.createStepSample(stepSample, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, completion: completion)
    }

    func updateMealEvent(_ mealEvent: MealEvent, completion: relamMealEventCompletion?) {
        let request = PilotRequest.updateMealEvent(mealEvent, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meal_event", completion: completion)
    }

    func reportMealEvents(_ mealEvents: [MealEvent], completion: relamMealEventsCompletion?) {
        let request = PilotRequest.reportMealEvents(mealEvents, accessCredentials: accessCredentials).urlRequest
        sendRequest(request, keyPath: "meal_events", completion: completion)
    }
}

enum DemoPilotAPIClientError: Error {
    case unsupportedRequest
    case unsupportedType
}

class DemoPilotAPIClient: PilotAPIClient {
    override func createMeal(_ meal: Meal, completion: relamMealCompletion?) {
        DispatchQueue.main.async {
            if let realmMeal = meal as? RealmMeal {
                realmMeal.identifier = UUID().uuidString
                completion?(.success(realmMeal))
            } else {
                completion?(.failure(DemoPilotAPIClientError.unsupportedType))
            }
        }
    }
    
    override func getMealEvents(completion: relamMealEventsCompletion?) {
        DispatchQueue.main.async {
            completion?(.success([]))
        }
    }
    
    override func createMealEvent(_ mealEvent: MealEvent, completion: relamMealEventCompletion?) {
        DispatchQueue.main.async {
            if let realmMealEvent = mealEvent as? RealmMealEvent {
                realmMealEvent.identifier = UUID().uuidString
                completion?(.success(realmMealEvent))
            } else {
                completion?(.failure(DemoPilotAPIClientError.unsupportedType))
            }
        }
    }
    
    override func updateMealEvent(_ mealEvent: MealEvent, completion: relamMealEventCompletion?) {
        DispatchQueue.main.async {
            if let realmMealEvent = mealEvent as? RealmMealEvent {
                completion?(.success(realmMealEvent))
            } else {
                completion?(.failure(DemoPilotAPIClientError.unsupportedType))
            }
        }
    }
    
    override func reportMealEvents(_ mealEvents: [MealEvent], completion: relamMealEventsCompletion?) {
        DispatchQueue.main.async {
            if let realmMealEvents = mealEvents as? [RealmMealEvent] {
                realmMealEvents.forEach({ event in
                    if let realm = event.realm {
                        try? realm.write {
                            event.isFlagged = true
                        }
                    } else {
                        event.isFlagged = true
                    }
                })
                completion?(.success(realmMealEvents))
            } else {
                completion?(.failure(DemoPilotAPIClientError.unsupportedType))
            }
        }
    }
}

