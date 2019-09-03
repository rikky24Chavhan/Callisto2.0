//
//  Region.swift
//  MealTrackingPilot
//
//  Created by Rikky Chavhan on 02/08/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation

public struct DateRegion: CustomStringConvertible {
    
    public private(set) var timeZone: TimeZone
    public private(set) var calendar: Calendar
    public private(set) var locale: Locale
    
    public var description: String {
        return "Region with timezone: \(self.timeZone), calendar: \(self.calendar), locale: \(self.locale)"
    }
    
    public static var UTC: DateRegion {
        return DateRegion(tz: TimeZone(identifier: "GMT")!, cal: Calendar.autoupdatingCurrent, loc: Locale.autoupdatingCurrent)
    }
    
    public init(tz: TimeZone, cal: Calendar, loc: Locale) {
        self.timeZone = tz
        self.calendar = cal
        self.calendar.timeZone = tz
        self.locale = loc
    }
    
}



