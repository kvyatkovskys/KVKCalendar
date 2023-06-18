//
//  CalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/17/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar

final class CalendarViewModel: ObservableObject, KVKCalendarSettings, KVKCalendarDataModel {
    
    @Published var type = CalendarType.week
    @Published var orientation: UIInterfaceOrientation = .unknown
    @Published var events: [Event] = []
    @Published var date = Date()
    
    var style: Style {
        createCalendarStyle()
    }
    
    init() {
        _date = Published(initialValue: defaultDate)
    }
    
    func loadEvents() {
        Task {
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                loadEvents(dateFormat: style.timeSystem.format) { [weak self] (result) in
                    self?.events = result
                }
            }
        }
    }
    
    func addNewEvent() {
        guard let newEvent = handleNewEvent(Event(ID: "\(events.count + 1)"), date: date) else { return }
        events.append(newEvent)
    }
    
}
