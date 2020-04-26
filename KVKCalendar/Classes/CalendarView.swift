//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

public final class CalendarView: UIView {
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource?
    public var selectedType: CalendarType {
        return type
    }
    
    private var style: Style
    private var type = CalendarType.day
    private var yearData: YearData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    private var events: [Event] {
        return dataSource?.eventsForCalendar() ?? []
    }
    
    private lazy var dayCalendar: DayViewCalendar = {
        let day = DayViewCalendar(data: dayData, frame: frame, style: style)
        day.delegate = self
        return day
    }()
    
    private lazy var weekCalendar: WeekViewCalendar = {
        let week = WeekViewCalendar(data: weekData, frame: frame, style: style)
        week.delegate = self
        return week
    }()
    
    private lazy var monthCalendar: MonthViewCalendar = {
        let month = MonthViewCalendar(data: monthData, frame: frame, style: style)
        month.delegate = self
        month.dataSource = self
        return month
    }()
    
    private lazy var yearCalendar: YearViewCalendar = {
        let year = YearViewCalendar(data: monthData.data, frame: frame, style: style)
        year.delegate = self
        return year
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style.checkStyle
        self.yearData = YearData(date: date, years: years, style: style)
        self.dayData = DayData(yearData: yearData, timeSystem: style.timeHourSystem, startDay: style.startWeekDay)
        self.weekData = WeekData(yearData: yearData, timeSystem: style.timeHourSystem, startDay: style.startWeekDay)
        self.monthData = MonthData(yearData: yearData, startDay: style.startWeekDay)
        super.init(frame: frame)
        
        if let defaultType = style.defaultType {
            type = defaultType
            set(type: type, date: date)
        } else {
            set(type: type, date: date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func switchTypeCalendar(type: CalendarType) {
        self.type = type
        if UIDevice.current.userInterfaceIdiom == .phone && type == .year {
            self.type = .month
        }
        subviews.filter({ $0 is DayViewCalendar
            || $0 is WeekViewCalendar
            || $0 is MonthViewCalendar
            || $0 is YearViewCalendar }).forEach({ $0.removeFromSuperview() })
        
        switch self.type {
        case .day:
            addSubview(dayCalendar)
        case .week:
            addSubview(weekCalendar)
        case .month:
            addSubview(monthCalendar)
        case .year:
            addSubview(yearCalendar)
        }
    }
    
    public func addEventViewToDay(view: UIView) {
        dayCalendar.addEventView(view: view)
    }
    
    public func set(type: CalendarType, date: Date) {
        self.type = type
        switchTypeCalendar(type: type)
        scrollTo(date)
    }
    
    public func reloadData() {
        switch type {
        case .day:
            dayCalendar.reloadData(events: events)
        case .week:
            weekCalendar.reloadData(events: events)
        case .month:
            monthCalendar.reloadData(events: events)
        case .year:
            break
        }
    }
    
    @available(*, deprecated, renamed: "scrollTo")
    public func scrollToDate(date: Date) {
        switch type {
        case .day:
            dayCalendar.setDate(date)
        case .week:
            weekCalendar.setDate(date)
        case .month:
            monthCalendar.setDate(date)
        case .year:
            yearCalendar.setDate(date)
        }
    }
    
    public func scrollTo(_ date: Date) {
        switch type {
        case .day:
            dayCalendar.setDate(date)
        case .week:
            weekCalendar.setDate(date)
        case .month:
            monthCalendar.setDate(date)
        case .year:
            yearCalendar.setDate(date)
        }
    }
}

extension CalendarView: MonthDataSource {
    public func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle? {
        return dataSource?.willDisplayDate(date, events: events)
    }
}

extension CalendarView: CalendarPrivateDelegate {
    func didDisplayCalendarEvents(_ events: [Event], dates: [Date?], type: CalendarType) {
        guard self.type == type else { return }
        
        delegate?.didDisplayEvents(events, dates: dates)
    }
    
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?) {
        delegate?.didSelectDate(date, type: type, frame: frame)
    }
    
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: type, frame: frame)
    }
    
    func didSelectCalendarMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectMore(date, frame: frame)
    }
    
    func didAddCalendarEvent(_ date: Date?) {
        delegate?.didAddEvent(date)
    }
    
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?) {
        delegate?.didChangeEvent(event, start: start, end: end)
    }
    
    func calendarEventViewerFrame(_ frame: CGRect) {
        var newFrame = frame
        newFrame.origin = .zero
        delegate?.eventViewerFrame(newFrame)
    }
}

extension CalendarView: CalendarSettingProtocol {
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        dayCalendar.reloadFrame(frame)
        weekCalendar.reloadFrame(frame)
        monthCalendar.reloadFrame(frame)
        yearCalendar.reloadFrame(frame)
    }
    
    // TODO: in progress
    func updateStyle(_ style: Style) {
        self.style = style
        dayCalendar.updateStyle(style)
        weekCalendar.updateStyle(style)
        monthCalendar.updateStyle(style)
        yearCalendar.updateStyle(style)
    }
}
