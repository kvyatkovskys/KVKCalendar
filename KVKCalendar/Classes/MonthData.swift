//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

struct MonthData {
    var days: [Day]
    var date: Date
    var data: YearData
    
    private let cachedDays: [Day]
    
    init(yearData: YearData, startDay: StartDayType) {
        self.data = yearData
        data.months = yearData.months.reduce([], { (acc, month) -> [Month] in
            var daysTemp = yearData.addStartEmptyDay(days: month.days, startDay: startDay)
            if daysTemp.count < yearData.boxCount {
                Array(1...yearData.boxCount - daysTemp.count).forEach { _ in
                    daysTemp.append(.empty())
                }
            }
            var monthTemp = month
            monthTemp.days = daysTemp
            return acc + [monthTemp]
        })
        self.date = yearData.date
        self.days = data.months.flatMap({ $0.days })
        self.cachedDays = days
    }
    
    private func compareDate(day: Day, date: Date?) -> Bool {
        return day.date?.year == date?.year && day.date?.month == date?.month
    }
    
    mutating func reloadEventsInDays(events: [Event]) {
        let startDate = date.startOfMonth
        let endDate = date.endOfMonth?.startOfDay
        let startIdx = cachedDays.firstIndex(where: { $0.date?.day == startDate?.day && compareDate(day: $0, date: startDate) }) ?? 0
        let endIdx = cachedDays.firstIndex(where: { $0.date?.day == endDate?.day && compareDate(day: $0, date: endDate) }) ?? 0
        let newDays = cachedDays[startIdx...endIdx].reduce([], { (acc, day) -> [Day] in
            var newDay = day
            guard newDay.events.isEmpty else { return acc + [day] }
            let sortedByDay = events.filter({ $0.start.month == day.date?.month && $0.start.year == day.date?.year && $0.start.day == day.date?.day })
            newDay.events = sortedByDay
            return acc + [newDay]
        })
        days[startIdx...endIdx] = ArraySlice(newDays)
    }
}
