//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthData: EventDateProtocol {
    
    struct Parameters {
        let data: CalendarData
        let startDay: StartDayType
        let calendar: Calendar
        let monthStyle: MonthStyle
    }
    
    var willSelectDate: Date
    var date: Date
    var data: CalendarData
    let daysCount: Int
    
    var isAnimate: Bool = false
    let tagEventPagePreview = -20
    let eventPreviewYOffset: CGFloat = 30
    var eventPreviewXOffset: CGFloat = 60
    let rowsInPage = 6
    let columnsInPage = 7
    var isFirstLoad = true
    var movingEvent: EventViewGeneral?
    var selectedDates: Set<Date> = []
    
    private let calendar: Calendar
    private let scrollDirection: UICollectionView.ScrollDirection
    
    init(parameters: Parameters) {
        self.data = parameters.data
        self.calendar = parameters.calendar
        self.scrollDirection = parameters.monthStyle.scrollDirection
        
        let months = parameters.data.months.reduce([], { (acc, month) -> [Month] in
            var daysTemp = parameters.data.addStartEmptyDays(month.days, startDay: parameters.startDay)
            if let lastDay = daysTemp.last, daysTemp.count < parameters.data.boxCount {
                var emptyEndDays = Array(1...(parameters.data.boxCount - daysTemp.count)).compactMap { (idx) -> Day in
                    var day = Day.empty()
                    day.date = parameters.data.getOffsetDate(offset: idx, to: lastDay.date)
                    return day
                }
                
                if !parameters.monthStyle.isPagingEnabled && emptyEndDays.count > 7 && parameters.monthStyle.scrollDirection == .vertical {
                    emptyEndDays = emptyEndDays.dropLast(7)
                }
                
                daysTemp += emptyEndDays
            }
            var monthTemp = month
            monthTemp.days = daysTemp
            return acc + [monthTemp]
        })
        self.data.months = months
        self.date = parameters.data.date
        self.willSelectDate = data.date
        self.daysCount = months.reduce(0, { $0 + $1.days.count })
    }
    
    private func compareDate(day: Day, date: Date?) -> Bool {
        return day.date?.year == date?.year && day.date?.month == date?.month
    }
    
    func getDay(indexPath: IndexPath) -> Day? {
        // TODO: we got a crash sometime when use a horizontal scroll direction
        // got index out of array
        // safe: -> optional subscript
        return data.months[indexPath.section].days[safe: indexPath.row]
    }
    
    func updateSelectedDates(_ dates: Set<Date>, date: Date, calendar: Calendar) -> Set<Date> {
        // works only in the same month
        if selectedDates.contains(where: { $0.month != date.month || $0.year != date.year }) {
            return [date]
        }
        
        var selectedDates = dates
        if let firstDate = selectedDates.min(by: { $0 < $1 }), firstDate.compare(date) == .orderedDescending {
            selectedDates.removeAll()
            selectedDates.insert(date)
        } else if let lastDate = selectedDates.max(by: { $0 < $1 }) {
            let offset = date.day - lastDate.day
            if offset >= 1 {
                let dates = (1...offset).compactMap({ calendar.date(byAdding: .day, value: $0, to: lastDate) })
                selectedDates.formUnion(dates)
            } else if offset < 0 {
                selectedDates = selectedDates.filter({ $0.compare(date) == .orderedAscending })
                selectedDates.insert(date)
            } else {
                selectedDates.remove(date)
            }
        } else {
            selectedDates.insert(date)
        }
        
        return selectedDates
    }
    
    func reloadEventsInDays(events: [Event], date: Date) -> (events: [Event], dates: [Date?]) {
        let recurringEvents = events.filter({ $0.recurringType != .none })
        guard let idxSection = data.months.firstIndex(where: { $0.date.month == date.month && $0.date.year == date.year }) else {
            return ([], [])
        }
        
        let days = data.months[idxSection].days
        var displayableEvents = [Event]()
        let updatedDays = days.reduce([], { (acc, day) -> [Day] in
            var newDay = day
            guard newDay.events.isEmpty else { return acc + [day] }
            
            let filteredEventsByDay = events.filter({ compareStartDate(day.date, with: $0) && !$0.isAllDay })
            let filteredAllDayEvents = events.filter({ $0.isAllDay })
            let allDayEvents = filteredAllDayEvents.filter({ compareStartDate(day.date, with: $0) || compareEndDate(day.date, with: $0) })
            
            let recurringEventByDate: [Event]
            if !recurringEvents.isEmpty, let date = day.date {
                recurringEventByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                    guard !filteredEventsByDay.contains(where: { $0.ID == event.ID })
                            && date.compare(event.start) == .orderedDescending else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: day.date, calendar: calendar) else {
                        return acc
                    }
                    
                    return acc + [recurringEvent]
                })
            } else {
                recurringEventByDate = []
            }
            
            let sortedEvents = (filteredEventsByDay + recurringEventByDate).sorted(by: { $0.start.hour < $1.start.hour })
            newDay.events = allDayEvents + sortedEvents.sorted(by: { $0.isAllDay && !$1.isAllDay })
            displayableEvents += newDay.events
            return acc + [newDay]
        })
        
        data.months[idxSection].days = updatedDays
        return (displayableEvents, updatedDays.map({ $0.date }))
    }
}

extension MonthData {
    var middleRowInPage: Int {
        return (rowsInPage * columnsInPage) / 2
    }
    var columns: Int {
        return ((daysCount / itemsInPage) * columnsInPage) + (daysCount % itemsInPage)
    }
    var itemsInPage: Int {
        return columnsInPage * rowsInPage
    }
}
