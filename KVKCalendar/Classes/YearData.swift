//
//  YearData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 28.11.2020.
//

import Foundation

final class YearData {
    
    struct YearSection {
        let date: Date
        var months: [Month]
    }
    
    var date: Date
    var style: Style
    let sections: [YearSection]
    
    init(data: CalendarData, date: Date, style: Style) {
        self.date = date
        self.style = style
        
        self.sections = data.months.reduce([], { (acc, month) -> [YearSection] in
            var accTemp = acc
            
            guard let idx = accTemp.firstIndex(where: { $0.date.year == month.date.year }) else {
                return accTemp + [YearSection(date: month.date, months: [month])]
            }
            
            accTemp[idx].months.append(month)
            return accTemp
        })
    }
}
