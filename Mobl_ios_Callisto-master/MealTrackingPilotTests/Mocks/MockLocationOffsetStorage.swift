//
//  MockLocationOffsetStorage.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 6/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation
@testable import MealTrackingPilot

class MockLocationOffsetStorage: LocationOffsetProviding {

    var offset: CLLocationCoordinate2D?

    init(offset: CLLocationCoordinate2D? = nil) {
        self.offset = offset
    }
}
