//
//  RealmSyncController.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 4/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import RealmSwift

import Intrepid

enum RealmSyncControllerError: Error {
    case dataPermissionsRequired
}

protocol RealmSyncController: class {
    associatedtype SyncableObject: RealmSwift.Object, Codable
    var realm: Realm { get }
    // Call the appropriate PilotAPIClient function to POST object
    func createObject(_ object: SyncableObject, completion: voidRequestCompletion?)
    func hasDataAccessPermissions() -> Bool
}

extension RealmSyncController {
    func hasDataAccessPermissions() -> Bool {
        return true
    }
}

extension RealmSyncController {
    func saveObject(_ object: SyncableObject, local: Bool = false) throws {
        guard hasDataAccessPermissions() else {
            print("Cannot sync local objects: \(self) does not have data access permissions at this time.")
            throw RealmSyncControllerError.dataPermissionsRequired
        }

        if local {
            do {
                try realm.write {
                    realm.add(object, update: .all)
                }
            } catch {
                print("Failed to save syncable object to realm: \(error)")
            }
        } else {
            createObject(object) { [weak self] result in
                switch result {
                case .failure(let error):
                    // Object could not be synced, save locally and attempt later
                    switch error {
                    case APIClientError.httpError(let statusCode, _, _):
                        if statusCode == 422 {
                            // Something was wrong with the data, don't attempt to send again
                            return
                        }
                    default:
                        break
                    }

                    try? self?.saveObject(object, local: true)
                case .success:
                    // Object successfully added, no longer needed in Realm
                    if let realm = object.realm {
                        do {
                            try realm.write {
                                realm.delete(object)
                            }
                        } catch {
                            print("Failed to delete syncable object from realm: \(error)")
                        }
                    }
                }
            }
        }
    }

    func syncLocalObjects() throws {
        guard hasDataAccessPermissions() else {
            print("Cannot sync local objects: \(self) does not have data access permissions at this time.")
            throw RealmSyncControllerError.dataPermissionsRequired
        }

        let objects = realm.objects(SyncableObject.self).toArray()
        for object in objects {
            try saveObject(object)
        }
    }
}
