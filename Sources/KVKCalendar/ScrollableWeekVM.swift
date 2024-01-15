//
//  ScrollableWeekVM.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 1/14/24.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
@Observable final class ScrollableWeekVM: EventDateProtocol, ScrollableWeekProtocol {
    var didSelectDate: ((Date) -> Void)?
    var style: Style
    var date: Date {
        didSet {
            didSelectDate?(date)
        }
    }
    var weeks: [[Day]] = []
    var scrollId: Int?
    var isAutoScrolling = false
    var type: CalendarType
    
    var daySize: CGSize {
        Platform.currentInterface == .phone ? CGSize(width: 40, height: 40) : CGSize(width: 30, height: 70)
    }
    var spacing: CGFloat {
        Platform.currentInterface == .phone ? 5 : 0
    }
    var leftPadding: CGFloat {
        type == .week ? style.timeline.widthTime + style.timeline.offsetTimeX : 0
    }
    var dayShortFormatter: DateFormatter {
        let format = DateFormatter()
        format.dateFormat = "EEEEE"
        return format
    }
    var todayTitle: String {
        "Today"
    }
        
    init(data: CalendarData, type: CalendarType) {
        date = data.date
        style = data.style
        self.type = type
        weeks = reloadData(data,
                           type: type,
                           startDay: data.style.startWeekDay,
                           maxDays: data.style.week.maxDays).weeks
    }
    
    func setup() async {
        await MainActor.run {
            scrollToDate(date, enableAutoScrolling: true)
        }
    }
}

#endif
