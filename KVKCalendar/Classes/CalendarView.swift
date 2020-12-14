//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit
import EventKit

public final class CalendarView: UIView {
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource?
    public var selectedType: CalendarType {
        return type
    }
    
    let eventStore = EKEventStore()
    var type = CalendarType.day
    var style: Style
    
    private(set) var calendarData: CalendarData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    
    var systemEvents: [EKEvent] {
        guard !style.systemCalendars.isEmpty else { return [] }

        let systemCalendars = eventStore.calendars(for: .event).filter({ style.systemCalendars.contains($0.title) })
        guard !systemCalendars.isEmpty else { return [] }
        
        return getSystemEvents(eventStore: eventStore, calendars: systemCalendars)
    }
    
    private(set) lazy var dayView: DayView = {
        let day = DayView(data: dayData, frame: frame, style: style)
        day.delegate = self
        day.dataSource = self
        day.scrollHeaderDay.dataSource = self
        return day
    }()
    
    private(set) lazy var weekView: WeekView = {
        let week = WeekView(data: weekData, frame: frame, style: style)
        week.delegate = self
        week.dataSource = self
        week.scrollHeaderDay.dataSource = self
        return week
    }()
    
    private(set) lazy var monthView: MonthView = {
        let month = MonthView(data: monthData, frame: frame, style: style)
        month.delegate = self
        month.dataSource = self
        month.willSelectDate = { [weak self] (date) in
            self?.delegate?.willSelectDate(date, type: .month)
        }
        return month
    }()
    
    private(set) lazy var yearView: YearView = {
        let year = YearView(data: YearData(data: monthData.data, date: calendarData.date, style: style), frame: frame)
        year.delegate = self
        year.dataSource = self
        return year
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style.checkStyle
        self.calendarData = CalendarData(date: date, years: years, style: style)
        self.dayData = DayData(data: calendarData, timeSystem: style.timeSystem, startDay: style.startWeekDay)
        self.weekData = WeekData(data: calendarData, timeSystem: style.timeSystem, startDay: style.startWeekDay)
        self.monthData = MonthData(data: calendarData, startDay: style.startWeekDay, calendar: style.calendar, scrollDirection: style.month.scrollDirection)
        super.init(frame: frame)
        
        if let defaultType = style.defaultType {
            type = defaultType
        }
        
        set(type: type, date: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
