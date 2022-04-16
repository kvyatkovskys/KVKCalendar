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
    /// references the current visible Views
    var viewCaches: [CalendarType: UIView] = [:]
    
    private(set) var calendarData: CalendarData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    private let listData: ListViewData
    
    private(set) var dayView: DayView
    private(set) var weekView: WeekView
    private(set) var monthView: MonthView
    private(set) var yearView: YearView
    private(set) var listView: ListView
    
    public init(frame: CGRect, date: Date? = nil, style: Style = Style(), years: Int = 4) {
        self.parameters = .init(type: style.defaultType ?? .day, style: style.adaptiveStyle)
        self.calendarData = CalendarData(date: date ?? Date(), years: years, style: style)
        
        // day view
        self.dayData = DayData(data: calendarData, startDay: style.startWeekDay)
        self.dayView = DayView(parameters: .init(style: style, data: dayData), frame: frame)
        
        // week view
        self.weekData = WeekData(data: calendarData,
                                 startDay: style.startWeekDay,
                                 maxDays: style.week.maxDays)
        self.weekView = WeekView(parameters: .init(data: weekData, style: style), frame: frame)
        
        // month view
        self.monthData = MonthData(parameters: .init(data: calendarData,
                                                     startDay: style.startWeekDay,
                                                     calendar: style.calendar,
                                                     style: style))
        self.monthView = MonthView(parameters: .init(monthData: monthData, style: style), frame: frame)
        
        // year view
        self.yearView = YearView(data: YearData(data: monthData.data, date: calendarData.date, style: style), frame: frame)
        
        // list view
        self.listData = ListViewData(data: calendarData)
        let params = ListView.Parameters(style: style, data: listData)
        self.listView = ListView(parameters: params, frame: frame)
        
        super.init(frame: frame)
        
        dayView.scrollableWeekView.dataSource = self
        dayView.dataSource = self
        dayView.delegate = self
        
        weekView.scrollableWeekView.dataSource = self
        weekView.dataSource = self
        weekView.delegate = self
        
        monthView.delegate = self
        monthView.dataSource = self
        monthView.willSelectDate = { [weak self] (date) in
            self?.delegate?.willSelectDate(date, type: .month)
        }
        
        yearView.delegate = self
        yearView.dataSource = self
        
        listView.dataSource = self
        listView.delegate = self
        
        viewCaches = [.day: dayView, .week: weekView, .month: monthView, .year: yearView, .list: listView]
        
        if let defaultType = style.defaultType {
            parameters.type = defaultType
        }
        set(type: parameters.type, date: date)
        updateStyle(style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
