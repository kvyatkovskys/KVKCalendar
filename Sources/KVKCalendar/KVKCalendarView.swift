//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit
import EventKit

@available(swift, deprecated: 0.6.11, obsoleted: 0.6.12, renamed: "KVKCalendarView")
public final class CalendarView: UIView {}

public final class KVKCalendarView: UIView {
    
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
    
    public private(set) var dayView: DayView
    private(set) var weekView: WeekView
    private(set) var monthView: MonthView
    private(set) var yearView: YearView
    private(set) var listView: ListView
    
    public convenience init(
        frame: CGRect = .zero,
        date: Date? = nil,
        style: Style = Style(),
        years: Int = 4
    ) {
        let calendarData = CalendarData(
            date: date ?? Date(),
            years: years,
            style: style.adaptiveStyle
        )
        self.init(
            frame: frame,
            date: date,
            style: style,
            calendarData: calendarData
        )
    }
    
    public convenience init<R: YearRange>(
        frame: CGRect = .zero,
        date: Date? = nil,
        style: Style = Style(),
        yearRange: R
    ) where R.Bound == Int {
        self.init(
            frame: frame,
            date: date,
            style: style,
            startYear: yearRange.lowerBound,
            endYear: yearRange.upperBound
        )
    }
    
    public convenience init(
        frame: CGRect = .zero,
        date: Date? = nil,
        style: Style = Style(),
        startYear: Int,
        endYear: Int
    ) {
        let calendarData = CalendarData(
            date: date ?? Date(),
            style: style.adaptiveStyle,
            startYear: startYear,
            endYear: endYear
        )
        self.init(
            frame: frame,
            date: date,
            style: style,
            calendarData: calendarData
        )
    }
    
    private init(
        frame: CGRect = .zero,
        date: Date?,
        style: Style,
        calendarData: CalendarData
    ) {
        let adaptiveStyle = style.adaptiveStyle
        self.parameters = .init(
            type: style.defaultType ?? .day,
            style: adaptiveStyle
        )
        self.calendarData = calendarData
        
        // day view
        self.dayData = DayData(
            data: calendarData,
            startDay: adaptiveStyle.startWeekDay
        )
        self.dayView = DayView(
            parameters: .init(
                style: adaptiveStyle,
                data: dayData
            ),
            frame: frame
        )
        
        // week view
        self.weekData = WeekData(
            data: calendarData,
            startDay: adaptiveStyle.startWeekDay,
            maxDays: adaptiveStyle.week.maxDays
        )
        self.weekView = WeekView(
            parameters: .init(
                data: weekData,
                style: adaptiveStyle
            ),
            frame: frame
        )
        
        // month view
        self.monthData = MonthData(
            parameters: .init(
                data: calendarData,
                startDay: adaptiveStyle.startWeekDay,
                calendar: adaptiveStyle.calendar,
                style: adaptiveStyle
            )
        )
        self.monthView = MonthView(
            parameters: .init(
                monthData: monthData,
                style: adaptiveStyle
            ),
            frame: frame
        )
        
        // year view
        self.yearData = YearData(
            data: monthData.data,
            date: calendarData.date,
            style: adaptiveStyle
        )
        self.yearView = YearView(
            data: yearData,
            frame: frame
        )
        
        // list view
        self.listData = ListViewData(
            data: calendarData,
            style: adaptiveStyle
        )
        let params = ListView.Parameters(
            style: adaptiveStyle,
            data: listData
        )
        self.listView = ListView(
            parameters: params,
            frame: frame
        )
        
        super.init(frame: frame)
        setup(with: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(with date: Date?) {
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
        
        if let defaultType = style.adaptiveStyle.defaultType {
            parameters.type = defaultType
        }
        set(type: parameters.type, date: date)
        reloadAllStyles(style.adaptiveStyle, force: true)
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        reloadFrame(bounds)
    }
}
#endif
