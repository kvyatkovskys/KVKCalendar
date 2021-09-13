//
//  DefaultTimelineEventLayout.swift
//  KVKCalendar
//
//  Created by Tom Knapen on 12/07/2021.
//

#if os(iOS)

import UIKit

public struct DefaultTimelineEventLayout: TimelineEventLayout {
    public func getEventRects(forEvents events: [Event], date: Date?, context: TimelineEventLayoutContext) -> [CGRect] {
        var rects: [CGRect] = []

        let crossEvents = context.calculateCrossEvents(forEvents: events)

        for event in events {
            var frame = context.getEventRect(start: event.start, end: event.end, date: date, style: event.style)

            // calculate 'width' and position 'x'
            if let crossEvent = crossEvents[event.start.timeIntervalSince1970] {
                var newOriginX = frame.origin.x
                var newWidth = frame.width
                newWidth /= CGFloat(crossEvent.events.count)
                newWidth -= context.style.timeline.offsetEvent
                frame.size.width = newWidth

                if crossEvent.events.count > 1 {
                    for rect in rects {
                        while rect.intersects(CGRect(x: newOriginX, y: frame.origin.y, width: frame.width, height: frame.height)) {
                            newOriginX += (rect.width + context.style.timeline.offsetEvent).rounded()
                        }
                    }
                }

                frame.origin.x = newOriginX
            }

            rects.append(frame)
        }

        return rects
    }
}

#endif
