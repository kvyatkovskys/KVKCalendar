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

struct CalendarViewDisplayable: UIViewRepresentable, KVKCalendarSettings, KVKCalendarDataModel {
        
    @Binding var events: [Event]
    @Binding var type: CalendarType
    @Binding var updatedDate: Date?
    @Binding var orientation: UIInterfaceOrientation
    
    var selectDate = Date()

    private var calendar = KVKCalendarView(frame: .zero)
        
    func makeUIView(context: UIViewRepresentableContext<CalendarViewDisplayable>) -> KVKCalendarView {
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        return calendar
    }
    
    func updateUIView(_ uiView: KVKCalendarView, context: UIViewRepresentableContext<CalendarViewDisplayable>) {
        context.coordinator.events = events
        context.coordinator.type = type
        context.coordinator.updatedDate = updatedDate
        context.coordinator.orientation = orientation
    }
    
    func makeCoordinator() -> CalendarViewDisplayable.Coordinator {
        Coordinator(self)
    }
    
    public init(events: Binding<[Event]>,
                type: Binding<CalendarType>,
                updatedDate: Binding<Date?>,
                orientation: Binding<UIInterfaceOrientation>) {
        _events = events
        _type = type
        _updatedDate = updatedDate
        _orientation = orientation
        selectDate = defaultDate
        
        var frame: CGRect
#if targetEnvironment(macCatalyst)
        frame = CGRect(origin: .zero, size: UIApplication.shared.windowSize)
#else
        let offset = UIApplication.shared.screenOffset
        frame = UIScreen.main.bounds
        frame.size.height -= (offset.top + offset.bottom)
        frame.size.width -= (offset.right + offset.left)
#endif
        calendar = KVKCalendarView(frame: frame, date: selectDate, style: style)
    }
    
    // MARK: Calendar DataSource and Delegate
    final class Coordinator: NSObject, CalendarDataSource, CalendarDelegate {
        
        private var view: CalendarViewDisplayable
        private var eventViewer: EventViewer?
        
        var events: [Event] = [] {
            didSet {
                view.events = events
                view.calendar.reloadData()
            }
        }
        
        var type: CalendarType = .day {
            didSet {
                guard oldValue != type else { return }
                view.calendar.set(type: type, date: view.selectDate)
                view.calendar.reloadData()
            }
        }
        
        var updatedDate: Date? {
            didSet {
                if let date = updatedDate, oldValue != date {
                    view.calendar.scrollTo(date, animated: true)
                    view.selectDate = date
                    view.calendar.reloadData()
                }
            }
        }
        
        var orientation: UIInterfaceOrientation = .unknown {
            didSet {
                guard oldValue != orientation else { return }
                
                let offset = UIApplication.shared.screenOffset
                var frame = UIScreen.main.bounds
                frame.origin.y = 0
                frame.size.height -= (offset.top + offset.bottom)
                frame.size.width -= (offset.left + offset.right)
                view.calendar.reloadFrame(frame)
            }
        }
                
        init(_ view: CalendarViewDisplayable) {
            self.view = view
            super.init()
        }
        
        func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
            view.handleEvents(systemEvents: systemEvents)
        }
        
        func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
            view.handleCustomEventView(event: event, style: view.calendar.style, frame: frame)
        }
        
        func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
            if eventViewer == nil {
                eventViewer = EventViewer(frame: frame)
            } else {
                eventViewer?.frame = frame
            }
            return eventViewer
        }
        
        func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
            if let result = view.handleChangingEvent(event, start: start, end: end) {
                events.replaceSubrange(result.range, with: result.events)
            }
        }
        
        func didChangeViewerFrame(_ frame: CGRect) {
            eventViewer?.reloadFrame(frame: frame)
        }
        
        func didAddNewEvent(_ event: Event, _ date: Date?) {
            if let newEvent = view.handleNewEvent(event, date: date) {
                events.append(newEvent)
            }
        }
        
        func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?) {
            updatedDate = dates.first ?? Date()
        }
        
        @available(iOS 14.0, *)
        func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
            view.handleOptionMenu(type: type)
        }
        
        func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
            print(type, event)
            switch type {
            case .day:
                eventViewer?.text = event.title.timeline
            default:
                break
            }
        }
        
    }
}
