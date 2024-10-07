//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 28.11.2020.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
@Observable final class YearNewData {

    var date: Date
    var style: Style
    var sections: [YearSection]
    var scrollId: Int?
    
    init(monthData: MonthNewData) {
        date = monthData.date
        style = monthData.style
        sections = monthData.data.prepareYears(monthData.data.months)
    }
    
    func getScrollId() async {
        let id = sections.firstIndex(where: { $0.date.kvkYear == date.kvkYear })
        await MainActor.run {
            withAnimation {
                scrollId = id
            }
        }
    }
    
    func handleSelectedDate(_ date: Date) {
        let components = DateComponents(year: date.kvkYear, month: date.kvkMonth, day: self.date.kvkDay)
        let dt = style.calendar.date(from: components)
        self.date = dt ?? date
    }
}

final class YearData {
    
    var date: Date
    var style: Style
    var sections: [YearSection]
    let rowsInPage = 3
    let columnsInPage = 4
    var middleRowInPage: Int {
        (rowsInPage * columnsInPage) / 2
    }

    var itemsInPage: Int {
        columnsInPage * rowsInPage
    }
    
    init(data: CalendarData, date: Date, style: Style) {
        self.date = date
        self.style = style
        sections = data.prepareYears(data.months)
    }
    
    func handleSelectedDate(_ date: Date) {
        let components = DateComponents(year: date.kvkYear, month: date.kvkMonth, day: self.date.kvkDay)
        let dt = style.calendar.date(from: components)
        self.date = dt ?? date
    }
}

#endif
