//
//  AllDayEventModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

struct AllDayEvent {
    let date: Date
    let event: Event
    let xOffset: CGFloat
    let width: CGFloat
}

extension AllDayEvent: EventProtocol {
    
    func compare(_ event: Event) -> Bool {
        self.event.hash == event.hash
    }
    
}

protocol AllDayEventDelegate: AnyObject {
    
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?)
    
}

#endif
