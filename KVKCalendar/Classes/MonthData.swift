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
