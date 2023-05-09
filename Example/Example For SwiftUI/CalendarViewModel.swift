//
//  CalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/17/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import KVKCalendar

final class CalendarViewModel: ObservableObject, KVKCalendarSettings, KVKCalendarDataModel {
    
    @Published var events: [Event] = []
    @Published var initialDate = Date()
    @Published var selectedDate: Date = Date()
    
    var style: KVKCalendar.Style {
        createCalendarStyle()
    }
    
    func loadEvents(completion: @escaping ([Event]) -> Void) {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) { [weak self] in
            self!.loadEvents(dateFormat: self!.style.timeSystem.format, completion: completion)
        }
    }
    
    func addNewEvent() -> Event? {
        handleNewEvent(Event(ID: "\(events.count + 1)"), date: Date())
    }
    
}
