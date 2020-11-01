//
//  CalendarContentView.swift
//  task_manager
//
//  Created by Sergei Kviatkovskii on 26.12.2019.
//  Copyright © 2019 Sergei Kviatkovskii. All rights reserved.
//

import SwiftUI
import KVKCalendar

@available(iOS 13.0, *)
struct CalendarDisplayView: UIViewRepresentable {
    
    private var calendar: CalendarView = {
        var frame = UIScreen.main.bounds
        frame.origin.y = 0
        frame.size.height -= 85
        
        let view = CalendarView(frame: frame, date: ViewController.selectDate, style: ViewController.style)
        let eventViewer = EventViewer(frame: CGRect(x: 0, y: 0, width: 500, height: view.frame.height))
        view.addEventViewToDay(view: eventViewer)
        return view
    }()
     
    func makeUIView(context: UIViewRepresentableContext<CalendarDisplayView>) -> CalendarView {
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        calendar.reloadData()
        return calendar
    }
    
    func updateUIView(_ uiView: CalendarView, context: UIViewRepresentableContext<CalendarDisplayView>) {
        
    }
    
    func makeCoordinator() -> CalendarDisplayView.Coordinator {
        Coordinator(self)
    }
    
    // MARK: Calendar DataSource and Delegate
    class Coordinator: NSObject, CalendarDataSource, CalendarDelegate {
        private let view: CalendarDisplayView
        private var events: [Event] = []
        
        init(_ view: CalendarDisplayView) {
            self.view = view
            super.init()
                        
            view.calendar.set(type: .week, date: ViewController.selectDate)
            
            ViewController().loadEvents { [weak self] (events) in
                self?.events = events
                self?.view.calendar.reloadData()
            }
        }
        
        func eventsForCalendar() -> [Event] {
            return events
        }
        
        @objc func addEvent() {
            
        }
        
        func didAddNewEvent(_ event: Event, _ date: Date?) {
            var newEvent = event
            guard let start = date, let end = Calendar.current.date(byAdding: .minute, value: 30, to: start) else { return }

            let startTime = timeFormatter(date: start)
            let endTime = timeFormatter(date: end)
            newEvent.start = start
            newEvent.end = end
            newEvent.ID = "\(events.count + 1)"
            newEvent.text = "\(startTime) - \(endTime)\n new event"
            events.append(newEvent)
            view.calendar.reloadData()
        }
        
        func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
            var eventTemp = event
            guard let startTemp = start, let endTemp = end else { return }
            
            let startTime = timeFormatter(date: startTemp)
            let endTime = timeFormatter(date: endTemp)
            eventTemp.start = startTemp
            eventTemp.end = endTemp
            eventTemp.text = "\(startTime) - \(endTime)\n new time"
            
            if let idx = events.firstIndex(where: { $0.compare(eventTemp) }) {
                events.remove(at: idx)
                events.append(eventTemp)
                view.calendar.reloadData()
            }
        }
        
        private func timeFormatter(date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
    }
}

@available(iOS 13.0, *)
struct CalendarContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarDisplayView()
    }
}
