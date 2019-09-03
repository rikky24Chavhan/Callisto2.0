//
//  LocationOffsetKeychainStorage.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 6/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation

class LocationOffsetKeychainStorage: KeychainValueStorage<CLLocationCoordinate2D>, LocationOffsetProviding {

    init(keychainServiceName: String = "io.intrepid.MealTrackingPilot") {
        super.init(keychainServiceName: keychainServiceName, storageKey: "locationOffset")
    }

    var offset: CLLocationCoordinate2D? {
        get {
            return value
        }
        set {
            value = newValue
        }
    }
}
