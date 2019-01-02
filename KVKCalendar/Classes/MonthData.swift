//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

struct MonthData {
    var days: [Day]
    var moveDate: Date
    
    fileprivate let cachedDays: [Day]
    
    init(yearData: YearData) {
        self.days = yearData.months.reduce([], { $0 + $1.days })
        self.moveDate = yearData.moveDate
        self.cachedDays = days
    }
    
    fileprivate func compareDate(day: Day, date: Date?) -> Bool {
        return day.date?.year == date?.year && day.date?.month == date?.month
    }
    
    mutating func reloadEventsInDays(events: [Event]) {
        let startDate = moveDate.startOfMonth
        let endDate = moveDate.endOfMonth?.startOfDay
        let startIdx = cachedDays.index(where: { $0.date?.day == startDate?.day && compareDate(day: $0, date: moveDate) }) ?? 0
        let endIdx = cachedDays.index(where: { $0.date?.day == endDate?.day && compareDate(day: $0, date: moveDate) }) ?? 0
        let newDays = cachedDays[startIdx...endIdx].reduce([], { (acc, day) -> [Day] in
            var newDay = day
            guard newDay.events.isEmpty else { return acc + [day] }
            let sortedByDay = events.filter({ $0.start.month == day.date?.month })
            for (idx, value) in sortedByDay.enumerated() where value.start.day == day.date?.day {
                newDay.events.append(events[idx])
            }
            return acc + [newDay]
        })
        days[startIdx...endIdx] = ArraySlice(newDays)
    }
}

struct Day {
    let day: String
    let shortName: String
    let type: DayType
    let date: Date?
    var events: [Event]
    
    static func empty() -> Day {
        return self.init()
    }
    
    private init() {
        self.day = ""
        self.shortName = ""
        self.date = nil
        self.events = []
        self.type = .empty
    }
    
    init(day: String, shortName: String, type: DayType, date: Date?, data: [Event]) {
        self.day = day
        self.shortName = shortName
        self.type = type
        self.events = data
        self.date = date
    }
}

enum DayType: String, CaseIterable {
    case monday = "ПН"
    case tuesday = "ВТ"
    case wednesday = "СР"
    case thursday = "ЧТ"
    case friday = "ПТ"
    case saturday = "СБ"
    case sunday = "ВС"
    case empty
    
    init(rawValue: String) {
        switch rawValue {
        case "ПН", "MON": self = .monday
        case "ВТ", "TUE": self = .tuesday
        case "СР", "WED": self = .wednesday
        case "ЧТ", "THU": self = .thursday
        case "ПТ", "FRI": self = .friday
        case "СБ", "SAT": self = .saturday
        case "ВС", "SUN": self = .sunday
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
