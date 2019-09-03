//
//  PilotAPIClientConstant.swift
//  MealTrackingPilot
//
//  Created by Rikky Chavhan on 22/07/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation

typealias voidRequestCompletion = (Result<Void?,Error>) -> Void

typealias boolResultCompletion = (Result<Bool,Error>) -> Void

typealias relamMealEventsCompletion = (Result<[RealmMealEvent],Error>) -> Void

typealias relamMealEventCompletion = (Result<RealmMealEvent,Error>) -> Void

typealias mealEventCompletion = (Result<MealEvent,Error>) -> Void

typealias relamMealCompletion = (Result<RealmMeal,Error>) -> Void

typealias relamMealsCompletion = (Result<[RealmMeal],Error>) -> Void

typealias currentUserCompletion = (Result<PilotUser,Error>) -> Void

typealias genericCompletion<T> = ((Result<T,Error>) -> Void)

public typealias defaultRequestCompletion = ((Result<Data?,Error>)?) -> Void

public typealias accessCredentialsCompletion = (Result<AccessCredentials,Error>) -> Void


