//
//  WeekData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import Foundation

final class WeekData: EventDateProtocol, ScrollableWeekProtocol {
    var days: [Day] = []
    var date: Date
    var events: [Event] = []
    var recurringEvents: [Event] = []
    var daysBySection: [[Day]] = []
    
    init(data: CalendarData, startDay: StartDayType, maxDays: Int) {
        self.date = data.date
        self.days = getDates(data: data, startDay: startDay, maxDays: maxDays)
        
        daysBySection = prepareDays(days, maxDayInWeek: maxDays)
    }
    
    func filterEvents(_ events: [Event], dates: [Date]) -> [Event] {
        events.filter { (event) -> Bool in
            dates.contains(where: {
                compareStartDate($0, with: event)
                || compareEndDate($0, with: event)
                || checkMultipleDate($0, with: event)
            })
        }
    }
    
    func updateDaysBySection(data: CalendarData, startDay: StartDayType, maxDays: Int) {
        self.date = data.date
        days = getDates(data: data, startDay: startDay, maxDays: maxDays)
        daysBySection = prepareDays(days, maxDayInWeek: maxDays)
    }
    
    private func getDates(data: CalendarData, startDay: StartDayType, maxDays: Int) -> [Day] {
        var item = startDay
        if maxDays != 7 {
            item = .sunday
        }
        
        var tempDays = data.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > maxDays ? tempDays.count - maxDays : tempDays.count
        let endWeek = data.addEndEmptyDays(Array(tempDays[startIdx..<tempDays.count]), startDay: item)
        
        tempDays.removeSubrange(startIdx..<tempDays.count)
        let defaultDays = data.addStartEmptyDays(tempDays, startDay: item) + endWeek
        
        var extensionDays:[Day] = []
        
        if maxDays != 7,
            let indexOfInputDate = defaultDays.firstIndex(where: { $0.date?.isSameDay(otherDate: data.date) ?? false }),
            let firstDate = defaultDays.first?.date
        {
            let extraBufferDays = (defaultDays.count - indexOfInputDate) % maxDays
            if extraBufferDays > 0 {
                var i = extraBufferDays
                while (i > 0) {
                    if let newDate = firstDate.addingTo(.day, value: -1 * i) {
                        extensionDays.append(Day(type: .empty, date: newDate, data: []))
                    }
                    i -= 1
                }
            }
        }
        
        if extensionDays.isEmpty {
            return defaultDays
        } else {
            return extensionDays + defaultDays
        }
    }
}

#endif
