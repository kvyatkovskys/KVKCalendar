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
    
    var type: CalendarType
    var data: CalendarData
    var weekData: WeekNewData?
    var dayData: WeekNewData?
    var monthData: MonthNewData?
    var yearData: YearNewData?
    var listData: ListView.Parameters?
    var date: Date {
        didSet {
            setDate(date)
        }
    }
    var selectedEvent: Event?
    
    private var cancellable: Set<AnyCancellable> = []
    
    init(type: CalendarType,
         date: Date,
         events: [KVKCalendar.Event],
         selectedEvent: KVKCalendar.Event? = nil,
         years: Int = 4,
         style: Style) {
        self.type = type
        self.date = date
        self.selectedEvent = selectedEvent
        
        data = CalendarData(date: date, years: years, style: style)
        dayData = WeekNewData(data: data, events: events, type: .day)
        weekData = WeekNewData(data: data, events: events, type: .week)
        monthData = MonthNewData(data: data)
        // listData = ListView.Parameters(data: ListViewData(data: data))
    }
    
    func setDate(_ date: Date) {
        dayData?.date = date
        weekData?.date = date
        
    }
    
    func setEvents(_ events: [Event]) {
        weekData?.events = events
    }
    
}
