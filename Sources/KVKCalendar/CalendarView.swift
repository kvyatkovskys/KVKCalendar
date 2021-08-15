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
    public weak var dataSource: CalendarDataSource? {
        didSet {
            dayView.reloadEventViewer()
        }
    }
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
    private let listData: ListViewData
    
    func getSystemEvents(store: EKEventStore, calendars: Set<String>, completion: @escaping ([EKEvent]) -> Void) {
        guard !calendars.isEmpty else {
            completion([])
            return
        }

        let systemCalendars = store.calendars(for: .event).filter({ calendars.contains($0.title) })
        guard !systemCalendars.isEmpty else {
            completion([])
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            self?.getSystemEvents(eventStore: store, calendars: systemCalendars) { (items) in
                DispatchQueue.main.async {
                    completion(items)
                }
            }
        }
    }
    
    /// references the current visible View (to allow lazy loading of views)
    // cannot be private unfortunately, because private only allows access to extensions that are in the same file...
    internal lazy var currentViewCache: UIView? = nil
    
    private(set) lazy var dayView: DayView = {
        let day = DayView(parameters: .init(style: style, data: dayData), frame: frame)
        day.dataSource = self
        day.delegate = self
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
    
    private(set) lazy var listView: ListView = {
        let params = ListView.Parameters(style: style, data: listData, dataSource: self, delegate: self)
        let list = ListView(parameters: params, frame: frame)
        return list
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style.checkStyle
        self.calendarData = CalendarData(date: date, years: years, style: style)
        self.dayData = DayData(data: calendarData, startDay: style.startWeekDay)
        self.weekData = WeekData(data: calendarData, startDay: style.startWeekDay)
        self.monthData = MonthData(parameters: .init(data: calendarData, startDay: style.startWeekDay, calendar: style.calendar, monthStyle: style.month))
        self.listData = ListViewData(data: calendarData)
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
