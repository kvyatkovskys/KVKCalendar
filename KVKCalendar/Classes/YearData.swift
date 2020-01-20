//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

struct YearData {
    private let style: Style
    
    let boxCount = 42
    var months = [Month]()
    var date: Date
    
    init(date: Date, years: Int, style: Style) {
        self.style = style
        self.date = date
        // count years for calendar
        let indexsYear = [Int](repeating: 0, count: years).split(half: years / 2)
        let lastYear = indexsYear.left
        let nextYear = indexsYear.right
        
        var yearsCount = [Int]()
        
        // last years
        for lastIdx in lastYear.indices.reversed() {
            yearsCount.append(-lastIdx)
        }
        
        // next years
        for nextIdx in nextYear.indices {
            yearsCount.append(nextIdx + 1)
        }
        
        let formatter = DateFormatter()
        formatter.locale = style.locale
        let nameMonths = (formatter.standaloneMonthSymbols ?? [""]).map({ $0.capitalized })
        
        let calendar = style.calendar
        var monthsTemp = [Month]()
        
        yearsCount.forEach { (idx) in
            let yearDate = calendar.date(byAdding: .year, value: idx, to: date)
            let monthsOfYearRange = calendar.range(of: .month, in: .year, for: yearDate ?? date)
            
            var dateMonths = [Date]()
            if let monthsOfYearRange = monthsOfYearRange {
                let year = calendar.component(.year, from: yearDate ?? date)
                for monthOfYear in (monthsOfYearRange.lowerBound..<monthsOfYearRange.upperBound) {
                    var components = DateComponents(year: year, month: monthOfYear)
                    components.day = 2
                    guard let dateMonth = calendar.date(from: components) else { continue }
                    dateMonths.append(dateMonth)
                }
            }
            
            var months = zip(nameMonths, dateMonths).map({ Month(name: $0.0,
                                                                 date: $0.1,
                                                                 week: [.empty],
                                                                 days: [.empty()]) })
            
            for (idx, month) in months.enumerated() {
                let days = getDaysInMonth(month: idx + 1, date: month.date)
                months[idx].days = days
            }
            monthsTemp += months
        }
        self.months = monthsTemp
    }
    
    func getDaysInMonth(month: Int, date: Date) -> [Day] {
        let calendar = style.calendar
        var dateComponents = DateComponents(year: date.year, month: month)
        dateComponents.day = 2
        
        guard let dateMonth = calendar.date(from: dateComponents), let range = calendar.range(of: .day, in: .month, for: dateMonth) else { return [] }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let arrDates = Array(1...range.count).compactMap({ day in formatter.date(from: "\(date.year)-\(month)-\(day) 00:00:00") })

        formatter.dateFormat = "d"
        let formatterDay = DateFormatter()
        formatterDay.dateFormat = "EE"
        formatterDay.timeZone = TimeZone(secondsFromGMT: 0)
        formatterDay.calendar = style.calendar
        formatterDay.locale = style.locale
        
        let days = arrDates.map({ Day(day: formatter.string(from: $0),
                                      type: DayType(rawValue: formatterDay.string(from: $0).uppercased()),
                                      date: $0,
                                      data: []) })
        return days
    }
    
    func addStartEmptyDay(days: [Day], startDay: StartDayType) -> [Day] {
        var tempDays = [Day]()
        if let firstDay = days.first?.type {
            tempDays = Array(0..<firstDay.shiftDay).compactMap({ _ in Day.empty() }) + days
        } else {
            tempDays = days
        }
        
        if startDay == .sunday {
            tempDays = addSundayToBegin(days: tempDays)
        }
        
        return tempDays
    }
    
    func addEndEmptyDay(days: [Day], startDay: StartDayType) -> [Day] {
        var tempDays = [Day]()
        if let lastDay = days.last?.type {
            let maxShift: DayType = startDay == .sunday ? .saturday : .sunday
            var emptyDays = [Day]()
            if maxShift.shiftDay > lastDay.shiftDay {
                emptyDays = Array(0..<maxShift.shiftDay - lastDay.shiftDay).compactMap({ _ in Day.empty() })
            }
            tempDays = days + emptyDays
        } else {
            tempDays = days
        }
        return tempDays
    }
    
    private func addSundayToBegin(days: [Day]) -> [Day] {
        var days = days
        if days.first?.type != .sunday {
            days.insert(.empty(), at: 0)
        }
        return days
    }
}

struct Month {
    let name: String
    let date: Date
    let week: [DayType]
    var days: [Day]
}

struct Day {
    let day: String
    let type: DayType
    let date: Date?
    var events: [Event]
    
    static func empty() -> Day {
        return self.init()
    }
    
    private init() {
        self.day = ""
        self.date = nil
        self.events = []
        self.type = .empty
    }
    
    init(day: String, type: DayType, date: Date?, data: [Event]) {
        self.day = day
        self.type = type
        self.events = data
        self.date = date
    }
}

enum DayType: String, CaseIterable {
    case monday = "MON"
    case tuesday = "TUE"
    case wednesday = "WED"
    case thursday = "THU"
    case friday = "FRI"
    case saturday = "SAT"
    case sunday = "SUN"
    case empty
    
    init(rawValue: String) {
        switch rawValue {
        case "MON": self = .monday
        case "TUE": self = .tuesday
        case "WED": self = .wednesday
        case "THU": self = .thursday
        case "FRI": self = .friday
        case "SAT": self = .saturday
        case "SUN": self = .sunday
        default: self = .empty
        }
    }
    
    var shiftDay: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        case .empty: return -1
        }
    }
}

public enum StartDayType: Int {
    case monday, sunday
}
