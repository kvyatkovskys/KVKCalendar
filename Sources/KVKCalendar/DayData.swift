//
//  DayData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import Foundation

final class DayData: EventDateProtocol, ScrollableWeekProtocol {
    let days: [Day]
    var date: Date
    var events: [Event] = []
    var recurringEvents: [Event] = []
    var daysBySection: [[Day]] = []
    
    init(data: CalendarData, startDay: StartDayType) {
        self.date = data.date
        var tempDays = data.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > 7 ? tempDays.count - 7 : tempDays.count
        let endWeek = data.addEndEmptyDays(Array(tempDays[startIdx..<tempDays.count]), startDay: startDay)
        tempDays.removeSubrange(startIdx..<tempDays.count)
        self.days = data.addStartEmptyDays(tempDays, startDay: startDay) + endWeek
        
        daysBySection = prepareDays(days, maxDayInWeek: 7)
    }
    
    func filterEvents(_ events: [Event], date: Date) -> [Event] {
        events.filter { (event) -> Bool in
            compareStartDate(date, with: event)
            || compareEndDate(date, with: event)
            || checkMultipleDate(date, with: event)
        }
    }
}

#endif
