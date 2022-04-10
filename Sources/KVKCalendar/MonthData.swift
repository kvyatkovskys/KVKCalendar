//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class MonthData: EventDateProtocol {
    
    typealias DayOfMonth = (indexPath: IndexPath, day: Day?, weeks: Int)
    
    struct Parameters {
        let data: CalendarData
        let startDay: StartDayType
        let calendar: Calendar
        let style: Style
    }
    
    var selectedSection: Int = -1
    var date: Date
    var data: CalendarData
    let daysCount: Int
    
    let tagEventPagePreview = -20
    let eventPreviewYOffset: CGFloat = 30
    var eventPreviewXOffset: CGFloat = 60
    let rowsInPage = 6
    let columnsInPage = 7
    var isFirstLoad = true
    var movingEvent: EventViewGeneral?
    var selectedDates: Set<Date> = []
    var isSkeletonVisible = false
    var days: [IndexPath: DayOfMonth] = [:]
    var customEventsView: [Date: UIView] = [:]
    
    private let calendar: Calendar
    private let scrollDirection: UICollectionView.ScrollDirection
    private let showRecurringEventInPast: Bool
    
    init(parameters: Parameters) {
        self.data = parameters.data
        self.calendar = parameters.calendar
        self.scrollDirection = parameters.style.month.scrollDirection
        self.showRecurringEventInPast = parameters.style.event.showRecurringEventInPast
        
        let months = parameters.data.months.reduce([], { (acc, month) -> [Month] in
            var daysTemp = parameters.data.addStartEmptyDays(month.days, startDay: parameters.startDay)
            
            let boxCount: Int
            switch month.weeks {
            case 5 where parameters.style.month.scrollDirection == .vertical:
                boxCount = parameters.data.minBoxCount
            default:
                boxCount = parameters.data.maxBoxCount
            }
            
            if let lastDay = daysTemp.last, daysTemp.count < boxCount {
                let emptyEndDays = Array(1...(boxCount - daysTemp.count)).compactMap { (idx) -> Day in
                    var day = Day.empty()
                    day.date = parameters.data.getOffsetDate(offset: idx, to: lastDay.date)
                    return day
                }
                
                daysTemp += emptyEndDays
            }
            var monthTemp = month
            monthTemp.days = daysTemp
            return acc + [monthTemp]
        })
        self.data.months = months
        self.date = parameters.data.date
        self.daysCount = months.reduce(0, { $0 + $1.days.count })
    }
    
    private func compareDate(day: Day, date: Date?) -> Bool {
        day.date?.year == date?.year && day.date?.month == date?.month
    }
    
    func getDay(indexPath: IndexPath) -> DayOfMonth {
        // TODO: we got a crash sometime when use a horizontal scroll direction
        // got index out of array
        // safe: -> optional subscript
        let month = data.months[indexPath.section]
        return (indexPath, month.days[safe: indexPath.row], month.weeks)
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
            
            let filteredEventsByDay = events.filter { compareStartDate(day.date, with: $0) && !$0.isAllDay }
            let filteredAllDayEvents = events.filter { $0.isAllDay }
            let allDayEvents = filteredAllDayEvents.filter {
                compareStartDate(day.date, with: $0)
                || compareEndDate(day.date, with: $0)
                || checkMultipleDate(day.date, with: $0)
            }
            
            let recurringEventByDate: [Event]
            if !recurringEvents.isEmpty, let date = day.date {
                recurringEventByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                    guard !filteredEventsByDay.contains(where: { $0.ID == event.ID })
                            && (date.compare(event.start) == .orderedDescending
                                || showRecurringEventInPast) else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: date, calendar: calendar) else {
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
        (rowsInPage * columnsInPage) / 2
    }
    var columns: Int {
        ((daysCount / itemsInPage) * columnsInPage) + (daysCount % itemsInPage)
    }
    var itemsInPage: Int {
        columnsInPage * rowsInPage
    }
}

#endif
