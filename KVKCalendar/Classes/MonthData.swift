//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

final class MonthData: CompareEventDateProtocol {
    var days: [Day]
    var date: Date
    var data: YearData
    
    private let cachedDays: [Day]
    
    init(yearData: YearData, startDay: StartDayType) {
        self.data = yearData
        let months = yearData.months.reduce([], { (acc, month) -> [Month] in
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
        data.months = months
        self.date = yearData.date
        self.days = months.flatMap({ $0.days })
        self.cachedDays = days
    }
    
    private func compareDate(day: Day, date: Date?) -> Bool {
        return day.date?.year == date?.year && day.date?.month == date?.month
    }
    
    func reloadEventsInDays(events: [Event]) {
        let startDate = date.startOfMonth
        let endDate = date.endOfMonth?.startOfDay
        let startIdx = cachedDays.firstIndex(where: { $0.date?.day == startDate?.day && compareDate(day: $0, date: startDate) }) ?? 0
        let endIdx = cachedDays.firstIndex(where: { $0.date?.day == endDate?.day && compareDate(day: $0, date: endDate) }) ?? 0
        let newDays = cachedDays[startIdx...endIdx].reduce([], { (acc, day) -> [Day] in
            var newDay = day
            guard newDay.events.isEmpty else { return acc + [day] }
            
            let filteredEventsByDay = events.filter({ $0.start.month == day.date?.month && $0.start.year == day.date?.year && $0.start.day == day.date?.day })
            let filteredAllDayEvents = events.filter({ $0.isAllDay })
            let allDayEvents = filteredAllDayEvents.filter({ compareStartDate(event: $0, date: day.date) || compareEndDate(event: $0, date: day.date) })
            let otherEvents = filteredEventsByDay.filter({ !$0.isAllDay }).sorted(by: { $0.start.hour < $1.start.hour })
            newDay.events = allDayEvents + otherEvents
            return acc + [newDay]
        })
        days[startIdx...endIdx] = ArraySlice(newDays)
    }
}
