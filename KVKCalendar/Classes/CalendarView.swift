//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

protocol CalendarFrameDelegate {
    func reloadFrame(frame: CGRect)
}

protocol CalendarSelectDateDelegate: AnyObject {
    func didSelectCalendarDate(_ date: Date?, type: CalendarType)
    func didSelectCalendarEvents(_ events: [Event])
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?)
    func didSelectCalendarMore(_ date: Date, frame: CGRect?)
}

public protocol CalendarDataSource: AnyObject {
    func eventsForCalendar() -> [Event]
}

public protocol CalendarDelegate: AnyObject {
    func didSelectDate(date: Date?, type: CalendarType)
    func didSelectEvents(_ events: [Event])
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
}

public extension CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType) {}
    func didSelectEvents(_ events: [Event]) {}
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    func didSelectMore(_ date: Date, frame: CGRect?) {}
}

public final class CalendarView: UIView {
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource?
    public var selectedType: CalendarType {
        return type
    }
    
    fileprivate let style: Style
    fileprivate var type = CalendarType.day
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
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4, timeHourSystem: TimeHourSystem = .twentyFourHour) {
        self.style = style
        self.yearData = YearData(date: date, years: years, style: style)
        self.dayData = DayData(yearData: yearData, timeSystem: timeHourSystem)
        self.weekData = WeekData(yearData: yearData, timeSystem: timeHourSystem)
        self.monthData = MonthData(yearData: yearData)
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
    
    fileprivate func switchTypeCalendar(type: CalendarType) {
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
        
        switch type {
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
        switch type {
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
}

extension CalendarView: CalendarSelectDateDelegate {
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
}

extension CalendarView: CalendarFrameDelegate {
    public func reloadFrame(frame: CGRect) {
        self.frame = frame
        dayCalendar.reloadFrame(frame: frame)
        weekCalendar.reloadFrame(frame: frame)
        monthCalendar.reloadFrame(frame: frame)
        yearCalendar.reloadFrame(frame: frame)
    }
}

public enum TimeHourSystem: Int {
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

public struct Event {
    public var id: Any = 0
    public var text: String = ""
    public var start: Date = Date()
    public var end: Date = Date()
    public var color: UIColor? = nil {
        didSet {
            guard let color = color else { return }
            backgroundColor = color.withAlphaComponent(0.3)
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            colorText = UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.4, alpha: alpha)
        }
    }
    public var backgroundColor: UIColor = UIColor.blue.withAlphaComponent(0.3)
    public var colorText: UIColor = .black
    public var isAllDay: Bool = false
    public var isContainsFile: Bool = false
    public var textForMonth: String = ""
    public var eventData: Any?
    
    public init() {}
}

