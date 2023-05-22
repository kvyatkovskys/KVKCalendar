//
//  ListViewData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

#if os(iOS)

import Foundation

open class ListViewData: EventDateProtocol {
    
    public struct SectionListView {
        let date: Date
        var events: [Event]
        
        public init(date: Date, events: [Event]) {
            self.date = date
            self.events = events
        }
    }
    
    var sections: [SectionListView]
    var date: Date
    var isSkeletonVisible = false
    
    private let style: Style?
    private let lastDate: Date?
    
    init(data: CalendarData, style: Style) {
        self.date = data.date
        self.lastDate = data.months.last?.days.filter { $0.type != .empty }.last?.date
        self.style = style
        self.sections = []
    }
    
    public init(date: Date, sections: [SectionListView]) {
        self.date = date
        self.sections = sections
        self.style = nil
        self.lastDate = nil
    }
    
    func titleOfHeader(section: Int, formatter: DateFormatter, locale: Locale) -> String {
        let dateSection = sections[section].date
        formatter.locale = locale
        return formatter.string(from: dateSection)
    }
    
    func reloadEvents(_ events: [Event]) {
        sections = events.filter { $0.recurringType != .none }.reduce([], { (acc, event) -> [SectionListView] in
            var accTemp = acc
            
            if let date = lastDate, let calendar = style?.calendar {
                let recurringSections = addRecurringEvent(event, lastDate: date, calendar: calendar)
                recurringSections.forEach { (recurringSection) in
                    if let idx = accTemp.firstIndex(where: { $0.date.kvkIsEqual(recurringSection.date) }) {
                        accTemp[idx].events += recurringSection.events
                        accTemp[idx].events = accTemp[idx].events.sorted(by: { $0.start < $1.start })
                    } else {
                        accTemp.append(recurringSection)
                    }
                }
            }
            
            return accTemp
        })
        
        sections += events.filter { $0.recurringType == .none }.reduce([], { (acc, event) -> [SectionListView] in
            var accTemp = acc
            
            if event.start.kvkDay != event.end.kvkDay {
                let offset: Int
                if event.start.kvkMonth == event.end.kvkMonth {
                    offset = abs(event.end.kvkDay - event.start.kvkDay)
                } else {
                    offset = abs((event.start.kvkEndOfMonth!.kvkDay - event.start.kvkDay) + event.end.kvkDay)
                }
                
                for i in 1...offset {
                    if let newDate = style?.calendar.date(byAdding: .day, value: i, to: event.start) {
                        var newEvent = event
                        newEvent.start = newDate
                        if let idx = accTemp.firstIndex(where: { compareStartDate($0.date, with: newEvent) }) {
                            accTemp[idx].events.append(event)
                            let eventValues = accTemp[idx].events.splitEvents
                            let filteredEvents = eventValues[.usual] ?? []
                            let filteredAllDayEvents = eventValues[.allDay] ?? []
                            accTemp[idx].events = filteredAllDayEvents + filteredEvents.sorted(by: { $0.start < $1.start })
                        } else {
                            accTemp += [SectionListView(date: newEvent.start, events: [newEvent])]
                        }
                    }
                }
            }
            
            guard let idx = accTemp.firstIndex(where: { compareStartDate($0.date, with: event) }) else {
                accTemp += [SectionListView(date: event.start, events: [event])]
                return accTemp
            }

            accTemp[idx].events.append(event)
            let eventValues = accTemp[idx].events.splitEvents
            let filteredEvents = eventValues[.usual] ?? []
            let filteredAllDayEvents = eventValues[.allDay] ?? []
            accTemp[idx].events = filteredAllDayEvents + filteredEvents.sorted(by: { $0.start < $1.start })
            return accTemp
        })
        
        sections = sections.sorted(by: { $0.date < $1.date })
    }
    
    func event(indexPath: IndexPath) -> Event {
        sections[indexPath.section].events[indexPath.row]
    }
    
    func numberOfSection() -> Int {
        isSkeletonVisible ? 2 : sections.count
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        isSkeletonVisible ? 5 : sections[section].events.count
    }
    
    private func addRecurringEvent(_ event: Event, lastDate: Date, calendar: Calendar) -> [SectionListView] {
        var items = [SectionListView]()
        var eventTemp = event
        
        func createNewDate(event: Event) -> Date? {
            calendar.date(byAdding: event.recurringType.component,
                          value: event.recurringType.shift,
                          to: event.start)
        }
        
        var value = true
        while value {
            if let newDate = createNewDate(event: eventTemp) {
                value = newDate <= lastDate
                
                if value, let nextEvent = event.updateDate(newDate: newDate, calendar: calendar) {
                    eventTemp = nextEvent
                    items.append(SectionListView(date: nextEvent.start, events: [nextEvent]))
                } else {
                    value = false
                }
            } else {
                value = false
            }
        }

        return items
    }
    
}

#endif
