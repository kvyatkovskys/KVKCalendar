//
//  KVKCalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 5/8/23.
//

import SwiftUI
import Combine

@available(iOS 17.0, *)
@Observable final class KVKCalendarViewModel {
    
    var data: CalendarData
    var weekData: WeekNewData?
    var monthData: MonthData?
    var listData: ListView.Parameters?
    var date: Date
    var selectedEvent: Event?
    
    private var cancellable: Set<AnyCancellable> = []
    
    init(date: Date,
         events: [KVKCalendar.Event],
         selectedEvent: KVKCalendar.Event? = nil,
         years: Int = 4,
         style: Style) {
        self.date = date
        self.selectedEvent = selectedEvent
        
        data = CalendarData(date: date,
                            years: years,
                            style: style)
        weekData = WeekNewData(data: data, events: events)
        monthData = MonthData(parameters: MonthData.Parameters(data: data))
        listData = ListView.Parameters(data: ListViewData(data: data))
        
//        weekData?.$date
//            .removeDuplicates()
//            .sink { [weak self] (dt) in
//                self?.date = dt
//            }
//            .store(in: &cancellable)
    }
    
    func setDate(_ date: Date) {
        weekData?.date = date
    }
    
    func setEvents(_ events: [Event]) {
        weekData?.events = events
    }
    
}
