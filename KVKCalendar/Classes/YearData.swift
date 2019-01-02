//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

private let boxCount = 42

struct YearData {
    var months = [Month]()
    var moveDate: Date
    
    init(date: Date, years: Int) {
        self.moveDate = date
        // определяем количество лет для календаря
        let indexsYear = [Int](repeating: 0, count: years).split(half: years / 2)
        let lastYear = indexsYear.left
        let nextYear = indexsYear.right
        
        var yearsCount = [Int]()
        
        // заполняем прошлыми годами
        for lastIdx in lastYear.indices.reversed() {
            yearsCount.append(-(lastIdx + 1))
        }
        
        // заполняем текущим и следующими годами
        for nextIdx in nextYear.indices {
            yearsCount.append(nextIdx)
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        let nameMonths = (formatter.standaloneMonthSymbols ?? [""]).map({ $0.capitalized })
        
        let calendar = Calendar(identifier: .gregorian)
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
                        days.append(Day(day: "", shortName: "", type: .empty, date: nil, data: []))
                    }
                }
                months[idx].days = days
            }
            monthsTemp += months
        }
        self.months = monthsTemp
    }
    
    func getDaysInMonth(month: Int, date: Date) -> [Day] {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year], from: date)
        let formatter = DateFormatter()
        var dateComponents = DateComponents(year: components.year ?? 0, month: month)
        dateComponents.day = 2
        let dateMonth = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: dateMonth)!
        let numDays = range.count
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        
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
                       shortName: formatterDay.string(from: date).uppercased(),
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
