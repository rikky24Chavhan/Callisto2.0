//
//  Meal.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/13/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

public enum MealClassification: String {
    case common
    case test
}

public enum MealOccasion: String, Codable {
    private struct JSONValue {
        static let breakfast = "Breakfast"
        static let lunch = "Lunch"
        static let dinner = "Dinner"
        static let snack = "Snacks"
        static let dessert = "Desserts"
        static let drink = "Drinks"
    }

    case breakfast
    case lunch
    case dinner
    case snack
    case dessert
    case drink

    static let orderedValues: [MealOccasion] = [
        .breakfast, .lunch, .dinner, .snack, .dessert, .drink
    ]

    static let jsonPluralizedValues: [MealOccasion] = [
        .snack, .dessert, .drink
    ]

    var displayValue: String {
        return rawValue.capitalized
    }

    init?(jsonValue: String) {
        switch jsonValue {
        case JSONValue.breakfast:
            self = .breakfast
        case JSONValue.lunch:
            self = .lunch
        case JSONValue.dinner:
            self = .dinner
        case JSONValue.snack:
            self = .snack
        case JSONValue.dessert:
            self = .dessert
        case JSONValue.drink:
            self = .drink
        default:
            return nil
        }
    }

    var jsonValue: String {
        switch self {
        case .breakfast:
            return JSONValue.breakfast
        case .lunch:
            return JSONValue.lunch
        case .dinner:
            return JSONValue.dinner
        case .snack:
            return JSONValue.snack
        case .dessert:
            return JSONValue.dessert
        case .drink :
            return JSONValue.drink
        }
    }
}

protocol Meal: Synchronizable {
    var name: String { get set }
    var classification: MealClassification { get set }
    var occasions: [MealOccasion] { get set }
    var carbGrams: Double { get set }
    var hasDosingRecommendation: Bool { get set }
    var location: String? { get set }
    var portionOunces: Double { get set }
    var loggingGoal: Int { get }
    var isHidden: Bool { get }
    var json: [String : Any]? { get }
}
