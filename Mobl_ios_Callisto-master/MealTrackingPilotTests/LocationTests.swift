//
//  LocationTests.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import XCTest
import CoreLocation
import RealmSwift
import RxRealm
@testable import MealTrackingPilot

class LocationTests: XCTestCase {

    let realmConfiguration = Realm.Configuration(inMemoryIdentifier: "LocationTests-\(UUID())")
    lazy var realm: Realm = {
        return try! Realm(configuration: self.realmConfiguration)
    }()

    let mockAPIClient = MockPilotAPIClient()
    let mockLocationManager = MockLocationManager()
    let mockLoginUserProvider = MockLoginUserProvider(mockIsLoggedInAsPrimaryUser: true)

    override func setUp() {
        super.setUp()
        try! realm.write {
            realm.deleteAll()
        }
    }

    func testVisitParsing() {
        let clVisit = TestVisit()
        let location = RealmLocation(visit: clVisit)
        XCTAssertEqual(location.arrivalDate, Date.distantPast)
        XCTAssertEqual(location.departureDate, clVisit.departureDate)
        XCTAssertEqual(location.coordinate.latitude, clVisit.coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, clVisit.coordinate.longitude)
        XCTAssertEqual(location.accuracyMeters, 0.0)
    }

    func testLocationParsing() {
        let coordinate = CLLocationCoordinate2D(latitude: 42.367152, longitude: -71.080197)
        let clLocation = CLLocation(coordinate: coordinate, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, timestamp: Date())
        let location = RealmLocation(location: clLocation)
        XCTAssertEqual(location.arrivalDate, clLocation.timestamp)
        XCTAssertEqual(location.departureDate, clLocation.timestamp)
        XCTAssertEqual(location.coordinate.latitude, clLocation.coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, clLocation.coordinate.longitude)
        XCTAssertEqual(location.accuracyMeters, 0.0)
    }

    func testMapToJSON() {
        let clVisit = TestVisit()
        let location = RealmLocation(visit: clVisit)
        let jsonEncoder = JSONEncoder.CallistoJSONEncoder()
        guard
            let data = try? jsonEncoder.encode(location),
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any],
            let latitude = json["latitude"] as? Double,
            let longitude = json["longitude"] as? Double
            else {
                XCTFail("Failed to map to JSON")
                return
        }
        XCTAssertEqual(json["arrived_at"] as? String, DateFormatter.pilotStringFromDate(Date.distantPast))
        XCTAssertEqual(latitude, 42.367152)
        XCTAssertEqual(longitude, -71.080197)
        XCTAssertNotNil(json["departed_at"] as? String)
    }

    func testLocationControllerRequestAlwaysAuthorization() {
        let locationController = LocationController(locationManager: mockLocationManager,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .notDetermined })
        var callbackCalled = false
        locationController.requestPermissions(completion: {
            callbackCalled = true
        })

        XCTAssert(callbackCalled, "Should call permissions request completion handler")
        XCTAssert(mockLocationManager.didRequestAlwaysAuthorization)
    }

    func testLocationControllerSignificantLocationChanges() {
        let locationController = LocationController(locationManager: mockLocationManager,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })

        locationController.startMonitoring()
        XCTAssertTrue(mockLocationManager.isMonitoringSignificantLocationChanges)
        XCTAssertFalse(mockLocationManager.isMonitoringVisits)

        locationController.stopMonitoring()
        XCTAssertFalse(mockLocationManager.isMonitoringSignificantLocationChanges)
    }

    func testLocationControllerVisits() {
        let locationController = LocationController(locationManager: mockLocationManager,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .visits,
                                                    authorizationStatusGetter: { .authorizedAlways })

        locationController.startMonitoring()
        XCTAssertTrue(mockLocationManager.isMonitoringVisits)
        XCTAssertFalse(mockLocationManager.isMonitoringSignificantLocationChanges)

        locationController.stopMonitoring()
        XCTAssertFalse(mockLocationManager.isMonitoringVisits)
    }

    func testLocationControllerSaveLocationSuccess() {
        let location = RealmLocation(location: CLLocation(latitude: 0, longitude: 0))

        mockAPIClient.mockCreateLocationResponse = .success(())

        let locationController = LocationController(locationManager: mockLocationManager,
                                                    realm: realm,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })
        do {
            try locationController.saveObject(location)
        } catch(_) {
            XCTFail("Should not throw error")
        }

        // Only result of successful request is location being removed from the realm, if necessary
       XCTAssertNotNil(location)
    }

    func testLocationControllerSaveLocationError() {
        let location = RealmLocation(location: CLLocation(latitude: 0, longitude: 0))

        mockAPIClient.mockCreateLocationResponse = .failure(MockPilotAPIClientError.errorFromServer)

        let locationController = LocationController(locationManager: mockLocationManager,
                                                    realm: realm,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })
        do {
            try locationController.saveObject(location)
        } catch(_) {
            XCTFail("Should not throw error")
        }

        // Server error should result in location being saved to the realm
        XCTAssertNotNil(location)
    }

    func testLocationControllerSyncLocalLocations() {
        let locationController = LocationController(locationManager: mockLocationManager,
                                                    realm: realm,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })

        // Seed realm with some locations to be synced
        var locations = [RealmLocation]()
        let locationCount = 10
        for _ in 0..<locationCount {
            let location = RealmLocation(location: CLLocation(latitude: 0, longitude: 0))
            locations.append(location)
        }
        try! realm.write {
            realm.add(locations)
        }

        // Test failed sync (locations should still exist in realm)
        mockAPIClient.mockCreateLocationResponse = .failure(MockPilotAPIClientError.errorFromServer)

        do {
            try locationController.syncLocalObjects()
        } catch(_) {
            XCTFail("Should not throw error")
        }

        let realmLocations = realm.objects(RealmLocation.self).toArray()
        XCTAssertEqual(realmLocations.count, locationCount)

        // Test successful sync (realm should be cleared out)
        mockAPIClient.mockCreateLocationResponse = .success(())

        do {
            try locationController.syncLocalObjects()
        } catch(_) {
            XCTFail("Should not throw error")
        }

        XCTAssert(realm.isEmpty)
    }

    func testLocationControllerSaveLocationWithoutPermissions() {
        let location = RealmLocation(location: CLLocation(latitude: 0, longitude: 0))

        mockLoginUserProvider.mockIsLoggedInAsPrimaryUser = false

        let locationController = LocationController(locationManager: mockLocationManager,
                                                    realm: realm,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })

        var caughtError: Bool = false
        do {
            try locationController.saveObject(location)
        } catch RealmSyncControllerError.dataPermissionsRequired {
            caughtError = true
        } catch (_) {
        }

        XCTAssert(caughtError, "Should throw permissions error when saving an object without primary user login")
    }

    func testLocationControllerSyncLocalLocationsWithoutPermissions() {
        mockLoginUserProvider.mockIsLoggedInAsPrimaryUser = false

        let locationController = LocationController(locationManager: mockLocationManager,
                                                    realm: realm,
                                                    apiClient: mockAPIClient,
                                                    loginUserProvider: mockLoginUserProvider,
                                                    monitorMode: .frequent,
                                                    authorizationStatusGetter: { .authorizedAlways })

        var caughtError: Bool = false
        do {
            try locationController.syncLocalObjects()
        } catch RealmSyncControllerError.dataPermissionsRequired {
            caughtError = true
        } catch (_) {
        }

        XCTAssert(caughtError, "Should throw permissions error when syncing without primary user login")
    }

    func testObscuredLocation() {
        let mockLocationOffsetStorage = MockLocationOffsetStorage()

        XCTAssertNil(mockLocationOffsetStorage.offset)

        let coordinate = CLLocationCoordinate2D(latitude: 42.367152, longitude: -71.080197)
        let clLocation = CLLocation(coordinate: coordinate, altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, timestamp: Date())
        var location = RealmLocation(location: clLocation, offsetProvider: mockLocationOffsetStorage)

        XCTAssertNotNil(mockLocationOffsetStorage.offset, "New random offset should be generated")

        // Test with a known offset
        mockLocationOffsetStorage.offset = CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5)
        location = RealmLocation(location: clLocation, offsetProvider: mockLocationOffsetStorage)

        XCTAssertEqual(location.latitude, 234.5300639681, accuracy: 0.001)
        XCTAssertEqual(location.longitude, 440.4719801784, accuracy: 0.001)
    }
}
