//
//  KVKCalendarViewModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 5/8/23.
//

import Foundation
import SwiftUI
import Combine

open class KVKCalendarViewModel: ObservableObject {
    
    var data: CalendarData
    @Published public var type: CalendarType
    @ObservedObject var weekData: WeekData
    @ObservedObject var dayData: WeekData
    @Published public var date: Date
    
    private var cancellable: Set<AnyCancellable> = []
    
    public init(date: Date,
                years: Int = 4,
                style: Style,
                type: CalendarType = .week) {
        self.date = date
        data = CalendarData(date: date,
                            years: years,
                            style: style)
        weekData = WeekData(data: data)
        dayData = WeekData(data: data, type: .day)
        self.type = type
        
        weekData.$date
            .removeDuplicates()
            .assign(to: \.date, on: self)
            .store(in: &cancellable)
        dayData.$date
            .removeDuplicates()
            .assign(to: \.date, on: self)
            .store(in: &cancellable)
    }
    
    public func setDate(_ date: Date) {
        weekData.date = date
    }
    
}
