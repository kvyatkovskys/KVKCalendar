//
//  MonthData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

@available(iOS 17.0, *)
@Observable final class MonthNewData: EventDateProtocol {
    typealias DayOfMonth = (indexPath: IndexPath, day: Day?, weeks: Int)
    
    var date: Date {
        didSet {
            headerDate = date
        }
    }
    var headerDate: Date
    var data: CalendarData
    var selectedEvent: Event?
    var style: KVKCalendar.Style
    var scrollId: Date? {
        didSet {
//            guard Platform.currentInterface != .phone, let idx = scrollId else { return }
//            headerDate = data.months[idx].date
        }
    }
    var days: [IndexPath: DayOfMonth] = [:]
    var daysCount: Int = 0
    let rowsInPage = 6
    let columnsInPage = 7
    
    private(set) var todayIdx: Date?
    
    init(data: CalendarData) {
        date = data.date
        headerDate = data.date
        self.data = data
        style = data.style
    }
    
    func setup() async {
        let months = await data.prepareMonths()
        await MainActor.run {
            data.months = months
        }
    }
    
    func getCurrentID() async {
        if date.kvkIsEqual(.now) {
            todayIdx = data.months.first(where: { $0.date.kvkMonthIsEqual(date) })?.date
        } else {
            todayIdx = data.months.first(where: { $0.date.kvkMonthIsEqual(.now) })?.date
        }
        await MainActor.run {
            scrollId = todayIdx
        }
    }
    
    func getDay(indexPath: IndexPath) -> DayOfMonth {
        // TODO: we got a crash sometime when use a horizontal scroll direction
        // got index out of array
        // safe: -> optional subscript
        let month = data.months[indexPath.section]
        return (indexPath, month.days[safe: indexPath.row], month.weeks)
    }
}

@available(iOS 17.0, *)
extension MonthNewData {
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

final class MonthData: EventDateProtocol {
    typealias DayOfMonth = (indexPath: IndexPath, day: Day?, weeks: Int)
    
    struct Parameters {
        let data: CalendarData
    }
    
    var selectedSection: Int = -1
    var date: Date
    var headerDate: Date
    var data: CalendarData
    var selectedEvent: Event?
    var daysCount: Int = 0
    var style: KVKCalendar.Style
    
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
        date = parameters.data.date
        headerDate = parameters.data.date
        data = parameters.data
        calendar = parameters.data.style.calendar
        scrollDirection = parameters.data.style.month.scrollDirection
        showRecurringEventInPast = parameters.data.style.event.showRecurringEventInPast
        style = parameters.data.style
        data.months = parameters.data.prepareMonthsOld()
        daysCount = data.months.reduce(0, { $0 + $1.days.count })
    }
    
    private func compareDate(day: Day, date: Date?) -> Bool {
        day.date?.kvkYear == date?.kvkYear && day.date?.kvkMonth == date?.kvkMonth
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
        if selectedDates.contains(where: { $0.kvkMonth != date.kvkMonth || $0.kvkYear != date.kvkYear }) {
            return [date]
        }
        
        var selectedDates = dates
        if let firstDate = selectedDates.min(by: { $0 < $1 }), firstDate.compare(date) == .orderedDescending {
            selectedDates.removeAll()
            selectedDates.insert(date)
        } else if let lastDate = selectedDates.max(by: { $0 < $1 }) {
            let offset = date.kvkDay - lastDate.kvkDay
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
    
    func findNextDateInMonth(_ month: Month) -> Date {
        if let date = month.days.first(where: { $0.date?.kvkYear == month.date.kvkYear
            && $0.date?.kvkMonth == month.date.kvkMonth
            && $0.date?.kvkDay == date.kvkDay })?.date {
            return date
        } else if let date = month.days.first(where: { $0.date?.kvkYear == month.date.kvkYear
            && $0.date?.kvkMonth == month.date.kvkMonth
            && $0.date?.kvkDay == (date.kvkDay - 1) })?.date {
            return date
        } else if month.date.kvkIsFebruary {
            // check for only February
            return month.days.last(where: { $0.type != .empty })?.date ?? Date()
        } else {
            return Date()
        }
    }
    
    func reloadEventsInDays(events: [Event], date: Date) -> (events: [Event], dates: [Date?]) {
        let recurringEvents = events.filter { $0.recurringType != .none } 
        guard let idxSection = data.months.firstIndex(where: { $0.date.kvkMonth == date.kvkMonth && $0.date.kvkYear == date.kvkYear }) else {
            return ([], [])
        }
        
        let days = data.months[idxSection].days
        var displayableEvents = [Event]()
        let updatedDays = days.reduce([], { (acc, day) -> [Day] in
            var newDay = day            
            let filteredEventsByDay = events.filter { (compareStartDate(day.date, with: $0) || checkMultipleDate(day.date, with: $0, checkMonth: true)) && !$0.isAllDay }
            let filteredAllDayEvents = events.filter { $0.isAllDay }
            let allDayEvents = filteredAllDayEvents.filter {
                compareStartDate(day.date, with: $0)
                || compareEndDate(day.date, with: $0)
                || checkMultipleDate(day.date, with: $0)
            }
            
            let recurringEventByDate = mapRecurringEvents(recurringEvents,
                                                          filteredEventsByDay: filteredEventsByDay,
                                                          date: day.date,
                                                          showRecurringEventInPast: showRecurringEventInPast,
                                                          calendar: calendar)
            
            let sortedEvents = (filteredEventsByDay + recurringEventByDate).sorted(by: { $0.start.kvkHour < $1.start.kvkHour })
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
