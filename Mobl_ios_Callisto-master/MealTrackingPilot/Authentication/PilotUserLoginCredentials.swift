//
//  PilotUserLoginCredentials.swift
//  MealTrackingPilot
//
//  Created by Steve Galbraith on 8/1/18.
//  Copyright © 2018 Intrepid. All rights reserved.
//

import Foundation
import UIKit

protocol LoginCredentials {
    func httpBodyParameters() -> [String: Any]
}

protocol UserLoginCredentials: LoginCredentials {
    var userName: String? { get set }
    var password: String? { get set }
}

struct PilotUserLoginCredentials: UserLoginCredentials, Codable {
    var userName: String?
    var password: String?
    var idForVendor: String {
        #if targetEnvironment(simulator)
            // Plug in a default idForVendor if running in the simulator so it does not change
        return "D9F0A23B-E5B0-4509-9F31-B37F2FB131C1"
        #else
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
        #endif
    }
    
    init(userName: String?, password: String? = nil) {
        self.userName = userName
        self.password = password
    }

    // MARK: - UserLoginCredentials

    func httpBodyParameters() -> [String : Any] {
        return [
            "username": userName ?? "",
            "password": password ?? "",
            "device_id": idForVendor
        ]
    }
}
