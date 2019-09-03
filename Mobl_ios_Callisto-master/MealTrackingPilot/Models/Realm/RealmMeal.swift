//
//  RealmMeal.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift

public final class RealmMeal: RealmSynchronizable, Meal, Codable {

    private struct Constants {
        static let portionSizeKey = "portion_size"
    }

    private enum CodingKeys: String, CodingKey {
        case isTestMeal = "test_meal"
        case offasions
        case name
        case hiddenAt = "hidden_at"
        case hasDosageRecommendation = "dosage_recommendation"
        case location = "source"
        case portionOunces = "portion_size"
        case carbGrams = "carbs"
        case occasionsRawValue = "occasions"

        case identifier = "id"
        case localIdentifier = "client_id"
        case createdDate = "inserted_at"
        case updatedDate = "updated_at"
    }

    @objc dynamic var name: String = ""
    @objc dynamic var classificationRawValue: String = MealClassification.common.rawValue
    @objc dynamic var occasionsRawValue: String = ""
    @objc dynamic var carbGrams: Double = 0
    @objc dynamic var hasDosingRecommendation: Bool = false
    @objc dynamic var location: String?
    @objc dynamic var portionOunces: Double = 0
    @objc dynamic var isHidden: Bool = false

    var loggingGoal: Int {
        switch classification {
        case .common:
            return 0    // Logging goal unused for common meals
        case .test:
            return 5
        }
    }

    // MARK: - Computed Properties

    var classification: MealClassification {
        get {
            return MealClassification(rawValue: classificationRawValue) ?? .common
        }
        set {
            classificationRawValue = newValue.rawValue
        }
    }

    var occasions: [MealOccasion] {
        get {
            return (try? MealOccasion.deserialize(occasionsRawValue)) ?? []
        }
        set {
            occasionsRawValue = MealOccasion.serialize(occasions: newValue)
        }
    }

    // MARK: - Realm

    public override class func ignoredProperties() -> [String] {
        return [
            "classification",
            "occasions",
        ]
    }

    // MARK: - Codable

    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        self.name = try container.decode(String.self, forKey: .name)
        let hiddenAt = try? container.decodeCallistoDate(forKey: .hiddenAt)
        self.isHidden = hiddenAt != nil
        self.hasDosingRecommendation = try container.decodeIfPresent(Bool.self, forKey: .hasDosageRecommendation) ?? false
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.portionOunces = try container.decodeIfPresent(Double.self, forKey: .portionOunces) ?? 0
        self.carbGrams = try container.decodeIfPresent(Double.self, forKey: .carbGrams) ?? 0
        let isTestMeal = try container.decode(Bool.self, forKey: .isTestMeal)
        self.classificationRawValue = isTestMeal ? MealClassification.test.rawValue : MealClassification.common.rawValue
        self.occasionsRawValue = try container.decodeMealOccasionsIfPresent(forKey: .occasionsRawValue) ?? ""

        identifier = try container.decode(String.self, forKey: .identifier)
        localIdentifier = try container.decodeIfPresent(String.self, forKey: .localIdentifier) ?? ""
        createdDate = try container.decodeCallistoDate(forKey: .createdDate)
        updatedDate = try container.decodeCallistoDate(forKey: .updatedDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(occasions.map({ $0.jsonValue }), forKey: .occasionsRawValue)
        try container.encode(carbGrams, forKey: .carbGrams)
        try container.encode(localIdentifier, forKey: .localIdentifier)
    }

    // MARK: - JSON

    var json: [String : Any]? {
        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        do {
            let data = try jsonEncoder.encode(self)
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                return ["meal" : json]
            }
        } catch {
            print(error)
        }
        return nil
    }
}

// MARK: - Occasion Serialization

fileprivate enum MealOccasionDeserializationError: Error {
    case invalidOccasionValue(rawValue: String)
}

fileprivate let defaultOccasionDelimiter = "-"

fileprivate extension MealOccasion {
    static func deserialize(_ rawValue: String, withDelimiter delimiter: String = defaultOccasionDelimiter) throws -> [MealOccasion] {
        let values = rawValue.components(separatedBy: delimiter)
        return try values.map {
            guard let occasion = MealOccasion(rawValue: $0) else {
                throw MealOccasionDeserializationError.invalidOccasionValue(rawValue: $0)
            }
            return occasion
        }
    }

    static func serialize(occasions: [MealOccasion], withDelimiter delimiter: String = defaultOccasionDelimiter) -> String {
        return occasions.map { $0.rawValue }.joined(separator: delimiter)
    }
}
