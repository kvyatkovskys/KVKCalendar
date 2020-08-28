//
//  CalendarModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 25.02.2020.
//

import UIKit

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
    
    public var format: String {
        switch self {
        case .twelveHour:
            return "h:mm a"
        case .twentyFourHour:
            return "HH:mm"
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
    static let idForNewEvent = "-999"
    
    public var ID: String
    public var text: String
    public var start: Date
    public var end: Date
    public var color: EventColor? {
        didSet {
            guard let tempColor = color else { return }
            
            let value = prepareColor(tempColor)
            backgroundColor = value.background
            textColor = value.text
        }
    }
    public var backgroundColor: UIColor
    @available(swift, deprecated: 0.3.5, obsoleted: 0.3.6, message: "This will be removed in v0.3.6, please migrate to a `textColor`", renamed: "textColor")
    public var colorText: UIColor = .black
    public var textColor: UIColor
    public var isAllDay: Bool
    public var isContainsFile: Bool
    public var textForMonth: String
    public var eventData: Any?
    public var recurringType: RecurringType
    
    public init(ID: String = "0", text: String = "", start: Date = Date(), end: Date = Date(), color: EventColor? = EventColor(UIColor.systemBlue), backgroundColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3), textColor: UIColor = .white, isAllDay: Bool = false, isContainsFile: Bool = false, textForMonth: String = "", eventData: Any? = nil, recurringType: RecurringType = .none) {
        self.ID = ID
        self.text = text
        self.start = start
        self.end = end
        self.color = color
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isAllDay = isAllDay
        self.isContainsFile = isContainsFile
        self.textForMonth = textForMonth
        self.eventData = eventData
        self.recurringType = recurringType
        
        guard let tempColor = color else { return }
        
        let value = prepareColor(tempColor)
        self.backgroundColor = value.background
        self.textColor = value.text
    }
    
    func prepareColor(_ color: EventColor) -> (background: UIColor, text: UIColor) {
        let bgColor = color.value.withAlphaComponent(color.alpha)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let txtColor = UIColor(hue: hue, saturation: saturation, brightness: UIScreen.isDarkMode ? brightness : brightness * 0.4, alpha: alpha)
        
        return (bgColor, txtColor)
    }
}

extension Event {
    var hash: Int {
        return ID.hashValue
    }
    
    var isNew: Bool {
        return ID == Event.idForNewEvent
    }
}

public enum RecurringType: Int {
    case everyDay, everyWeek, everyMonth, everyYear, none
}

extension Event: EventProtocol {
    public func compare(_ event: Event) -> Bool {
        return hash == event.hash
    }
}

extension Event {
    func updateDate(newDate: Date?, calendar: Calendar = Calendar.current) -> Event? {
        var startComponents = DateComponents()
        startComponents.year = start.year
        startComponents.month = start.month
        startComponents.hour = start.hour
        startComponents.minute = start.minute
        
        var endComponents = DateComponents()
        endComponents.year = end.year
        endComponents.month = end.month
        endComponents.hour = end.hour
        endComponents.minute = end.minute
        
        switch recurringType {
        case .everyDay:
            startComponents.day = newDate?.day
        case .everyWeek where newDate?.weekday == start.weekday:
            startComponents.day = newDate?.day
            startComponents.weekday = newDate?.weekday
            
            endComponents.weekday = newDate?.weekday
        case .everyMonth where newDate?.month != start.month && newDate?.day == start.day:
            startComponents.day = newDate?.day
            startComponents.month = newDate?.month
            
            endComponents.month = newDate?.month
        case .everyYear where newDate?.year != start.year && newDate?.month == start.month && newDate?.day == start.day:
            startComponents.day = newDate?.day
            startComponents.month = newDate?.month
            startComponents.year = newDate?.year
            
            endComponents.month = newDate?.month
            endComponents.year = newDate?.year
        default:
            return nil
        }
        
        let offsetDay = end.day - start.day
        if start.day == end.day {
            endComponents.day = newDate?.day
        } else if let newDay = newDate?.day {
            endComponents.day = newDay + offsetDay
        } else {
            endComponents.day = newDate?.day
        }
        
        guard let newStart = calendar.date(from: startComponents), let newEnd = calendar.date(from: endComponents) else { return nil }
        
        var newEvent = self
        newEvent.start = newStart
        newEvent.end = newEnd
        return newEvent
    }
}

// MARK: - Event protocol

public protocol EventProtocol {
    func compare(_ event: Event) -> Bool
}

// MARK: - Settings protocol

protocol CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect)
    func updateStyle(_ style: Style)
    func setUI()
}

extension CalendarSettingProtocol {
    func setUI() {}
}

// MARK: - Calendar private protocol

protocol CalendarPrivateDelegate: class {
    func didDisplayCalendarEvents(_ events: [Event], dates: [Date?], type: CalendarType)
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?)
    func didSelectCalendarMore(_ date: Date, frame: CGRect?)
    func getEventViewerFrame(_ frame: CGRect)
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?)
    func didAddCalendarEvent(_ event: Event, _ date: Date?)
}

extension CalendarPrivateDelegate {
    func getEventViewerFrame(_ frame: CGRect) {}
}

// MARK: - Data source protocol

public protocol CalendarDataSource: class {
    func eventsForCalendar() -> [Event]
    func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle?
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral?
}

public extension CalendarDataSource {
    func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle? { return nil }
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? { return nil }
}

// MARK: - Display data source

protocol DisplayDataSource: class {
    func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle?
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral?
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration?
}

extension DisplayDataSource {
    func willDisplayDate(_ date: Date?, events: [Event]) -> DateStyle? { return nil }
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? { return nil }
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? { return nil }
}

// MARK: - Delegate protocol

public protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func eventViewerFrame(_ frame: CGRect)
    func didChangeEvent(_ event: Event, start: Date?, end: Date?)
    
    @available(*, deprecated, renamed: "didAddNewEvent")
    func didAddEvent(_ date: Date?)
    func didAddNewEvent(_ event: Event, _ date: Date?)
    
    func didDisplayEvents(_ events: [Event], dates: [Date?])
}

public extension CalendarDelegate {
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?) {}
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    func eventViewerFrame(_ frame: CGRect) {}
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {}
    func didAddEvent(_ date: Date?) {}
    func didAddNewEvent(_ event: Event, _ date: Date?) {}
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {}
}

// MARK: - Date style protocol

public struct DateStyle {
    public var backgroundColor: UIColor
    public var textColor: UIColor?
    public var dotBackgroundColor: UIColor?
    
    public init(backgroundColor: UIColor, textColor: UIColor? = nil, dotBackgroundColor: UIColor? = nil) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.dotBackgroundColor = dotBackgroundColor
    }
}

typealias DayStyle = (day: Day, style: DateStyle?)

protocol DayStyleProtocol: class {
    associatedtype Model
        
    func styleForDay(_ day: Day) -> Model
}
