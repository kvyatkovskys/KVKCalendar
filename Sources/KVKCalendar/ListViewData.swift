//
//  ListViewData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

import Foundation

public final class ListViewData {
    
    public struct SectionListView {
        let date: Date
        var events: [Event]
        
        public init(date: Date, events: [Event]) {
            self.date = date
            self.events = events
        }
    }
    
    var sections: [SectionListView]
    var date: Date
    
    init(data: CalendarData) {
        self.date = data.date
        self.sections = []
    }
    
    public init(date: Date, sections: [SectionListView]) {
        self.date = date
        self.sections = sections
    }
    
    func titleOfHeader(section: Int, formatter: DateFormatter, locale: Locale) -> String {
        let dateSection = sections[section].date
        formatter.locale = locale
        return formatter.string(from: dateSection)
    }
    
    func reloadEvents(_ events: [Event]) {
        sections = events.reduce([], { (acc, event) -> [SectionListView] in
            var accTemp = acc
            
            guard let idx = accTemp.firstIndex(where: { $0.date.year == event.start.year && $0.date.month == event.start.month && $0.date.day == event.start.day }) else {
                accTemp += [SectionListView(date: event.start, events: [event])]
                accTemp = accTemp.sorted(by: { $0.date < $1.date })
                return accTemp
            }
            
            accTemp[idx].events.append(event)
            accTemp[idx].events = accTemp[idx].events.sorted(by: { $0.start < $1.start })
            return accTemp
        })
    }
    
    func event(indexPath: IndexPath) -> Event {
        return sections[indexPath.section].events[indexPath.row]
    }
    
    func numberOfSection() -> Int {
        return sections.count
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        return sections[section].events.count
    }
    
}

