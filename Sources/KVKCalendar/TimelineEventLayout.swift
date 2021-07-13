//
//  TimelineEventLayout.swift
//  KVKCalendar
//
//  Created by Tom Knapen on 12/07/2021.
//

import UIKit

public struct TimelineEventLayoutContext {
    public let style: Style
    let pageFrame: CGRect
    let startHour: Int
    let timeLabels: [TimelineLabel]
    let calculatePointYByMinute: (_ minute: Int, _ label: TimelineLabel) -> CGFloat
    let getTimelineLabel: (_ hour: Int) -> TimelineLabel?
}

public protocol TimelineEventLayout {
    func getEventRects(forEvents events: [Event], date: Date?, context: TimelineEventLayoutContext) -> [CGRect]
}

public extension TimelineEventLayoutContext {
    func getEventRect(start: Date, end: Date, date: Date?, style eventStyle: EventStyle?) -> CGRect {
        var newFrame = pageFrame
        let midnight = 24

        for time in timeLabels {
            // calculate position 'y'
            if start.hour.hashValue == time.valueHash, start.day == date?.day {
                if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
                    newFrame.origin.y = calculatePointYByMinute(start.minute, newTime)
                } else {
                    newFrame.origin.y = calculatePointYByMinute(start.minute, time)
                }
            } else if let firstTimeLabel = getTimelineLabel(startHour), start.day != date?.day {
                newFrame.origin.y = calculatePointYByMinute(startHour, firstTimeLabel)
            }

            // calculate 'height' event
            if let defaultHeight = eventStyle?.defaultHeight {
                newFrame.size.height = defaultHeight
            } else if let globalDefaultHeight = style.event.defaultHeight {
                newFrame.size.height = globalDefaultHeight
            } else if end.hour.hashValue == time.valueHash, end.day == date?.day {
                var timeTemp = time
                if time.tag == midnight, let newTime = timeLabels.first(where: { $0.tag == 0 }) {
                    timeTemp = newTime
                }

                let summHeight = (CGFloat(timeTemp.tag) * (style.timeline.offsetTimeY + timeTemp.frame.height)) - newFrame.origin.y + (timeTemp.frame.height / 2)
                if 0...59 ~= end.minute {
                    let minutePercent = 59.0 / CGFloat(end.minute)
                    let newY = (style.timeline.offsetTimeY + timeTemp.frame.height) / minutePercent
                    newFrame.size.height = summHeight + newY - style.timeline.offsetEvent
                } else {
                    newFrame.size.height = summHeight - style.timeline.offsetEvent
                }
            } else if end.day != date?.day {
                newFrame.size.height = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) - newFrame.origin.y + (time.frame.height / 2)
            }
        }

        return newFrame
    }
}

// MARK: - Helpers

public extension TimelineEventLayoutContext {
    // count event cross in one hour
    func calculateCrossEvents(forEvents events: [Event]) -> [TimeInterval: CrossEvent] {
        var eventsTemp = events
        var crossEvents = [TimeInterval: CrossEvent]()

        while let event = eventsTemp.first {
            let start = event.start.timeIntervalSince1970
            let end = event.end.timeIntervalSince1970
            var crossEventNew = CrossEvent(eventTime: EventTime(start: start, end: end))
            let endCalculated: TimeInterval = crossEventNew.eventTime.end - TimeInterval(style.timeline.offsetEvent)
            crossEventNew.events = events.filter { item in
                let itemEnd = item.end.timeIntervalSince1970 - TimeInterval(style.timeline.offsetEvent)
                let itemStart = item.start.timeIntervalSince1970
                guard itemEnd > itemStart else { return false }

                return (itemStart...itemEnd).contains(start) || (itemStart...itemEnd).contains(endCalculated) || (start...endCalculated).contains(itemStart) || (start...endCalculated).contains(itemEnd)
            }

            crossEvents[crossEventNew.eventTime.start] = crossEventNew
            eventsTemp.removeFirst()
        }

        return crossEvents
    }
}

public struct EventTime: Equatable, Hashable {
    public let start: TimeInterval
    public let end: TimeInterval
}

public struct CrossEvent {
    public let eventTime: EventTime
    public var events: [Event] = []
}
