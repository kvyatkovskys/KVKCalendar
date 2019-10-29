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
        let newDate = convertDate(date)
        switchTypeCalendar(type: type)
        
        switch type {
        case .day:
            dayCalendar.setDate(newDate)
        case .week:
            weekCalendar.setDate(newDate)
        case .month:
            monthCalendar.setDate(newDate)
        case .year:
            yearCalendar.setDate(newDate)
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
            dayCalendar.setDate(newDate)
        case .week:
            weekCalendar.setDate(newDate)
        case .month:
            monthCalendar.setDate(newDate)
        case .year:
            yearCalendar.setDate(newDate)
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
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?) {
        delegate?.didSelectDate(date: date, type: type, frame: frame)
    }
    
    func didSelectCalendarEvents(_ events: [Event]) {
        //delegate?.didSelectEvents(events)
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

extension CalendarView: CalendarSettingProtocol {
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        dayCalendar.reloadFrame(frame)
        weekCalendar.reloadFrame(frame)
        monthCalendar.reloadFrame(frame)
        yearCalendar.reloadFrame(frame)
    }
    
    // work in progress
    func updateStyle(_ style: Style) {
        self.style = style
    }
}

public enum TimeHourSystem: Int {
    case twelveHour = 12
    case twentyFourHour = 24
    
    var hours: [String] {
        switch self {
        case .twelveHour:
            let array = ["12"] + Array(1...11).map({ String($0) })
            let am = array.map { $0 + " AM" } + ["Noon"]
            var pm = array.map { $0 + " PM" }
            
            pm.removeFirst()
            if let item = am.first {
                pm.append(item)
            }
            return am + pm
        case .twentyFourHour:
            let array = ["00:00"] + Array(1...24).map({ (i) -> String in
                let i = i % 24
                var string = i < 10 ? "0" + "\(i)" : "\(i)"
                string.append(":00")
                return string
            })
            return array
        }
    }
}

public enum CalendarType: String, CaseIterable {
    case day, week, month, year
}

public struct EventColor {
    let value: UIColor
    let alpha: CGFloat
    
    public init(_ color: UIColor, alpha: CGFloat = 0.3) {
        self.value = color
        self.alpha = alpha
    }
}

public struct Event {
    public var id: Any = 0
    public var text: String = ""
    public var start: Date = Date()
    public var end: Date = Date()
    public var color: EventColor? = nil {
        didSet {
            guard let valueColor = color else { return }
            backgroundColor = valueColor.value.withAlphaComponent(valueColor.alpha)
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            valueColor.value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            colorText = UIColor(hue: hue, saturation: saturation, brightness: UIScreen.isDarkMode ? brightness : brightness * 0.4, alpha: alpha)
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

protocol CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect)
    func updateStyle(_ style: Style)
    func setUI()
}

extension CalendarSettingProtocol {
    func setUI() {}
}

protocol CalendarPrivateDelegate: AnyObject {
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    //func didSelectCalendarEvents(_ events: [Event])
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?)
    func didSelectCalendarMore(_ date: Date, frame: CGRect?)
    func getEventViewerFrame(frame: CGRect)
}

extension CalendarPrivateDelegate {
    func getEventViewerFrame(frame: CGRect) {}
}

public protocol CalendarDataSource: AnyObject {
    func eventsForCalendar() -> [Event]
}

public protocol CalendarDelegate: AnyObject {
    func didSelectDate(date: Date?, type: CalendarType, frame: CGRect?)
    //func didSelectEvents(_ events: [Event])
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func eventViewerFrame(_ frame: CGRect)
}

public extension CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType, frame: CGRect?) {}
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    func eventViewerFrame(_ frame: CGRect) {}
}
