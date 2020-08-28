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
    
    private lazy var dayView: DayView = {
        let day = DayView(data: dayData, frame: frame, style: style)
        day.delegate = self
        day.dataSource = self
        day.scrollHeaderDay.dataSource = self
        return day
    }()
    
    private lazy var weekView: WeekView = {
        let week = WeekView(data: weekData, frame: frame, style: style)
        week.delegate = self
        week.dataSource = self
        week.scrollHeaderDay.dataSource = self
        return week
    }()
    
    private lazy var monthView: MonthView = {
        let month = MonthView(data: monthData, frame: frame, style: style)
        month.delegate = self
        month.dataSource = self
        return month
    }()
    
    private lazy var yearView: YearView = {
        let year = YearView(data: monthData.data, frame: frame, style: style)
        year.delegate = self
        return year
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style.checkStyle
        self.yearData = YearData(date: date, years: years, style: style)
        self.dayData = DayData(yearData: yearData, timeSystem: style.timeHourSystem, startDay: style.startWeekDay)
        self.weekData = WeekData(yearData: yearData, timeSystem: style.timeHourSystem, startDay: style.startWeekDay)
        self.monthData = MonthData(yearData: yearData, startDay: style.startWeekDay, calendar: style.calendar)
        super.init(frame: frame)
        
        if let defaultType = style.defaultType {
            type = defaultType
        }
        set(type: type, date: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func switchTypeCalendar(type: CalendarType) {
        self.type = type
        subviews.filter({ $0 is DayView
            || $0 is WeekView
            || $0 is MonthView
            || $0 is YearView }).forEach({ $0.removeFromSuperview() })
        
        switch self.type {
        case .day:
            addSubview(dayView)
        case .week:
            addSubview(weekView)
        case .month:
            addSubview(monthView)
        case .year:
            addSubview(yearView)
        }
    }
    
    public func addEventViewToDay(view: UIView) {
        dayView.addEventView(view: view)
    }
    
    public func set(type: CalendarType, date: Date) {
        self.type = type
        switchTypeCalendar(type: type)
        scrollTo(date)
    }
    
    public func reloadData() {
        switch type {
        case .day:
            dayView.reloadData(events: events)
        case .week:
            weekView.reloadData(events: events)
        case .month:
            monthView.reloadData(events: events)
        case .year:
            break
        }
    }

    public func scrollTo(_ date: Date) {
        switch type {
        case .day:
            dayView.setDate(date)
        case .week:
            weekView.setDate(date)
        case .month:
            monthView.setDate(date)
        case .year:
            yearView.setDate(date)
        }
    }
}

extension CalendarView: DisplayDataSource {
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
    
    func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle? {
        return dataSource?.willDisplayDate(date, events: events)
    }
    
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? {
        return nil //dataSource?.willDisplayContextMenu(event, date: date)
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
    
    func didAddCalendarEvent(_ event: Event, _ date: Date?) {
        delegate?.didAddNewEvent(event, date)
    }
    
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?) {
        delegate?.didChangeEvent(event, start: start, end: end)
    }
    
    func getEventViewerFrame(_ frame: CGRect) {
        var newFrame = frame
        newFrame.origin = .zero
        delegate?.eventViewerFrame(newFrame)
    }
}

extension CalendarView: CalendarSettingProtocol {
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        dayView.reloadFrame(frame)
        weekView.reloadFrame(frame)
        monthView.reloadFrame(frame)
        yearView.reloadFrame(frame)
    }
    
    // TODO: in progress
    func updateStyle(_ style: Style) {
        self.style = style
        dayView.updateStyle(style)
        weekView.updateStyle(style)
        monthView.updateStyle(style)
        yearView.updateStyle(style)
    }
}
