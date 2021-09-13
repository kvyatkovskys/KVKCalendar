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

protocol EventDateProtocol {}

extension EventDateProtocol {
    func compareStartDate(_ date: Date?, with event: Event) -> Bool {
        return event.start.year == date?.year && event.start.month == date?.month && event.start.day == date?.day
    }
    
    func compareEndDate(_ date: Date?, with event: Event) -> Bool {
        return event.end.year == date?.year && event.end.month == date?.month && event.end.day == date?.day
    }
    
    func checkMultipleDate(_ date: Date?, with event: Event) -> Bool {
        let startDate = event.start.timeIntervalSince1970
        let endDate = event.end.timeIntervalSince1970
        
        // workaround to fix crash https://github.com/kvyatkovskys/KVKCalendar/issues/191
        guard let timeInterval = date?.timeIntervalSince1970, endDate > startDate else { return false }
        
        return event.start.day != event.end.day
            && startDate...endDate ~= timeInterval
            && event.start.year == date?.year
            && event.start.month == date?.month
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
