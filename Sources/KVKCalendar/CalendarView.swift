//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit
import EventKit

public final class CalendarView: UIView {
    
    struct Parameters {
        var type = CalendarType.day
        var style: Style
    }
    
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource? {
        didSet {
            dayView.reloadEventViewerIfNeeded()
        }
    }
    public var selectedType: CalendarType {
        parameters.type
    }
    
    let eventStore = EKEventStore()
    var parameters: Parameters
    
    private(set) var calendarData: CalendarData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    private let listData: ListViewData
    
    /// references the current visible View (to allow lazy loading of views)
    // cannot be private unfortunately, because private only allows access to extensions that are in the same file...
    internal lazy var currentViewCache: UIView? = nil
    
    private(set) lazy var dayView: DayView = {
        let day = DayView(parameters: .init(style: style, data: dayData, delegate: self, dataSource: self), frame: frame)
        day.scrollableWeekView.dataSource = self
        return day
    }()
    
    private(set) lazy var weekView: WeekView = {
        let week = WeekView(parameters: .init(data: weekData, style: style, delegate: self, dataSource: self), frame: frame)
        week.scrollableWeekView.dataSource = self
        return week
    }()
    
    private(set) lazy var monthView: MonthView = {
        let month = MonthView(parameters: .init(monthData: monthData, style: style), frame: frame)
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
    
    public init(frame: CGRect, date: Date? = nil, style: Style = Style(), years: Int = 4) {
        self.parameters = .init(type: style.defaultType ?? .day, style: style.checkStyle)
        self.calendarData = CalendarData(date: date ?? Date(), years: years, style: style)
        self.dayData = DayData(data: calendarData, startDay: style.startWeekDay)
        self.weekData = WeekData(data: calendarData,
                                 startDay: style.startWeekDay,
                                 maxDays: style.week.maxDays)
        self.monthData = MonthData(parameters: .init(data: calendarData,
                                                     startDay: style.startWeekDay,
                                                     calendar: style.calendar,
                                                     style: style))
        self.listData = ListViewData(data: calendarData)
        super.init(frame: frame)
        
        if let defaultType = style.defaultType {
            parameters.type = defaultType
        }
        
        set(type: parameters.type, date: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
