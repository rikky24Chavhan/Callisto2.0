//
//  PilotAPIErrorReason.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 6/12/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation
import UIKit

enum PilotAPIErrorReason: String {

    case nameAlreadyExists = "creator_id_name_taken"

    var displayMessage: String {
        switch self {
        case .nameAlreadyExists:
            return "A meal with this name already exists"
        }
    }

    static func reasons(for data: Data?) -> [PilotAPIErrorReason] {
        guard
            let data = data,
            let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
            let errorReasonStrings = json["errors"] as? [String]
        else {
            return []
        }
        //return errorReasonStrings.flatMap(  PilotAPIErrorReason(rawValue: $0)  )


        return errorReasonStrings.compactMap { PilotAPIErrorReason(rawValue: $0) }
    }
}
