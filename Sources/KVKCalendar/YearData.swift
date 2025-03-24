//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 28.11.2020.
//

#if os(iOS)

import Foundation

final class YearData {
    
    struct YearSection {
        let date: Date
        var months: [Month]
    }

    let calendarData: CalendarData
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
        self.calendarData = data
        self.date = date
        self.style = style
        
        self.sections = data.months.reduce([], { (acc, month) -> [YearSection] in
            var accTemp = acc
            
            guard let idx = accTemp.firstIndex(where: { $0.date.kvkYear == month.date.kvkYear }) else {
                return accTemp + [YearSection(date: month.date, months: [month])]
            }
            
            accTemp[idx].months.append(month)
            return accTemp
        })
    }

    func reloadEventsInDays(events: [Event]) -> YearData {
        var calendarData = self.calendarData

        for section in self.sections {
            for month in section.months {
                let monthData = MonthData(
                    parameters: .init(
                        data: calendarData,
                        startDay: style.startWeekDay,
                        calendar: style.calendar,
                        style: style
                    )
                )
                _ = monthData.reloadEventsInDays(events: events, date: month.date)
                calendarData = monthData.data
            }
        }

        return YearData(data: calendarData, date: self.date, style: self.style)
    }
}

#endif
