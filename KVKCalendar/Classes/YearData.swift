//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

private let boxCount = 42

struct YearData {
    fileprivate let style: Style
    var months = [Month]()
    var moveDate: Date
    
    init(date: Date, years: Int, style: Style) {
        self.style = style
        self.moveDate = date
        // count years for calendar
        let indexsYear = [Int](repeating: 0, count: years).split(half: years / 2)
        let lastYear = indexsYear.left
        let nextYear = indexsYear.right
        
        var yearsCount = [Int]()
        
        // last years
        for lastIdx in lastYear.indices.reversed() {
            yearsCount.append(-(lastIdx + 1))
        }
        
        // next years
        for nextIdx in nextYear.indices {
            yearsCount.append(nextIdx)
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
                                                                 days: [Day.empty()]) })
            
            for (idx, month) in months.enumerated() {
                var days = getDaysInMonth(month: idx + 1, date: month.date)
                if days.count < boxCount {
                    for _ in 1...boxCount - days.count {
                        days.append(Day(day: "", type: .empty, date: nil, data: []))
                    }
                }
                months[idx].days = days
            }
            monthsTemp += months
        }
        self.months = monthsTemp
    }
    
    func getDaysInMonth(month: Int, date: Date) -> [Day] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        let formatter = DateFormatter()
        var dateComponents = DateComponents(year: components.year ?? 0, month: month)
        dateComponents.day = 2
        let dateMonth = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: dateMonth)!
        let numDays = range.count
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = self.style.timezone
        
        var arrDates = [Date]()
        for day in 1...numDays {
            let dateString = "\(components.year ?? 0) \(month) \(day)"
            if let date = formatter.date(from: dateString) {
                arrDates.append(date)
            }
        }
        
        formatter.dateFormat = "d"
        let formatterDay = DateFormatter()
        formatterDay.dateFormat = "EE"
        
        let days = arrDates.map({ (date) -> Day in
            return Day(day: formatter.string(from: date),
                       type: DayType(rawValue: formatterDay.string(from: date).uppercased()),
                       date: date,
                       data: [])
        })
        
        guard let shift = days.first?.type else { return days }
        var shiftDays = [Day]()
        for _ in 0..<shift.shiftDay {
            shiftDays.append(Day.empty())
        }
        return shiftDays + days
    }
    
    func addStartEmptyDay(days: [Day]) -> [Day] {
        var tempDays = [Day]()
        let filterDays = days.filter({ $0.type != .empty })
        if let firstDay = filterDays.first?.type {
            for _ in 0..<firstDay.shiftDay {
                tempDays.append(Day.empty())
            }
            tempDays += filterDays
        } else {
            tempDays = filterDays
        }
        return tempDays
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
