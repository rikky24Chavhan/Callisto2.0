//
//  RealmMealEvent.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 3/15/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift
import AlamofireImage

public final class RealmMealEvent: RealmSynchronizable, MealEvent, Codable {

    enum CodingKeys: String, CodingKey {
        case portion
        case notes
        case meal
        case imageURL = "image_url"
        case imageData = "image_data"
        case imageType = "image_type"
        case imageOrientation = "image_orientation"
        case flaggedAt = "flagged_at"
        case consumedAt = "consumed_at"
        case carbs
        case mealId = "meal_id"

        case identifier = "id"
        case localIdentifier = "client_id"
        case createdDate = "inserted_at"
        case updatedDate = "updated_at"
    }

    var fileManager: FileManager = .default

    @objc dynamic var realmMeal: RealmMeal? = RealmMeal()
    @objc dynamic var date: Date = Date()
    @objc dynamic var imageURLString: String?
    @objc dynamic var imageDataString: String? {
        didSet {
            if imageDataString != nil {
                imageTypeString = "jpeg"
            } else {
                imageDataString = nil
            }
        }
    }
    @objc dynamic var imageTypeString: String?
    @objc dynamic var localImageFileName: String?
    @objc dynamic var portionRawValue: String = ""
    @objc dynamic var note: String = ""
    @objc dynamic var isFlagged: Bool = false

    var meal: Meal {
        get {
            return realmMeal!
        }
        set {
            if let realmMeal = newValue as? RealmMeal {
                self.realmMeal = realmMeal
            }
        }
    }

    // Local images are stored in the Documents directory and cannot be stored as absolute paths
    var imageURL: URL? {
        get {
            if let imageURLString = imageURLString {
                return URL(string: imageURLString)
            } else if let localImageFileName = localImageFileName {
                guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return nil
                }
                return documentsURL.appendingPathComponent(localImageFileName)
            } else {
                return nil
            }
        }
        set {
            if let newValue = newValue, newValue.isFileURL {
                localImageFileName = newValue.lastPathComponent
                imageURLString = nil
            } else {
                imageURLString = newValue?.absoluteString
                localImageFileName = nil
            }
        }
    }

    var imageData: Data? {
        get {
            if let imageDataString = imageDataString {
                return imageDataString.data(using: .utf8)
            } else {
                return nil
            }
        }
        set {
            // Remove cached image data so that image will reload on dashboard
            if let urlRequest = imageURLRequest {
                let _ = ImageDownloader.default.imageCache?.removeImage(for: urlRequest, withIdentifier: nil)
                ImageDownloader.default.session.sessionConfiguration.urlCache?.removeCachedResponse(for: urlRequest)
            }

            // Send an empty string to the backend if the original image has been removed
            let stringifiedData = newValue == Data() ? "" : newValue?.base64EncodedString(options: .lineLength64Characters)
            imageDataString = stringifiedData
        }
    }

    var imageURLRequest: URLRequest? {
        guard let url = imageURL else { return nil }

        var request = PilotRequest.downloadImage(at: url).urlRequest
        request.addValue("image/jpeg", forHTTPHeaderField: "Accept")

        return request
    }

    var portion: MealEventPortion {
        get {
            return MealEventPortion(rawValue: portionRawValue) ?? .usual
        }
        set {
            portionRawValue = newValue.rawValue
        }
    }

    // MARK: - MealEvent Protocol

    var classification: MealClassification {
        return meal.classification
    }

    // MARK: - Realm

    public override class func ignoredProperties() -> [String] {
        return [
            "meal",
            "imageURL",
            "classification",
            "portion",
            "fileManager"
        ]
    }

    // MARK: - Init

    public convenience init(meal: RealmMeal) {
        self.init()
        self.realmMeal = RealmMeal(value: meal) // Use unmanaged version of meal
    }

    // MARK: - Codable

    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.realmMeal = try container.decode(RealmMeal.self, forKey: .meal)
        self.imageURLString = try? container.decode(String.self, forKey: .imageURL)
        self.imageTypeString = try? container.decode(String.self, forKey: .imageType)
        self.imageDataString = try? container.decode(String.self, forKey: .imageData)
        self.note = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.date = try container.decodeCallistoDate(forKey: .consumedAt)
        let portionJSONValue = try container.decode(String.self, forKey: .portion)
        self.portionRawValue = MealEventPortion(jsonValue: portionJSONValue)?.rawValue ?? MealEventPortion.usual.rawValue
        let flaggedAt = try? container.decodeCallistoDate(forKey: .flaggedAt)
        self.isFlagged = flaggedAt != nil

        identifier = try container.decode(String.self, forKey: .identifier)
        localIdentifier = try container.decodeIfPresent(String.self, forKey: .localIdentifier) ?? ""
        createdDate = try container.decodeCallistoDate(forKey: .createdDate)
        updatedDate = try container.decodeCallistoDate(forKey: .updatedDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(realmMeal?.identifier, forKey: .mealId)
        try container.encodeIfPresent(imageDataString, forKey: .imageData)
        try container.encodeIfPresent(imageTypeString, forKey: .imageType)
        try container.encodeIfPresent(note, forKey: .notes)
        try container.encode(localIdentifier, forKey: .localIdentifier)
        try container.encode(date, forKey: .consumedAt)
        let portionJSONValue = MealEventPortion(rawValue: portionRawValue)?.jsonValue
        try container.encode(portionJSONValue, forKey: .portion)
    }

    // MARK: - JSON

    var json: [String : Any]? {
        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        do {
            let data = try jsonEncoder.encode(self)
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                return ["meal_event" : json]
            }
        } catch {
            print(error)
        }
        return nil
    }

    // MARK: - Validation

    enum ValidationError: Error {
        case mealEventContainsLocalOnlyMeal(meal: Meal)
    }

    func validateBeforeSave() throws {
        if meal.isLocalOnly {
            throw ValidationError.mealEventContainsLocalOnlyMeal(meal: meal)
        }
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = RealmMealEvent(value: self)
        copy.meal = RealmMeal(value: meal)
        return copy
    }
}

