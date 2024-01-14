//
//  TimelineNewPageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 1/14/24.
//

import SwiftUI

@available(iOS 17.0, *)
struct TimelineNewPageView: View {
    
    let params: TimelinePageWrapper.Parameters
    
    var body: some View {
        bodyView
    }
    
    private var bodyView: some View {
        ZStack {
            GeometryReader { (geometry) in
                TabView(selection: .constant(3)) {
                    ForEach(0..<params.style.timeline.maxLimitCachedPages, id: \.self) { (idx) in
                        TimelineViewWrapper(params: params, frame: geometry.frame(in: .local))
                            .ignoresSafeArea(.container, edges: .bottom)
                            .id(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private func setupTimelinePageView(frame: CGRect) -> [TimelineViewWrapper] {
        Array(0..<params.style.timeline.maxLimitCachedPages).reduce([]) { (acc, _) -> [TimelineViewWrapper] in
            acc + [TimelineViewWrapper(params: params, frame: frame)]
        }
    }
}

@available(iOS 17.0, *)
#Preview("Week") {
    var style = KVKCalendar.Style()
    style.timeline.offsetTimeY = 50
    let events: [KVKCalendar.Event] = [
        .stub(id: "1", startFrom: -50, duration: 50),
        .stub(id: "2", startFrom: 60, duration: 30),
        .stub(id: "3", startFrom: -30, duration: 55),
        .stub(id: "4", startFrom: -80, duration: 30),
        .stub(id: "5", startFrom: -80, duration: 30)
    ]
    @State var event: KVKCalendar.Event?
    return TimelineNewPageView(params: TimelinePageWrapper.Parameters(style: style, dates: Array(repeating: Date(), count: 7), selectedDate: Date(), events: events, recurringEvents: [], selectedEvent: $event))
}

@available(iOS 17.0, *)
#Preview("Day") {
    var style = KVKCalendar.Style()
    style.timeline.offsetTimeY = 50
    let events: [KVKCalendar.Event] = [
        .stub(id: "1", startFrom: -50, duration: 50),
        .stub(id: "2", startFrom: 60, duration: 30),
        .stub(id: "3", startFrom: -30, duration: 55),
        .stub(id: "4", startFrom: -80, duration: 30),
        .stub(id: "5", startFrom: -80, duration: 30)
    ]
    @State var event: KVKCalendar.Event?
    return TimelineNewPageView(params: TimelinePageWrapper.Parameters(style: style, dates: Array(repeating: Date(), count: 1), selectedDate: Date(), events: events, recurringEvents: [], selectedEvent: $event))
}
