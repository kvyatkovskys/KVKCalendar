//
//  Date+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

public extension Date {
    var minute: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.minute], from: self)
        return componet.minute ?? 0
    }
    
    var hour: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.hour], from: self)
        return componet.hour ?? 0
    }
    
    var day: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.day], from: self)
        return componet.day ?? 0
    }
    
    var weekday: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.weekday], from: self)
        return componet.weekday ?? 0
    }
    
    var month: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.month], from: self)
        return componet.month ?? 0
    }
    
    var year: Int {
        let calendar = Calendar.current
        let componet = calendar.dateComponents([.year], from: self)
        return componet.year ?? 0
    }
    
    var startOfDay: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        return gregorian.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: startOfDay ?? self)
    }
    
    var startOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)),
              let selfDate = gregorian.date(from: gregorian.dateComponents([.year, .month, .day], from: self))else { return nil }

        return selfDate == sunday ? gregorian.date(byAdding: .day, value: -6, to: sunday) : gregorian.date(byAdding: .day, value: 1, to: sunday)
    }
    
    var startSundayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        let components = gregorian.dateComponents([.weekday], from: self)
        guard components.weekday != 7 else {
            return self
        }
        return sunday
    }
    
    var endOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)),
              let selfDate = gregorian.date(from: gregorian.dateComponents([.year, .month, .day], from: self)) else { return nil }

        return selfDate == sunday ? sunday : gregorian.date(byAdding: .day, value: 7, to: sunday)
    }
    
    var startOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        return gregorian.date(from: gregorian.dateComponents([.year, .month], from: self))
    }
    
    var endOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(abbreviation: "UTC")!
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: startOfMonth ?? self)
    }
    
    func toGlobalTime() -> Date { 
        let timezone = TimeZone.autoupdatingCurrent
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func toLocalTime() -> Date {
        let timezone = TimeZone.autoupdatingCurrent
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}
