//
//  UserPermissionsNode.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/29/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

enum ChatPermissionsType: String {
    case healthKit
    case location
}

struct UserPermissionsNode: ChatNode {
    let identifier: String
    let nextIdentifier: String?
    let permissionsType: ChatPermissionsType

    var hasAskedForPermissions: Bool = false

    init(identifier: String, nextIdentifier: String?, permissionsType: ChatPermissionsType) {
        self.identifier = identifier
        self.nextIdentifier = nextIdentifier
        self.permissionsType = permissionsType
    }

    func nextNodeIdentifier() -> String? {
        return nextIdentifier
    }

    var canContinue: Bool {
        return hasAskedForPermissions
    }
}
