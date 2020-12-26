//
//  ListViewData.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

import Foundation

final class ListViewData {
    
    struct SectionListView {
        let date: Date
        var events: [Event]
    }
    
    var sections: [SectionListView]
    var date: Date
    
    init(data: CalendarData) {
        self.date = data.date
        self.sections = []
    }
    
    func reloadEvents(_ events: [Event]) {
        sections = events.reduce([], { (acc, event) -> [SectionListView] in
            var accTemp = acc
            
            guard let idx = accTemp.firstIndex(where: { $0.date.year == event.start.year && $0.date.month == event.start.month && $0.date.day == event.start.day }) else {
                return accTemp + [SectionListView(date: event.start, events: [event])]
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

