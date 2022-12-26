//
//  Date+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

public extension Date {
    
    private init(year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        self.init()
        let isoDate = "\(year)-\(month)-\(day)T\(hour):\(minute):00+0000"
        let dateFormatter = ISO8601DateFormatter()
        self = dateFormatter.date(from: isoDate) ?? self
    }
    
    func titleForLocale(_ locale: Locale, formatter: DateFormatter) -> String {
        formatter.locale = locale
        return formatter.string(from: self)
    }
    
    var isSunday: Bool {
        kvkWeekday == 1
    }
    
    var isSaturday: Bool {
        kvkWeekday == 7
    }
    
    var isWeekend: Bool {
        isSunday || isSaturday
    }
    
    var isWeekday: Bool {
        !isWeekend
    }
    
    var kvkMinute: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.minute], from: self)
        return component.minute ?? 0
    }
    
    var kvkHour: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.hour], from: self)
        return component.hour ?? 0
    }
    
    var kvkDay: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.day], from: self)
        return component.day ?? 0
    }
    
    var kvkWeekday: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.weekday], from: self)
        return component.weekday ?? 0
    }
    
    var kvkMonth: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.month], from: self)
        return component.month ?? 0
    }
    
    var kvkYear: Int {
        let calendar = Calendar.current
        let component = calendar.dateComponents([.year], from: self)
        return component.year ?? 0
    }
    
    var kvkStartOfDay: Date {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.startOfDay(for: self)
    }
    
    var kvkEndOfDay: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: kvkStartOfDay)
    }
    
    var kvkStartMondayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.firstWeekday = 2
        gregorian.timeZone = TimeZone.current
        var startDate = Date()
        var interval = TimeInterval()
        _ = gregorian.dateInterval(of: .weekOfMonth, start: &startDate, interval: &interval, for: self)
        return startDate
    }
    
    var kvkStartSundayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        return sunday
    }
    
    var kvkEndSundayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(byAdding: .day, value: 6, to: kvkStartMondayOfWeek ?? self)
    }
    
    var kvkEndSaturdayOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(byAdding: .day, value: 6, to: kvkStartSundayOfWeek ?? self)
    }
    
    var kvkStartOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        return gregorian.date(from: gregorian.dateComponents([.year, .month], from: self))
    }
    
    var kvkEndOfMonth: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone.current
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return gregorian.date(byAdding: components, to: kvkStartOfMonth ?? self)
    }
    
    func kvkToGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func kvkToLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
    
    func kvkConvertTimeZone(_ initTimeZone: TimeZone, to timeZone: TimeZone) -> Date {
        let value = TimeInterval(timeZone.secondsFromGMT() - initTimeZone.secondsFromGMT())
        var components = DateComponents()
        components.second = Int(value)
        let date = Calendar.current.date(byAdding: components, to: self)
        return date ?? self
    }
        
    func kvkIsSameDay(otherDate: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: otherDate)
        return diff.day == 0
    }
    
    func kvkAddingTo(_ component: Calendar.Component, value: Int) -> Date? {
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: self) {
            return newDate
        }
        
        return nil
    }
    
    func kvkIsEqual(_ date: Date) -> Bool {
        date.kvkYear == kvkYear && date.kvkMonth == kvkMonth && date.kvkDay == kvkDay
    }
    
    var kvkIsFebruary: Bool {
        kvkMonth == 2
    }
}
