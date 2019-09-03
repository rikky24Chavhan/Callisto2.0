//
//  UserProviding.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/16/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

protocol User {
    var identifier: String { get }
    var userName: String { get }
}

protocol UserProviding {
    var user: User? { get set }
}

protocol LoginUserProviding: UserProviding {
    func isLoggedInAsPrimaryUser() -> Bool
}
