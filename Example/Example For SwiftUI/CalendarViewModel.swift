//
//  CalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/17/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import KVKCalendar

@available(iOS 13.0, *)
final class CalendarViewModel: ObservableObject, KVKCalendarSettings, KVKCalendarDataModel {
    
    // 🤔👹🍻😬🥸
    var events: [Event] = []
    
    var style: KVKCalendar.Style {
        createCalendarStyle()
    }
    
    func loadEvents(completion: @escaping ([Event]) -> Void) {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
            self.loadEvents(dateFormat: self.style.timeSystem.format, completion: completion)
        }
    }
    
    func addNewEvent() -> Event? {
         handleNewEvent(Event(ID: "-1"), date: Date())
    }
    
}
