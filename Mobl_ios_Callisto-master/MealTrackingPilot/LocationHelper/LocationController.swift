//
//  LocationController.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/6/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift
import APIClient
import Intrepid

public final class LocationController: NSObject, RealmSyncController, PermissionRequestController {

    // MARK: - Properties

    let realm: Realm

    private let apiClient: PilotAPIClient
    fileprivate let loginUserProvider: LoginUserProviding
    fileprivate let locationOffsetProvider: LocationOffsetProviding?
    private let locationManager: CLLocationManager
    private let getAuthorizationStatus: () -> CLAuthorizationStatus

    enum MonitorMode {
        case visits
        case frequent
    }

    var monitorMode: MonitorMode {
        willSet {
            if monitorMode != newValue {
                stopMonitoring()
            }
        }
    }

    // MARK: - Lifecycle

    init(
        locationManager: CLLocationManager = CLLocationManager(),
        realm: Realm = try! Realm(configuration: Realm.Configuration(deleteRealmIfMigrationNeeded: true)),
        apiClient: PilotAPIClient,
        loginUserProvider: LoginUserProviding,
        locationOffsetProvider: LocationOffsetProviding? = nil,
        monitorMode: MonitorMode = .frequent,
        authorizationStatusGetter: @escaping () -> CLAuthorizationStatus = CLLocationManager.authorizationStatus) {

        self.locationManager = locationManager
        self.realm = realm
        self.apiClient = apiClient
        self.loginUserProvider = loginUserProvider
        self.locationOffsetProvider = locationOffsetProvider
        self.monitorMode = monitorMode
        self.getAuthorizationStatus = authorizationStatusGetter

        super.init()

        locationManager.delegate = self
        locationManager.allowDeferredLocationUpdates(untilTraveled: CLLocationDistanceMax, timeout: CLTimeIntervalMax)
    }

    deinit {
        locationManager.delegate = nil
    }

    // MARK: - Actions

    func startMonitoring() {
        if getAuthorizationStatus() == .notDetermined {
            return
        }

        switch monitorMode {
        case .visits:
            locationManager.startMonitoringVisits()
        case .frequent:
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    func stopMonitoring() {
        switch monitorMode {
        case .visits:
            locationManager.stopMonitoringVisits()
        case .frequent:
            locationManager.stopMonitoringSignificantLocationChanges()
        }
    }

    // MARK: - RealmSyncController

    typealias SyncableObject = RealmLocation

    func createObject(_ object: RealmLocation, completion: ((Result<Void>) -> Void)?) {
        apiClient.createLocation(object, completion: completion)
    }

    func hasDataAccessPermissions() -> Bool {
        return loginUserProvider.isLoggedInAsPrimaryUser()
    }

    // MARK: - PermissionsRequestController

    fileprivate var permissionRequestCompletionBlock: (() -> Void)?

    func requestPermissions(completion: @escaping () -> Void) {
        let status = getAuthorizationStatus()

        guard status == .notDetermined else {
            completion()
            return
        }

        permissionRequestCompletionBlock = completion
        locationManager.requestAlwaysAuthorization()
    }
}

extension LocationController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        defer {
            let block = permissionRequestCompletionBlock
            permissionRequestCompletionBlock = nil
            block?()
        }

        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            stopMonitoring()
            return
        }

        startMonitoring()
    }

    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard loginUserProvider.isLoggedInAsPrimaryUser() else {
            return
        }
        let location = RealmLocation(visit: visit, offsetProvider: locationOffsetProvider)
        try? saveObject(location)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard loginUserProvider.isLoggedInAsPrimaryUser() else {
            return
        }
        locations.forEach {
            let location = RealmLocation(location: $0, offsetProvider: locationOffsetProvider)
            try? saveObject(location)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }

    public func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        if let error = error {
            print(error)
        }
    }
}
