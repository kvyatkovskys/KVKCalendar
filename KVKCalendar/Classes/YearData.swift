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
    var yearsCount = [Int]()
    
    init(date: Date, years: Int, style: Style) {
        self.style = style
        self.date = date
        
        // count years for calendar
        let indexsYear = [Int](repeating: 0, count: years).split(half: years / 2)
        let lastYear = indexsYear.left
        let nextYear = indexsYear.right
                
        // last years
        for lastIdx in lastYear.indices.reversed() where years > 1 {
            yearsCount.append(-lastIdx)
        }
        
        // next years
        for nextIdx in nextYear.indices where years > 1 {
            yearsCount.append(nextIdx + 1)
        }
        
        // select current year
        if 0...1 ~= years {
            yearsCount = [0]
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
                dateMonths = Array(monthsOfYearRange.lowerBound..<monthsOfYearRange.upperBound).compactMap({ monthOfYear -> Date? in
                    var components = DateComponents(year: year, month: monthOfYear)
                    components.day = 2
                    return calendar.date(from: components)
                })
            }
            
            var months = zip(nameMonths, dateMonths).map({ Month(name: $0.0, date: $0.1, days: []) })
            
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
        dateComponents.day = 1
        guard let dateMonth = calendar.date(from: dateComponents), let range = calendar.range(of: .day, in: .month, for: dateMonth) else { return [] }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        formatter.timeZone = style.timezone
        let arrDates = Array(range.lowerBound..<range.upperBound).compactMap({ formatter.date(from: "\(date.year)-\(month)-\($0)") })

        let formatterDay = DateFormatter()
        formatterDay.dateFormat = "EE"
        formatterDay.locale = Locale(identifier: "en_US")
        let days = arrDates.map({ Day(type: DayType(rawValue: formatterDay.string(from: $0).uppercased()), date: $0, data: []) })
        return days
    }
    
    func addStartEmptyDay(days: [Day], startDay: StartDayType) -> [Day] {
        var tempDays = [Day]()
        if let firstDay = days.first {
            if firstDay.type == .sunday, startDay == .sunday {
                tempDays = days
            } else {
                tempDays = Array(0..<firstDay.type.shiftDay).compactMap({ (idx) -> Day in
                    var day = Day.empty()
                    day.date = getOffsetDate(offset: -(idx + 1), to: firstDay.date)
                    return day
                }) + days
            }
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
        if let lastDay = days.last {
            let maxShift: DayType = startDay == .sunday ? .saturday : .sunday
            var emptyDays = [Day]()
            if maxShift.shiftDay > lastDay.type.shiftDay {
                emptyDays = Array(0..<maxShift.shiftDay - lastDay.type.shiftDay).compactMap({ (idx) -> Day in
                    var day = Day.empty()
                    day.date = getOffsetDate(offset: (idx + 1), to: lastDay.date)
                    return day
                })
            }
            tempDays = days + emptyDays
        } else {
            tempDays = days
        }
        return tempDays
    }
    
    func getOffsetDate(offset: Int, to date: Date?) -> Date? {
        guard let dateTemp = date else { return nil }
        
        return style.calendar.date(byAdding: .day, value: offset, to: dateTemp)
    }
    
    private func addSundayToBegin(days: [Day]) -> [Day] {
        var days = days
        if let firstDay = days.first, firstDay.type != .sunday {
            var emptyDay = Day.empty()
            emptyDay.date = getOffsetDate(offset: -1, to: firstDay.date)
            days.insert(emptyDay, at: 0)
        }
        return days
    }
}

struct Month {
    let name: String
    let date: Date
    var days: [Day]
}

struct Day {
    let type: DayType
    var date: Date?
    var events: [Event]
    
    static func empty() -> Day {
        return self.init()
    }
    
    private init() {
        self.date = nil
        self.events = []
        self.type = .empty
    }
    
    init(type: DayType, date: Date?, data: [Event]) {
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
    
    var isWeekend: Bool {
        switch self {
        case .saturday, .sunday:
            return true
        default:
            return false
        }
    }
    
    var isWeekday: Bool {
        switch self {
        case .monday, .tuesday, .wednesday, .thursday, .friday:
            return true
        default:
            return false
        }
    }
}

public enum StartDayType: Int {
    case monday, sunday
}
