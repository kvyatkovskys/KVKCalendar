//
//  DayData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import Foundation

struct DayData {
    let days: [Day]
    var date: Date
    var timeSystem: TimeHourSystem
    var events: [Event] = []
    
    init(yearData: YearData, timeSystem: TimeHourSystem) {
        self.date = yearData.moveDate
        let days = yearData.months.reduce([], { $0 + $1.days }).filter({ $0.type != .empty })
        var tempDays = [Day]()
        if let firstDay = days.first?.type {
            for _ in 0..<firstDay.shiftDay {
                tempDays.append(Day.empty())
            }
            tempDays += days
        } else {
            tempDays = days
        }
        self.days = tempDays
        self.timeSystem = timeSystem
    }
}
