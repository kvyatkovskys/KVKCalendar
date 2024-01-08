//
//  CalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/17/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar

@available(iOS 17.0, *)
@Observable final class CalendarViewModel: KVKCalendarSettings, KVKCalendarDataModel {
    
    var type = CalendarType.week
    var orientation: UIInterfaceOrientation = .unknown
    var events: [Event] = []
    var date = Date()
    var selectedEvent: KVKCalendar.Event?
    
    var style: Style {
        createCalendarStyle()
    }
    
    init() {
        date = defaultDate
    }
    
    func loadEvents() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let result = await loadEvents(dateFormat: style.timeSystem.format)
        await MainActor.run {
            events = result
        }
    }
    
    func addNewEvent() {
        var components = DateComponents(year: date.kvkYear, month: date.kvkMonth, day: date.kvkDay)
        components.minute = date.kvkMinute + 30
        guard let newEvent = handleNewEvent(Event(ID: "\(events.count + 1)"), date: components.date ?? date) else { return }
        events.append(newEvent)
    }
    
}
