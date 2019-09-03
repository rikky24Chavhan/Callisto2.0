//
//  Location.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation
import Realm
import RealmSwift

protocol Location {
    var arrivalDate: Date { get }
    var departureDate: Date { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var accuracyMeters: Double { get }

    var json: [String: Any]? { get }
}

public final class RealmLocation: RealmSwift.Object, Location, Codable {

    // MARK: - Properties

    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var arrivalDate: Date = Date()
    @objc dynamic var departureDate: Date = Date()
    @objc dynamic var latitude: Double = 0
    @objc dynamic var longitude: Double = 0
    @objc dynamic var accuracyMeters: CLLocationAccuracy = 0

    enum CodingKeys: String, CodingKey {
        case arrivalDate = "arrived_at"
        case departureDate = "departed_at"
        case latitude
        case longitude
        case accuracyMeters = "accuracy_in_meters"
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // MARK: - Lifecycle

    convenience init(visit: CLVisit, offsetProvider: LocationOffsetProviding? = nil) {
        self.init()
        localIdentifier = NSUUID().uuidString
        arrivalDate = visit.arrivalDate
        departureDate = visit.departureDate
        let coordinate = visit.coordinate.obscured(offsetProvider: offsetProvider)
        longitude = coordinate.longitude
        latitude = coordinate.latitude
        accuracyMeters = visit.horizontalAccuracy
    }

    convenience init(location: CLLocation, offsetProvider: LocationOffsetProviding? = nil) {
        self.init()
        localIdentifier = NSUUID().uuidString
        arrivalDate = location.timestamp
        departureDate = location.timestamp
        let coordinate = location.coordinate.obscured(offsetProvider: offsetProvider)
        longitude = coordinate.longitude
        latitude = coordinate.latitude
        accuracyMeters = location.horizontalAccuracy
    }

    override public class func primaryKey() -> String? {
        return "localIdentifier"
    }

    var json: [String : Any]? {
        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        do {
            let data = try jsonEncoder.encode(self)
            if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                return ["location" : json]
            }
        } catch {
            print(error)
        }
        return nil
    }
}
