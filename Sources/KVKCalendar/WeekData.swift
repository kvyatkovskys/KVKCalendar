//
//  WeekData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import Foundation

final class WeekData: EventDateProtocol {
    let days: [Day]
    var date: Date
    var events: [Event] = []
    var recurringEvents: [Event] = []
    var daysBySection: [[Day]] = []
    
    init(data: CalendarData, startDay: StartDayType, maxDays: Int) {
        self.date = data.date
        var item = startDay
        if maxDays != 7 {
            item = .sunday
        }
        var tempDays = data.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > maxDays ? tempDays.count - maxDays : tempDays.count
        let endWeek = data.addEndEmptyDays(Array(tempDays[startIdx..<tempDays.count]), startDay: item)
        tempDays.removeSubrange(startIdx..<tempDays.count)
        self.days = data.addStartEmptyDays(tempDays, startDay: item) + endWeek
        
        var idx = 0
        var stop = false
        while !stop {
            var endIdx = idx + maxDays
            if endIdx > days.count {
                endIdx = days.count
            }
            let items = Array(days[idx..<endIdx])
            self.daysBySection.append(items)
            idx += maxDays
            if idx > days.count - 1 {
                stop = true
            }
        }
    }
    
    func filterEvents(_ events: [Event], dates: [Date?]) -> [Event] {
        events.filter { (event) -> Bool in
            dates.contains(where: {
                compareStartDate($0, with: event)
                || compareEndDate($0, with: event)
            })
        }
    }
}

#endif
