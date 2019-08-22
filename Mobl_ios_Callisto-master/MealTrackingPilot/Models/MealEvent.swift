//
//  MealEvent.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/13/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import KeychainAccess

public enum MealEventPortion: String {

    private struct JSONValue {
        static let regular = "Regular"
        static let small = "Small"
        static let large = "Large"
    }

    case usual
    case less
    case more

    static let orderedValues: [MealEventPortion] = [
        .less, .usual, .more
    ]

    init?(jsonValue: String) {
        switch jsonValue {
        case JSONValue.regular:
            self = .usual
        case JSONValue.small:
            self = .less
        case JSONValue.large:
            self = .more
        default:
            return nil
        }
    }

    var jsonValue: String {
        switch self {
        case .usual:
            return JSONValue.regular
        case .less:
            return JSONValue.small
        case .more:
            return JSONValue.large
        }
    }
}

protocol MealEvent: Synchronizable, NSCopying {
    var meal: Meal { get set }
    var date: Date { get set }
    var imageURL: URL? { get set }
    var imageData: Data? { get set }
    var imageURLRequest: URLRequest? { get }
    var portion: MealEventPortion { get set }
    var note: String { get set }
    var classification: MealClassification { get }
    var isFlagged: Bool { get set }
    var json: [String: Any]? { get }
}
