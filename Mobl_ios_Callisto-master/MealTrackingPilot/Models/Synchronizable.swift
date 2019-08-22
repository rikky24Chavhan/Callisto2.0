//
//  Synchronizable.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/1/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol Synchronizable: class {
    var identifier: String { get }
    var localIdentifier: String { get set }
    var isDirty: Bool { get set }
    var createdDate: Date { get }
    var updatedDate: Date { get }
    var isInvalidated: Bool { get }
}

func ==(_ lhs: Synchronizable, _ rhs: Synchronizable) -> Bool {
    return lhs.localIdentifier == rhs.localIdentifier
}

extension Synchronizable {
    var isLocalOnly: Bool {
        return identifier.isEmpty
    }
}
