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
    
    private let style: Style
    private var type = CalendarType.day
    private var yearData: YearData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    
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
        return month
    }()
    
    private lazy var yearCalendar: YearViewCalendar = {
        let year = YearViewCalendar(data: yearData, frame: frame, style: style)
        year.delegate = self
        return year
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style
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
        let newDate = convertDate(date)
        switchTypeCalendar(type: type)
        
        switch type {
        case .day:
            dayCalendar.setDate(date: newDate)
        case .week:
            weekCalendar.setDate(date: newDate)
        case .month:
            monthCalendar.setDate(date: newDate)
        case .year:
            yearCalendar.setDate(date: newDate)
        }
    }
    
    public func reloadData() {
        switch type {
        case .day:
            dayCalendar.reloadData(events: dataSource?.eventsForCalendar() ?? [])
        case .week:
            weekCalendar.reloadData(events: dataSource?.eventsForCalendar() ?? [])
        case .month:
            monthCalendar.reloadData(events: dataSource?.eventsForCalendar() ?? [])
        case .year:
            break
        }
    }
    
    public func scrollToDate(date: Date) {
        let newDate = convertDate(date)
        
        switch type {
        case .day:
            dayCalendar.setDate(date: newDate)
        case .week:
            weekCalendar.setDate(date: newDate)
        case .month:
            monthCalendar.setDate(date: newDate)
        case .year:
            yearCalendar.setDate(date: newDate)
        }
    }
    
    private func convertDate(_ date: Date) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: "\(date.year)-\(date.month)-\(date.day)") ?? date
    }
}

extension CalendarView: CalendarPrivateDelegate {
    func didSelectCalendarDate(_ date: Date?, type: CalendarType) {
        delegate?.didSelectDate(date: date, type: type)
    }
    
    func didSelectCalendarEvents(_ events: [Event]) {
        delegate?.didSelectEvents(events)
    }
    
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: type, frame: frame)
    }
    
    func didSelectCalendarMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectMore(date, frame: frame)
    }
    
    func getEventViewerFrame(frame: CGRect) {
        var newFrame = frame
        newFrame.origin = .zero
        delegate?.eventViewerFrame(newFrame)
    }
}

extension CalendarView: CalendarFrameProtocol {
    public func reloadFrame(frame: CGRect) {
        self.frame = frame
        dayCalendar.reloadFrame(frame: frame)
        weekCalendar.reloadFrame(frame: frame)
        monthCalendar.reloadFrame(frame: frame)
        yearCalendar.reloadFrame(frame: frame)
    }
}
