//
//  CalendarViewDisplayable.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 5/1/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar
import EventKit

@available(iOS 13.0, *)
struct CalendarDisplayView: UIViewRepresentable, KVKCalendarSettings {
    
    @Binding var events: [Event]
    
    var style: Style {
        createCalendarStyle()
    }
    var selectDate = Date()
    var eventViewer = EventViewer()

    private var calendar = CalendarView(frame: .zero)
        
    func makeUIView(context: UIViewRepresentableContext<CalendarDisplayView>) -> CalendarView {
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        calendar.reloadData()
        return calendar
    }
    
    func updateUIView(_ uiView: CalendarView, context: UIViewRepresentableContext<CalendarDisplayView>) {
        context.coordinator.events = events
    }
    
    func makeCoordinator() -> CalendarDisplayView.Coordinator {
        Coordinator(self)
    }
    
    public init(events: Binding<[Event]>) {
        self._events = events
        selectDate = onlyDateFormatter.date(from: defaultDate) ?? Date()
        
        var frame = UIScreen.main.bounds
        frame.origin.y = 0
        frame.size.height -= topOffset
        calendar = CalendarView(frame: frame, date: selectDate, style: style)
    }
    
    // MARK: Calendar DataSource and Delegate
    class Coordinator: NSObject, CalendarDataSource, CalendarDelegate {
        private let view: CalendarDisplayView
        
        var events: [Event] = [] {
            didSet {
                view.calendar.reloadData()
            }
        }
        
        init(_ view: CalendarDisplayView) {
            self.view = view
            super.init()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(changedOerintation),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
        }
        
        func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
            events
        }
        
        func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
            view.eventViewer.frame = frame
            view.eventViewer.reloadFrame(frame: frame)
            return view.eventViewer
        }
        
        func didChangeViewerFrame(_ frame: CGRect) {
            view.eventViewer.reloadFrame(frame: frame)
        }
        
        // MARK: Private
        
        @objc private func changedOerintation() {
            var frame = UIScreen.main.bounds
            frame.origin.y = 0
            frame.size.height -= (view.topOffset + view.bottomOffset)
            view.calendar.reloadFrame(frame)
        }
        
    }
}
