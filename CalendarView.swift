//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

protocol CalendarSelectDateDelegate: AnyObject {
    func didSelectCalendarDate(_ date: Date?, type: CalendarType)
    func didSelectCalendarEvents(_ events: [Event])
    func didSelectCalendarEvent(_ event: Event)
}

public protocol CalendarDelegate: AnyObject {
    func didSelectDate(date: Date?, type: CalendarType)
    func eventsForCalendar() -> [Event]
    func didSelectEvents(_ events: [Event])
    func didSelectEvent(_ event: Event, type: CalendarType)
}

public extension CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType) {}
    func didSelectEvents(_ events: [Event]) {}
    func didSelectEvent(_ event: Event, type: CalendarType) {}
}

public final class CalendarView: UIView, CalendarSelectDateDelegate {
    public weak var delegate: CalendarDelegate?
    var timeHourSystem: TimeHourSystem = .twentyFourHour
    
    public let style: Style
    fileprivate var calendarType = CalendarType.day
    fileprivate var yearData: YearData
    fileprivate var weekData: WeekData
    fileprivate let monthData: MonthData
    fileprivate var dayData: DayData
    
    fileprivate lazy var dayCalendar: DayViewCalendar = {
        let day = DayViewCalendar(data: dayData, frame: frame, style: style)
        day.delegate = self
        return day
    }()
    
    fileprivate lazy var weekCalendar: WeekViewCalendar = {
        let week = WeekViewCalendar(data: weekData, frame: frame, style: style)
        week.delegate = self
        return week
    }()
    
    fileprivate lazy var monthCalendar: MonthViewCalendar = {
        let month = MonthViewCalendar(data: monthData, frame: frame, style: style)
        month.delegate = self
        return month
    }()
    
    fileprivate lazy var yearCalendar: YearViewCalendar = {
        let year = YearViewCalendar(data: yearData, frame: frame, style: style)
        year.delegate = self
        return year
    }()
    
    public init(date: Date = Date(), frame: CGRect, style: Style = Style(), years: Int = 4) {
        self.style = style
        self.yearData = YearData(date: date, years: years, style: style)
        self.dayData = DayData(yearData: yearData, timeSystem: timeHourSystem)
        self.weekData = WeekData(yearData: yearData, timeSystem: timeHourSystem)
        self.monthData = MonthData(yearData: yearData)
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func switchTypeCalendar(type: CalendarType) {
        calendarType = type
        subviews.filter({ $0 is DayViewCalendar
            || $0 is WeekViewCalendar
            || $0 is MonthViewCalendar
            || $0 is YearViewCalendar }).forEach({ $0.removeFromSuperview() })
        
        switch type {
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
        calendarType = type
        switchTypeCalendar(type: type)
        
        switch type {
        case .day:
            dayCalendar.setDate(date: date)
        case .week:
            weekCalendar.setDate(date: date)
        case .month:
            monthCalendar.setDate(date: date)
        default:
            yearCalendar.setDate(date: date)
        }
    }
    
    public func reloadData() {
        switch calendarType {
        case .day:
            dayCalendar.reloadData(events: delegate?.eventsForCalendar() ?? [])
        case .week:
            weekCalendar.reloadData(events: delegate?.eventsForCalendar() ?? [])
        case .month:
            monthCalendar.reloadData(events: delegate?.eventsForCalendar() ?? [])
        case .year:
            break
        }
    }
    
    public func scrollToDate(date: Date) {
        switch calendarType {
        case .day:
            dayCalendar.setDate(date: date)
        case .week:
            weekCalendar.setDate(date: date)
        case .month:
            monthCalendar.setDate(date: date)
        case .year:
            yearCalendar.setDate(date: date)
        }
    }
    
    // MARK: delegate selected calendar
    func didSelectCalendarDate(_ date: Date?, type: CalendarType) {
        delegate?.didSelectDate(date: date, type: type)
    }
    
    func didSelectCalendarEvents(_ events: [Event]) {
        delegate?.didSelectEvents(events)
    }
    
    func didSelectCalendarEvent(_ event: Event) {
        delegate?.didSelectEvent(event, type: calendarType)
    }
}

enum TimeHourSystem: Int {
    case twelveHour = 12
    case twentyFourHour = 24
    
    var hours: [String] {
        switch self {
        case .twelveHour:
            var array = [String]()
            
            for idx in 0...11 {
                if idx == 0 {
                    array.append("12")
                } else {
                    let string = String(idx)
                    array.append(string)
                }
            }
            var am = array.map { $0 + " AM" }
            var pm = array.map { $0 + " PM" }
            
            am.append("Noon")
            pm.removeFirst()
            pm.append(am.first!)
            
            return am + pm
        case .twentyFourHour:
            var array = [String]()
            
            for i in 0...24 {
                if i == 0 {
                    array.append("00:00")
                } else {
                    let i = i % 24
                    var string = i < 10 ? "0" + "\(i)" : "\(i)"
                    string.append(":00")
                    array.append(string)
                }
            }
            
            return array
        }
    }
}

public enum CalendarType: String, CaseIterable {
    case day, week, month, year
}

