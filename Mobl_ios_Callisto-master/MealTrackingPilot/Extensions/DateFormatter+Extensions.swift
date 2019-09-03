//
//  DateFormatter+Extensions.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 4/5/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Foundation

enum PilotDateMappingError: Error {
    case couldNotParseDateString(dateString: String)
}

extension DateFormatter {
    static let pilotMappingDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func pilotDateFromString(_ dateString: String) throws -> Date {
        guard let date = pilotMappingDateFormatter.date(from: dateString) else {
            throw PilotDateMappingError.couldNotParseDateString(dateString: dateString)
        }
        return date
    }

    static func pilotStringFromDate(_ date: Date) -> String {
        return pilotMappingDateFormatter.string(from: date)
    }
}
