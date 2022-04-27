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
    private(set) var monthData: MonthData
    private var dayData: DayData
    private(set) var yearData: YearData
    private let listData: ListViewData
    
    private(set) var dayView: DayView
    private(set) var weekView: WeekView
    private(set) var monthView: MonthView
    private(set) var yearView: YearView
    private(set) var listView: ListView
    
    public init(frame: CGRect, date: Date? = nil, style: Style = Style(), years: Int = 4) {
        let adaptiveStyle = style.adaptiveStyle
        self.parameters = .init(type: style.defaultType ?? .day, style: adaptiveStyle)
        self.calendarData = CalendarData(date: date ?? Date(), years: years, style: adaptiveStyle)
        
        // day view
        self.dayData = DayData(data: calendarData, startDay: adaptiveStyle.startWeekDay)
        self.dayView = DayView(parameters: .init(style: adaptiveStyle, data: dayData), frame: frame)
        
        // week view
        self.weekData = WeekData(data: calendarData,
                                 startDay: adaptiveStyle.startWeekDay,
                                 maxDays: adaptiveStyle.week.maxDays)
        self.weekView = WeekView(parameters: .init(data: weekData, style: adaptiveStyle), frame: frame)
        
        // month view
        self.monthData = MonthData(parameters: .init(data: calendarData,
                                                     startDay: adaptiveStyle.startWeekDay,
                                                     calendar: adaptiveStyle.calendar,
                                                     style: adaptiveStyle))
        self.monthView = MonthView(parameters: .init(monthData: monthData, style: adaptiveStyle), frame: frame)
        
        // year view
        self.yearData = YearData(data: monthData.data, date: calendarData.date, style: adaptiveStyle)
        self.yearView = YearView(data: yearData, frame: frame)
        
        // list view
        self.listData = ListViewData(data: calendarData)
        let params = ListView.Parameters(style: adaptiveStyle, data: listData)
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
        
        if let defaultType = adaptiveStyle.defaultType {
            parameters.type = defaultType
        }
        set(type: parameters.type, date: date)
        reloadAllStyles(adaptiveStyle, force: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateDaysBySectionInWeekView(date: Date? = nil) {
        weekView.updateDaysBySection(date: date)
    }
}

#endif
