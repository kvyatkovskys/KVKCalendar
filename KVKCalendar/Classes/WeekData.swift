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
        let days = yearData.months.reduce([], { $0 + $1.days }).filter({ $0.type != .empty })
        var tempDays = [Day]()
        if let firstDay = days.first?.type {
            for _ in 0..<firstDay.shiftDay {
                tempDays.append(.empty())
            }
            tempDays += days
        } else {
            tempDays = days
        }
        
        if startDay == .sunday {
            tempDays.insert(.empty(), at: 0)
        }
        
        self.days = tempDays
        self.timeSystem = timeSystem
    }
}
