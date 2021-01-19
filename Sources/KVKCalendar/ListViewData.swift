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
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    init(data: CalendarData) {
        self.date = data.date
        self.sections = []
    }
    
    func titleOfHeader(section: Int) -> String {
        let dateSection = sections[section].date
        return dateFormatter.string(from: dateSection)
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

