//
//  TimelineModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 09.03.2020.
//

import Foundation

struct CrossEvent: Hashable {
    let eventTime: EventTime
    var count: Int
    
    init(eventTime: EventTime, count: Int = 1) {
        self.eventTime = eventTime
        self.count = count
    }
    
    static func == (lhs: CrossEvent, rhs: CrossEvent) -> Bool {
        return lhs.eventTime == rhs.eventTime
            && lhs.count == rhs.count
    }
}

extension CrossEvent {
    var displayValue: String {
        return "\(Date(timeIntervalSince1970: eventTime.start).toLocalTime()) - \(Date(timeIntervalSince1970: eventTime.end).toLocalTime()) = \(count)"
    }
}

struct EventTime: Equatable, Hashable {
    let start: TimeInterval
    let end: TimeInterval
}

protocol TimelineDelegate: AnyObject {
    func didDisplayEvents(_ events: [Event], dates: [Date?])
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func nextDate()
    func previousDate()
    func swipeX(transform: CGAffineTransform, stop: Bool)
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint)
    func didAddEvent(minute: Int, hour: Int, point: CGPoint)
}

protocol CompareEventDateProtocol {
    func compareStartDate(event: Event, date: Date?) -> Bool
    func compareEndDate(event: Event, date: Date?) -> Bool
}

extension CompareEventDateProtocol {
    func compareStartDate(event: Event, date: Date?) -> Bool {
        return event.start.year == date?.year && event.start.month == date?.month && event.start.day == date?.day
    }
    
    func compareEndDate(event: Event, date: Date?) -> Bool {
        return event.end.year == date?.year && event.end.month == date?.month && event.end.day == date?.day
    }
}
