//
//  Date+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

public extension Date {
    func titleForLocale(_ locale: Locale, formatter: DateFormatter) -> String {
        formatter.locale = locale
        return formatter.string(from: self)
    }
    
    var isSunday: Bool {
        weekday == 1
    }
    
    var isSaturday: Bool {
        weekday == 7
    }
    
    var isWeekend: Bool {
        isSunday || isSaturday
    }
    
    var isWeekday: Bool {
        !isWeekend
    }
    
    var minute: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.minute], from: self)
        return component.minute ?? 0
    }
    
    var hour: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.hour], from: self)
        return component.hour ?? 0
    }
    
    var day: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.day], from: self)
        return component.day ?? 0
    }
    
    var weekday: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.weekday], from: self)
        return component.weekday ?? 0
    }
    
    var month: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.month], from: self)
        return component.month ?? 0
    }
    
    var year: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.year], from: self)
        return component.year ?? 0
    }
    
    var startOfDay: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: startOfDay ?? self)
    }
    
    var startMondayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.firstWeekday = 2
        gregorian.timeZone = TimeZone.current
        var startDate = Date()
        var interval = TimeInterval()
        _ = gregorian.dateInterval(of: .weekOfMonth, start: &startDate, interval: &interval, for: self)
        return startDate
    }
    
    var startSundayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        return sunday
    }
    
    var endSundayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(byAdding: .day, value: 6, to: startMondayOfWeek ?? self)
    }
    
    var endSaturdayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(byAdding: .day, value: 6, to: startSundayOfWeek ?? self)
    }
    
    var startOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(from: gregorian.dateComponents([.year, .month], from: self))
    }
    
    var endOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: startOfMonth ?? self)
    }
    
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func convertTimeZone(_ initTimeZone: TimeZone, to timeZone: TimeZone) -> Date {
        let value = TimeInterval(timeZone.secondsFromGMT() - initTimeZone.secondsFromGMT())
        var components = DateComponents()
        components.second = Int(value)
        let date = Calendar.current.date(byAdding: components, to: self)
        return date ?? self
    }
        
    func isSameDay(otherDate: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: otherDate)
        return diff.day == 0
    }
    
    func addingTo(_ component: Calendar.Component, value: Int) -> Date? {
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: self) {
            return newDate
        }
        
        return nil
    }
    
    func isEqual(_ date: Date) -> Bool {
        date.year == year && date.month == month && date.day == day
    }
}
