//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import Foundation

struct CalendarData {
    let style: Style
    let maxBoxCount = 42
    let minBoxCount = 35
    var date: Date
    var months = [Month]()
    var yearsCount = [Int]()
    
    init(date: Date, years: Int, style: Style) {
        self.date = date
        self.style = style
        
        // count years for calendar
        let indexesYear = [Int](repeating: 0, count: years).split(half: years / 2)
        let lastYear = indexesYear.left
        let nextYear = indexesYear.right
                
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
                    components.day = 1
                    return calendar.date(from: components)
                })
            }
            
            var months = zip(nameMonths, dateMonths).map { Month(name: $0.0, date: $0.1, weeks: numberOfWeeksInMonth($0.1, calendar: calendar)) }
            
            for (idx, month) in months.enumerated() {
                let days = getDaysInMonth(month: idx + 1, date: month.date)
                months[idx].days = days
            }
            monthsTemp += months
        }
        self.months = monthsTemp
    }
    
    func prepareYears(_ months: [Month]) -> [YearSection] {
        months.reduce([], { (acc, month) -> [YearSection] in
            var accTemp = acc
            guard let idx = accTemp.firstIndex(where: { $0.date.kvkYear == month.date.kvkYear }) else {
                return accTemp + [YearSection(date: month.date, months: [month])]
            }
            
            accTemp[idx].months.append(month)
            return accTemp
        })
    }
    
    func prepareMonths() -> [Month] {
        months.reduce([], { (acc, month) -> [Month] in
            var daysTemp = addStartEmptyDays(month.days, startDay: style.startWeekDay)
            
            let boxCount: Int
            switch month.weeks {
            case 5 where style.month.scrollDirection == .vertical:
                boxCount = minBoxCount
            default:
                boxCount = maxBoxCount
            }
            
            if let lastDay = daysTemp.last, daysTemp.count < boxCount {
                let emptyEndDays = Array(1...(boxCount - daysTemp.count)).compactMap { (idx) -> Day in
                    var day = Day.empty(uniqID: (lastDay.date?.kvkUniqID ?? 0) + idx)
                    day.date = getOffsetDate(offset: idx, to: lastDay.date)
                    return day
                }
                
                daysTemp += emptyEndDays
            }
            var monthTemp = month
            monthTemp.days = daysTemp
            return acc + [monthTemp]
        })
    }
    
    func getDaysInMonth(month: Int, date: Date) -> [Day] {
        let calendar = style.calendar
        var dateComponents = DateComponents(year: date.kvkYear, month: month)
        dateComponents.day = 1
        guard let dateMonth = calendar.date(from: dateComponents), let range = calendar.range(of: .day, in: .month, for: dateMonth) else { return [] }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        formatter.timeZone = style.timezone
        let arrDates = Array(range.lowerBound..<range.upperBound).compactMap({ formatter.date(from: "\(date.kvkYear)-\(month)-\($0)") })

        let formatterDay = DateFormatter()
        formatterDay.dateFormat = "EE"
        formatterDay.locale = Locale(identifier: "en_US")
        let days = arrDates.compactMap {
            Day(type: DayType(rawValue: formatterDay.string(from: $0).uppercased()) ?? .empty,
                date: $0,
                data: [])
        }
        return days
    }
    
    func addStartEmptyDays(_ days: [Day], startDay: StartDayType, maxDaysInWeek: Int? = nil) -> [Day] {
        var tempDays = [Day]()
        if let firstDay = days.first {
            var endIdx = (firstDay.date?.kvkWeekday ?? 1)
            
            switch startDay {
            case .monday:
                if firstDay.date?.isSunday == true {
                    endIdx = 7 - endIdx
                } else {
                    endIdx -= 2
                }
            case .sunday:
                endIdx -= 1
            }
            
            tempDays = Array(0..<endIdx).reversed().compactMap({ (idx) -> Day in
                var day = Day.empty(uniqID: (firstDay.date?.kvkUniqID ?? 0) + idx)
                day.date = getOffsetDate(offset: -(idx + 1), to: firstDay.date)
                return day
            }) + days
        } else {
            tempDays = days
        }
        
        return tempDays
    }
    
    func addEndEmptyDays(_ days: [Day], startDay: StartDayType, maxDaysInWeek: Int? = nil) -> [Day] {
        var tempDays = [Day]()
        if let lastDay = days.last {
            var emptyDays = [Day]()
            
            let maxIdx: Int
            switch startDay {
            case .sunday:
                maxIdx = 6
            case .monday:
                maxIdx = 7
            }
            let lastIdx = (lastDay.date?.kvkWeekday ?? 1) - 1
            
            if maxIdx > lastIdx {
                emptyDays = Array(0..<maxIdx - lastIdx).compactMap({ (idx) -> Day in
                    var day = Day.empty(uniqID: (lastDay.date?.kvkUniqID ?? 0) + idx)
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
    
    func numberOfWeeksInMonth(_ date: Date?, calendar: Calendar) -> Int {
        guard let dt = date else { return 6 }
        
        var item = calendar
        item.firstWeekday = 1
        let weekRange = item.range(of: .weekOfMonth, in: .month, for: dt)
        return weekRange?.count ?? 6
    }
    
    func getOffsetDate(offset: Int, to date: Date?) -> Date? {
        guard let dateTemp = date else { return nil }
        return style.calendar.date(byAdding: .day, value: offset, to: dateTemp)
    }
    
//    private func addEmptyDayToEnd(days: [Day]) -> [Day] {
//        var days = days
//        if let lastDay = days.last {
//            var emptyDay = Day.empty()
//            emptyDay.date = getOffsetDate(offset: 1, to: lastDay.date)
//            days.append(emptyDay)
//        }
//        return days
//    }
}

struct Month: Identifiable {
    let name: String
    let date: Date
    var days: [Day] = []
    var weeks: Int
    
    var id: Int {
        date.hashValue
    }
    
    var yearName: String {
        Platform.currentInterface == .phone ? String(name.prefix(3)) : name
    }
}

struct YearSection: Identifiable {
    let date: Date
    var months: [Month]
    
    var id: Int {
        date.hashValue
    }
}

struct Day: Identifiable, Equatable, Hashable {
    
    let type: DayType
    var date: Date?
    var events: [Event]
    let uniqID: Int?
    
    static func empty(uniqID: Int? = nil) -> Day {
        self.init(uniqID: uniqID)
    }
    
    private init(uniqID: Int?) {
        date = nil
        events = []
        type = .empty
        self.uniqID = -(uniqID ?? 1)
    }
    
    init(type: DayType, date: Date?, data: [Event]) {
        self.type = type
        self.events = data
        self.date = date
        self.uniqID = date?.kvkUniqID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
    
    var id: Int {
        var dateId: Int
        if let uniqID {
            dateId = uniqID
        } else {
            dateId = date?.kvkUniqID ?? 0
        }
        return dateId + type.id
    }
    
    static func == (lhs: Day, rhs: Day) -> Bool {
        lhs.date == rhs.date
    }
}

public enum DayType: String, CaseIterable, Identifiable {
    case monday = "MON"
    case tuesday = "TUE"
    case wednesday = "WED"
    case thursday = "THU"
    case friday = "FRI"
    case saturday = "SAT"
    case sunday = "SUN"
    case empty
    
    public var id: Int {
        switch self {
        case .monday:
            1
        case .tuesday:
            2
        case .wednesday:
            3
        case .thursday:
            4
        case .friday:
            5
        case .saturday:
            6
        case .sunday:
            7
        case .empty:
            8
        }
    }
}

public enum StartDayType: Int {
    case monday, sunday
}

protocol WeekPreparing {}

extension WeekPreparing {
    
    func getWeekDays(style: Style) -> [Date] {
        let startWeekDate = style.startWeekDay == .sunday ? Date().kvkStartSundayOfWeek : Date().kvkStartMondayOfWeek
        return Array(0..<7).compactMap { date -> Date? in
            guard let dateTemp = startWeekDate else { return nil }
            
            return style.calendar.date(byAdding: .day,
                                       value: date,
                                       to: dateTemp)
        }
    }
    
}

#endif
