//
//  TestVisit.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation

class TestVisit: CLVisit {
    private let creationDate = Date()

    override var arrivalDate: Date {
        return Date.distantPast
    }

    override var departureDate: Date {
        return creationDate
    }

    override var coordinate: CLLocationCoordinate2D {
        let intrepidCoordinates = CLLocationCoordinate2D(latitude: 42.367152, longitude: -71.080197)
        return intrepidCoordinates
    }

    override var horizontalAccuracy: CLLocationAccuracy {
        return 0.0
    }
}
