//
//  TimelineModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 09.03.2020.
//

#if os(iOS)

import UIKit

struct TimeContainer {
    var minute: Int
    var hour: Int
}

typealias ResizeTime = (hour: Int, minute: Int)

protocol TimelineDelegate: AnyObject {
    func didDisplayEvents(_ events: [Event], dates: [Date?])
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func nextDate()
    func previousDate()
    func swipeX(transform: CGAffineTransform, stop: Bool)
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDay: Int?)
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint)
    func didResizeEvent(_ event: Event, startTime: ResizeTime, endTime: ResizeTime)
}

extension TimelineDelegate {
    func swipeX(transform: CGAffineTransform, stop: Bool) {}
}

protocol EventDateProtocol: AnyObject {}

extension EventDateProtocol {
    
    func mapRecurringEvents(_ recurringEvents: [Event],
                            filteredEventsByDay: [Event],
                            date: Date?,
                            showRecurringEventInPast: Bool,
                            calendar: Calendar) -> [Event] {
        if !recurringEvents.isEmpty, let date = date {
            return recurringEvents.reduce([], { (acc, event) -> [Event] in
                guard !filteredEventsByDay.contains(where: { $0.ID == event.ID })
                        && (date.compare(event.start) == .orderedDescending
                            || showRecurringEventInPast) else { return acc }
                
                guard let recurringEvent = event.updateDate(newDate: date, calendar: calendar) else {
                    return acc
                }
                
                return acc + [recurringEvent]
            })
        } else {
            return []
        }
    }
    
    func compareStartDate(_ date: Date?, with event: Event) -> Bool {
        guard let dt = date else { return false }
        
        return event.start.isEqual(dt)
    }
    
    func compareEndDate(_ date: Date?, with event: Event) -> Bool {
        guard let dt = date else { return false }
        
        return event.end.isEqual(dt)
    }
    
    func checkMultipleDate(_ date: Date?, with event: Event, checkMonth: Bool = false) -> Bool {
        let startDate = event.start.timeIntervalSince1970
        let endDate = event.end.timeIntervalSince1970
        
        // workaround to fix crash https://github.com/kvyatkovskys/KVKCalendar/issues/191
        guard let timeInterval = date?.timeIntervalSince1970, endDate > startDate else { return false }
        
        let result = event.start.kvkDay != event.end.kvkDay
        && (startDate...endDate).contains(timeInterval)
        && event.start.kvkYear == date?.kvkYear
        
        if checkMonth {
            return result && event.start.kvkMonth == date?.kvkMonth
        } else {
            return result
        }
    }
}

extension TimelineView {
    struct StubEvent {
        let event: Event
        let frame: CGRect
    }
    
    enum ScrollDirectionType: Int {
        case up, down
    }
}

#endif
