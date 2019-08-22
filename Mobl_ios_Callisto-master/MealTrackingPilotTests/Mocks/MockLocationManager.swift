//
//  MockLocationManager.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/19/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation

class MockLocationManager: CLLocationManager {

    var isMonitoringSignificantLocationChanges: Bool = false
    var isMonitoringVisits: Bool = false
    var didRequestAlwaysAuthorization: Bool = false

    override func startMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = true
    }

    override func stopMonitoringSignificantLocationChanges() {
        isMonitoringSignificantLocationChanges = false
    }

    override func startMonitoringVisits() {
        isMonitoringVisits = true
    }

    override func stopMonitoringVisits() {
        isMonitoringVisits = false
    }

    override func requestAlwaysAuthorization() {
        didRequestAlwaysAuthorization = true
        delegate?.locationManager?(self, didChangeAuthorization: .authorizedAlways)
    }
}
