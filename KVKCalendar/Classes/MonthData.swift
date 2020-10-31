//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthData: EventDateProtocol {
    var days: [Day]
    var date: Date
    var data: YearData
    var isAnimate: Bool = false
    let tagEventPagePreview = -20
    let eventPreviewYOffset: CGFloat = 30
    var eventPreviewXOffset: CGFloat = 60
    var willSelectDate: Date?
    let rows = 6
    let columns = 7
    var isFirstLoad = true
    var movingEvent: EventViewGeneral?
    
    private let cachedDays: [Day]
    private let calendar: Calendar
    private let scrollDirection: UICollectionView.ScrollDirection
    
    init(yearData: YearData, startDay: StartDayType, calendar: Calendar, scrollDirection: UICollectionView.ScrollDirection) {
        self.data = yearData
        self.calendar = calendar
        self.scrollDirection = scrollDirection
        
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
    
    func reloadEventsInDays(events: [Event]) -> (events: [Event], dates: [Date?]) {
        let recurringEvents = events.filter({ $0.recurringType != .none })
        let startDate = date.startOfMonth
        let endDate = date.endOfMonth?.startOfDay
        let startIdx = cachedDays.firstIndex(where: { $0.date?.day == startDate?.day && compareDate(day: $0, date: startDate) }) ?? 0
        let endIdx = cachedDays.firstIndex(where: { $0.date?.day == endDate?.day && compareDate(day: $0, date: endDate) }) ?? 0
        
        var displayableEvents = [Event]()
        let newDays = cachedDays[startIdx...endIdx].reduce([], { (acc, day) -> [Day] in
            var newDay = day
            guard newDay.events.isEmpty else { return acc + [day] }
            
            let filteredEventsByDay = events.filter({ compareStartDate(day.date, with: $0) })
            let filteredAllDayEvents = events.filter({ $0.isAllDay })
            let allDayEvents = filteredAllDayEvents.filter({ compareStartDate(day.date, with: $0) || compareEndDate(day.date, with: $0) })
            let otherEvents = filteredEventsByDay.filter({ !$0.isAllDay })
            let recurringEventByDate: [Event]
            if !recurringEvents.isEmpty {
                recurringEventByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                    guard !otherEvents.contains(where: { $0.ID == event.ID }) else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: day.date, calendar: calendar) else {
                        return acc
                    }
                    
                    return acc + [recurringEvent]
                    
                })
            } else {
                recurringEventByDate = []
            }
            let sortedEvents = (otherEvents + recurringEventByDate).sorted(by: { $0.start.hour < $1.start.hour })
            newDay.events = allDayEvents + sortedEvents.sorted(by: { $0.isAllDay && !$1.isAllDay })
            displayableEvents += newDay.events
            return acc + [newDay]
        })
        
        days[startIdx...endIdx] = ArraySlice(newDays)
        
        return (displayableEvents, newDays.map({ $0.date }))
    }
}
