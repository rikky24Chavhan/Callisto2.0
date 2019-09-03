//
//  CLLocationCoordinate2D+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationOffsetProviding {
    var offset: CLLocationCoordinate2D? { get set }
}

extension CLLocationCoordinate2D {
    func obscured(offsetProvider: LocationOffsetProviding? = nil) -> CLLocationCoordinate2D {
        guard var offsetProvider = offsetProvider else {
            return self
        }

        let saveNewOffset: (() -> CLLocationCoordinate2D) = {
            func getRandomOffset() -> Double {
                return Double(arc4random()) / Double(UINT32_MAX)
            }

            let newOffset = CLLocationCoordinate2D(latitude: getRandomOffset(), longitude: getRandomOffset())
            offsetProvider.offset = newOffset
            return newOffset
        }

        let offset = offsetProvider.offset ?? saveNewOffset()

        return CLLocationCoordinate2D(
            latitude: latitude.obscured(withOffset: offset.latitude),
            longitude: longitude.obscured(withOffset: offset.longitude))
    }
}

extension CLLocationCoordinate2D: Codable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.init()
        longitude = try container.decode(Double.self)
        latitude = try container.decode(Double.self)

    }
}

extension CLLocationDegrees {
    fileprivate func obscured(withOffset offset: Double) -> CLLocationDegrees {
        return 180 * exp(-1 * self / 180 + offset)
    }
}
