//
//  Date+Extension.swift
//  MealTrackingPilot
//
//  Created by Rikky Chavhan on 02/08/19.
//  Copyright © 2019 Intrepid. All rights reserved.
//

import Foundation

extension Date {
    
    public static var defaultRegion = DateRegion.UTC
    
    private func value(forComponent cmp: Calendar.Component) -> Int {
        if cmp == .calendar || cmp == .timeZone {
            assertionFailure("You can't get the value of the calendar/timezone component")
        }
        let components = calendar.dateComponents([cmp], from: self)
        let value = components.value(for: cmp)
        return value ?? 0
    }
    
    private func dateFormatter(format: String? = nil) -> DateFormatter {
        let formatter =  DateFormatter()
        if let format = format {
            formatter.dateFormat = format
        }
        formatter.timeZone = timeZone
        formatter.calendar = calendar
        formatter.locale = locale
        return formatter
    }
    
    private var calendar: Calendar {
        return Date.defaultRegion.calendar
    }
    
    private var timeZone: TimeZone {
        return Date.defaultRegion.timeZone
    }
    
    private var locale: Locale {
        return Date.defaultRegion.locale
    }
    
    /*
    func startOf(forComponent dateComponent : Calendar.Component) -> Date {
        var startOfComponent = self
        var timeInterval : TimeInterval = 0.0
        calendar.dateInterval(of: dateComponent, start: &startOfComponent, interval: &timeInterval, for: now)
        return startOfComponent
    }
    */
    
    public var weekday: Int {
        return value(forComponent: .weekday)
    }
    
    public var weekdayName: String {
        return self.dateFormatter(format: "EEEE").string(from: self)
    }
    
    public var weekdayShortName: String {
        return self.dateFormatter(format: "EE").string(from: self)
    }
    
    public var isToday: Bool {
        return calendar.isDateInToday(self)
    }
    
    public var startOfDay: Date {
        return calendar.startOfDay(for: self)
    }
    
    public func string(custom format: String) -> String {
        return dateFormatter(format: format).string(from: self)
    }
    
    public func adjustDays(noOfDays: Int) -> Date {
        guard let addedDate = calendar.date(byAdding: .day, value: noOfDays, to: self) else {
            return Date()
        }
        return addedDate
    }
    
    var startWeek: Date {
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) ?? Date()
    }
    
    var endWeek: Date? {
        guard let startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return Date()
        }
        return calendar.date(byAdding: .day, value: 7, to: startDate)
    }
    
}
