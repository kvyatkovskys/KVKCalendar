//
//  TimelineColumnView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 4/29/23.
//

import SwiftUI

@available(iOS 16.0, *)
struct TimelineColumnView: View, TimelineEventLayoutProtocol {
    
    struct Container: Identifiable {
        let event: Event
        var rect: CGRect
        
        var id: String {
            event.id
        }
    }
    
    @Binding var selectedEvent: Event?
    var items: [TimelineColumnView.Container]
    var crossEvents: [TimeInterval: CrossEvent]
    var style: Style
        
    init(selectedEvent: Binding<Event?>,
         items: [TimelineColumnView.Container],
         crossEvents: [TimeInterval: CrossEvent],
         style: Style) {
        _selectedEvent = selectedEvent
        self.items = items
        self.crossEvents = crossEvents
        self.style = style
        
        if crossEvents.isEmpty {
            self.crossEvents = calculateCrossEvents(forEvents: items.compactMap { $0.event })
        }
    }

    var body: some View {
        GeometryReader { (proxy) in
            EventStack(items: items,
                       crossEvents: crossEvents, size: proxy.size, style: style) {
                ForEach(items) { (item) in
                    EventNewView(isSelected: selectedEvent?.id == item.event.id, event: item.event, style: style) {
                        if selectedEvent?.id == item.event.id {
                            selectedEvent = nil
                        } else {
                            selectedEvent = item.event
                        }
                    }
                    .frame(width: getActualWidth(proxy, for: item),
                           height: item.rect.height)
                }
            }
            .background(.clear)
        }
    }
    
    private func getActualWidth(_ proxy: GeometryProxy,
                                for item: TimelineColumnView.Container) -> CGFloat {
        var width = proxy.size.width
        if let crossEvent = crossEvents[item.event.start.timeIntervalSince1970], !crossEvent.events.isEmpty {
            width /= CGFloat(crossEvent.events.count)
        }
        return width - style.timeline.offsetEvent
    }
    
}

@available(iOS 16.0, *)
struct TimelineColumnView_Previews: PreviewProvider {
    
    static var previews: some View {
        let items: [TimelineColumnView.Container] = [
            TimelineColumnView.Container(event: .stub(id: "1", duration: 50), rect: CGRect(x: 0, y: 100, width: 0, height: 350)),
            TimelineColumnView.Container(event: .stub(id: "2", duration: 30), rect: CGRect(x: 0, y: 100, width: 0, height: 140)),
            TimelineColumnView.Container(event: .stub(id: "3", startFrom: 30, duration: 55), rect: CGRect(x: 0, y: 270, width: 0, height: 400)),
            TimelineColumnView.Container(event: .stub(id: "4", startFrom: 80, duration: 30), rect: CGRect(x: 0, y: 500, width: 0, height: 100)),
            TimelineColumnView.Container(event: .stub(id: "5", startFrom: 80, duration: 30), rect: CGRect(x: 0, y: 500, width: 0, height: 100))
        ]
        return Group {
            TimelineColumnView(selectedEvent: .constant(nil), items: items, crossEvents: [:], style: Style())
            TimelineColumnView(selectedEvent: .constant(.stub(id: "1")), items: items, crossEvents: [:], style: Style())
        }
    }
}

@available(iOS 16.0, *)
struct EventStack: Layout {
    
    var items: [TimelineColumnView.Container]
    var crossEvents: [TimeInterval: CrossEvent]
    var size: CGSize
    var style: Style
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // get ideal size based
        let subviewSizes = subviews
            .compactMap {
                $0.sizeThatFits(.unspecified)
            }
        var rects = [CGRect]()
        for index in subviews.indices {
            let subviewSize = subviewSizes[index]
            var item = items[index]
            item.rect.size = subviewSize
            let rect = calculateFrame(item: item, pageFrame: bounds, rects: rects, crossEvents: crossEvents)
            rects.append(rect)
            let sizeProposal = ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            subviews[index].place(at: rect.origin, anchor: .topLeading, proposal: sizeProposal)
        }
    }
    
    private func calculateFrame(item: TimelineColumnView.Container,
                                pageFrame: CGRect,
                                rects: [CGRect],
                                crossEvents: [TimeInterval: CrossEvent]) -> CGRect {
        let event = item.event
        var frame = item.rect
        if let defaultWidth = event.style?.defaultWidth {
            frame.size.width = defaultWidth
        }
        // calculate 'width' and position 'x' event
        // check events are not empty to avoid crash https://github.com/kvyatkovskys/KVKCalendar/issues/237
        if let crossEvent = crossEvents[event.start.timeIntervalSince1970], !crossEvent.events.isEmpty {
            var newX = frame.origin.x
            if crossEvent.events.count > 1 {
                func moveXIfNeeded() {
                    var needMove = true
                    while needMove {
                        let tempRect = CGRect(x: newX,
                                              y: frame.origin.y,
                                              width: frame.width,
                                              height: frame.height)
                        if let oldRect = rects.first(where: { $0.intersects(tempRect) }) {
                            newX += (oldRect.width + style.timeline.offsetEvent).rounded()
                        } else {
                            needMove = false
                        }
                    }
                }
                
                moveXIfNeeded()
            }
            
            // when the current event exceeds a certain frame
            if newX >= pageFrame.width {
                let value = frame.width * 0.5
                let lastIdx = rects.count - 1
//                if var lastUpdatedRect = rects[safe: lastIdx] {
//                    lastUpdatedRect.size.width -= value
//                    rects.removeLast()
//                    rects.append(lastUpdatedRect)
//                }
                newX -= value
            }
            
            // sometimes the event width is large than the page width
            let newEventWidth = newX + frame.width
            if newEventWidth > pageFrame.width {
                frame.size.width -= newEventWidth - pageFrame.width + style.timeline.offsetEvent
            }
            frame.origin.x = newX
        }
        return frame
    }
    
}
