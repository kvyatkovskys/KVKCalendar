//
//  WeekData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI
import Combine
import Foundation

final class WeekData: ObservableObject, EventDateProtocol, ScrollableWeekProtocol {
    var days: [Day] = []
    @Published var date: Date
    @Published var timelineDays: [Date] = []
    @Published var allDayEvents: [Event] = []
    @Binding var selectedEvent: Event?
    var events: [Event] = []
    var recurringEvents: [Event] = []
    var weeks: [[Day]] = []
    
    @available(swift, deprecated: 0.6.13, renamed: "weeks")
    var daysBySection: [[Day]] = []
    
    private var cancellation: Set<AnyCancellable> = []
    
    init(data: CalendarData, startDay: StartDayType, maxDays: Int, selectedEvent: Binding<Event?> = .constant(nil)) {
        self.date = data.date
        _selectedEvent = selectedEvent
        reloadData(data, startDay: startDay, maxDays: maxDays)
        
        $date
            .map { [weak self] (dt) -> [Date] in
                (self?.getDaysByDate(dt) ?? []).compactMap { $0.date }
            }
            .assign(to: \.timelineDays, on: self)
            .store(in: &cancellation)
    }
    
    private func getIdxByDate(_ date: Date) -> Int? {
        weeks.firstIndex(where: { week in
            week.firstIndex(where: { $0.date?.kvkIsEqual(date) ?? false }) != nil
        })
    }
    
    private func getDaysByDate(_ date: Date) -> [Day] {
        guard let idx = getIdxByDate(date) else { return [] }
        return weeks[idx]
    }
    
    func filterEvents(_ events: [Event], dates: [Date]) -> [Event] {
        events.filter { (event) -> Bool in
            dates.contains(where: {
                compareStartDate($0, with: event)
                || compareEndDate($0, with: event)
                || checkMultipleDate($0, with: event)
            })
        }
    }
    
    func reloadData(_ data: CalendarData, startDay: StartDayType, maxDays: Int) {
        days = getDates(data: data, startDay: startDay, maxDays: maxDays)
        daysBySection = prepareDays(days, maxDayInWeek: maxDays)
        weeks = daysBySection
    }
    
    private func getDates(data: CalendarData, startDay: StartDayType, maxDays: Int) -> [Day] {
        var item = startDay
        if maxDays != 7 {
            item = .sunday
        }
        
        var tempDays = data.months.reduce([], { $0 + $1.days })
        let startIdx = tempDays.count > maxDays ? tempDays.count - maxDays : tempDays.count
        let endWeek = data.addEndEmptyDays(Array(tempDays[startIdx..<tempDays.count]), startDay: item)
        
        tempDays.removeSubrange(startIdx..<tempDays.count)
        let defaultDays = data.addStartEmptyDays(tempDays, startDay: item) + endWeek
        var extensionDays: [Day] = []
        
        if maxDays != 7,
           let indexOfInputDate = defaultDays.firstIndex(where: { $0.date?.kvkIsSameDay(otherDate: data.date) ?? false }),
           let firstDate = defaultDays.first?.date {
            let extraBufferDays = (defaultDays.count - indexOfInputDate) % maxDays
            if extraBufferDays > 0 {
                var i = extraBufferDays
                while (i > 0) {
                    if let newDate = firstDate.kvkAddingTo(.day, value: -1 * i) {
                        extensionDays.append(Day(type: .empty, date: newDate, data: []))
                    }
                    i -= 1
                }
            }
        }
        
        if extensionDays.isEmpty {
            return defaultDays
        } else {
            return extensionDays + defaultDays
        }
    }
}

#endif
