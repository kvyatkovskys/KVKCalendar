//
//  WeekData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

struct WeekData {
    let days: [Day]
    var date: Date
    var timeSystem: TimeHourSystem
    var events: [Event] = []
    
    init(yearData: YearData, timeSystem: TimeHourSystem, startDay: StartDayType) {
        self.date = yearData.date
        var tempDays = yearData.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > 7 ? tempDays.count - 7 : tempDays.count
        let endWeek = yearData.addEndEmptyDay(days: Array(tempDays[startIdx..<tempDays.count]), startDay: startDay)
        tempDays.removeSubrange(startIdx..<tempDays.count)
        self.days = yearData.addStartEmptyDay(days: tempDays, startDay: startDay) + endWeek
        self.timeSystem = timeSystem
    }
}
