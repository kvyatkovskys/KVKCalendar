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
    @Binding var type: CalendarType
    @Binding var updatedDate: Date?
    
    var style: Style {
        createCalendarStyle()
    }
    var selectDate = Date()
    var eventViewer = EventViewer()

    private var calendar = CalendarView(frame: .zero)
        
    func makeUIView(context: UIViewRepresentableContext<CalendarDisplayView>) -> CalendarView {
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        return calendar
    }
    
    func updateUIView(_ uiView: CalendarView, context: UIViewRepresentableContext<CalendarDisplayView>) {
        context.coordinator.events = events
        context.coordinator.type = type
        context.coordinator.updatedDate = updatedDate
    }
    
    func makeCoordinator() -> CalendarDisplayView.Coordinator {
        Coordinator(self)
    }
    
    public init(events: Binding<[Event]>, type: Binding<CalendarType>, updatedDate: Binding<Date?>) {
        self._events = events
        self._type = type
        self._updatedDate = updatedDate
        selectDate = defaultDate
        
        var frame = UIScreen.main.bounds
        frame.origin.y = 0
        frame.size.height -= topOffset
        calendar = CalendarView(frame: frame, date: selectDate, style: style)
    }
    
    // MARK: Calendar DataSource and Delegate
    class Coordinator: NSObject, CalendarDataSource, CalendarDelegate {
        private var view: CalendarDisplayView
        
        var events: [Event] = [] {
            didSet {
                view.calendar.reloadData()
            }
        }
        
        var type: CalendarType = .day {
            didSet {
                view.calendar.set(type: type, date: view.selectDate)
                view.calendar.reloadData()
            }
        }
        
        var updatedDate: Date? {
            didSet {
                if let date = updatedDate {
                    view.selectDate = date
                    view.calendar.reloadData()
                }
            }
        }
        
        init(_ view: CalendarDisplayView) {
            self.view = view
            super.init()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(changedOerintation),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
            
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
                self.view.loadEvents(dateFormat: view.style.timeSystem.format) { [weak self] (events) in
                    self?.view.events = events
                }
            }
        }
        
        func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
            view.handleEvents(systemEvents: systemEvents)
        }
        
        func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
            view.handleCustomEventView(event: event, style: view.calendar.style, frame: frame)
        }
        
        func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
            view.eventViewer.frame = frame
            view.eventViewer.reloadFrame(frame: frame)
            return view.eventViewer
        }
        
        func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
            if let result = view.handleChangingEvent(event, start: start, end: end) {
                events.replaceSubrange(result.range, with: result.events)
            }
        }
        
        func didChangeViewerFrame(_ frame: CGRect) {
            view.eventViewer.reloadFrame(frame: frame)
        }
        
        func didAddNewEvent(_ event: Event, _ date: Date?) {
            if let newEvent = view.handleNewEvent(event, date: date) {
                events.append(newEvent)
            }
        }
        
        func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?) {
            updatedDate = dates.first ?? Date()
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
