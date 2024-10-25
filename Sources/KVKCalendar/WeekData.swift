//
//  WeekData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
@Observable final class WeekNewData: EventDateProtocol, WeekDataProtocol {
    var days: [Day] = []
    let style: Style
    var date: Date
    var timelineDays: [Date?] = []
    var allDayEvents: [Event] = []
    var event: Event?
    var events: [Event]
    var recurringEvents: [Event] = []
    var weeks: [WeekItem] = []
    var type: CalendarType
    
    private let data: KVKCalendar.CalendarData
        
    init(data: KVKCalendar.CalendarData,
         events: [Event] = [],
         type: KVKCalendar.CalendarType,
         event: Event? = nil) {
        self.data = data
        date = data.date
        self.events = events
        style = data.style
        self.event = event
        self.type = type
        let item = reloadData(data,
                              type: type,
                              startDay: data.style.startWeekDay,
                              maxDays: data.style.week.maxDays)
        days = item.days
        weeks = item.weeks
    }
    
    func setup() async {
        timelineDays = await getDaysByDate(date, for: type).map { $0.date }
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
}

final class WeekData: EventDateProtocol, ScrollableWeekProtocol {
    
    // temporary here
    var isAutoScrolling: Bool = false
    var scrollId: Int?
    var type: CalendarType
    var days: [Day] = []
    var style: Style
    var date: Date
    var timelineDays: [Date?] = []
    var allDayEvents: [Event] = []
    var events: [Event]
    var recurringEvents: [Event] = []
    var weeks: [WeekItem] = []
    
    @available(swift, deprecated: 0.6.13, renamed: "weeks")
    var daysBySection: [[Day]] = []
        
    init(data: CalendarData,
         type: CalendarType = .week,
         events: [Event] = []) {
        date = data.date
        self.type = type
        self.events = events
        style = data.style
        reloadData(data,
                   startDay: data.style.startWeekDay,
                   maxDays: type == .week ? data.style.week.maxDays : 1)
        timelineDays = getDaysByDate(date).map { $0.date }
    }
    
    private func getIdxByDate(_ date: Date) -> Int? {
        weeks.firstIndex(where: { week in
            week.days.firstIndex(where: { $0.date?.kvkIsEqual(date) ?? false }) != nil
        })
    }
    
    private func getDaysByDate(_ date: Date) -> [Day] {
        guard let idx = getIdxByDate(date) else { return [] }
        return weeks[idx].days
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
    
    func reloadData(_ data: CalendarData, startDay: StartDayType, maxDays: Int) {
        var startDayProxy = startDay
        if type == .week && maxDays != 7 {
            startDayProxy = .sunday
        }
        
        days = getDates(data: data, startDay: startDayProxy, maxDays: maxDays)
        weeks = prepareDays(days, maxDayInWeek: maxDays)
    }
    
    private func getDates(data: CalendarData, startDay: StartDayType, maxDays: Int) -> [Day] {
        var tempDays = data.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > maxDays ? tempDays.count - maxDays : tempDays.count
        let endWeek = data.addEndEmptyDays(Array(tempDays[startIdx..<tempDays.count]), startDay: startDay)
        
        tempDays.removeSubrange(startIdx..<tempDays.count)
        let defaultDays = data.addStartEmptyDays(tempDays, startDay: startDay) + endWeek
        var extensionDays: [Day] = []
        
        if maxDays != 7,
           let indexOfInputDate = defaultDays.firstIndex(where: { $0.date?.kvkIsSameDay(otherDate: data.date) ?? false }),
           let firstDate = defaultDays.first?.date {
            let extraBufferDays = (defaultDays.count - indexOfInputDate) % maxDays
            if extraBufferDays > 0 {
                var i = extraBufferDays
                while (i > 0) {
                    if let newDate = firstDate.kvkAddingTo(.day, value: -1 * i) {
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
