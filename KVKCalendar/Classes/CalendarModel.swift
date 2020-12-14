//
//  CalendarModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 25.02.2020.
//

import UIKit
import EventKit

public enum TimeHourSystem: Int {
    @available(swift, deprecated: 0.3.6, obsoleted: 0.3.7, renamed: "twelve")
    case twelveHour = 0
    @available(swift, deprecated: 0.3.6, obsoleted: 0.3.7, renamed: "twentyFour")
    case twentyFourHour = 1
    
    case twelve = 12
    case twentyFour = 24
    
    var hours: [String] {
        switch self {
        case .twelveHour, .twelve:
            let array = ["12"] + Array(1...11).map({ String($0) })
            let am = array.map { $0 + " AM" } + ["Noon"]
            var pm = array.map { $0 + " PM" }
            
            pm.removeFirst()
            if let item = am.first {
                pm.append(item)
            }
            return am + pm
        case .twentyFourHour, .twentyFour:
            let array = ["00:00"] + Array(1...24).map({ (i) -> String in
                let i = i % 24
                var string = i < 10 ? "0" + "\(i)" : "\(i)"
                string.append(":00")
                return string
            })
            return array
        }
    }
    
    @available(swift, deprecated: 0.4.2, obsoleted: 0.4.3, renamed: "current")
    public static var currentSystemOnDevice: TimeHourSystem? {
        let locale = NSLocale.current
        guard let formatter = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) else { return nil }
        
        if formatter.contains("a") {
            return .twelve
        } else {
            return .twentyFour
        }
    }
    
    public static var current: TimeHourSystem? {
        let locale = NSLocale.current
        guard let formatter = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) else { return nil }
        
        if formatter.contains("a") {
            return .twelve
        } else {
            return .twentyFour
        }
    }
    
    public var format: String {
        switch self {
        case .twelveHour, .twelve:
            return "h:mm a"
        case .twentyFourHour, .twentyFour:
            return "HH:mm"
        }
    }
}

public enum CalendarType: String, CaseIterable {
    case day, week, month, year
}

@available(swift, deprecated: 0.4.1, obsoleted: 0.4.2, renamed: "Event.Color")
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
    
    /// unique identifier of Event
    public var ID: String
    public var text: String
    public var start: Date
    public var end: Date
    public var color: Event.Color? {
        didSet {
            guard let tempColor = color else { return }
            
            let value = prepareColor(tempColor)
            backgroundColor = value.background
            textColor = value.text
        }
    }
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var isAllDay: Bool
    public var isContainsFile: Bool
    public var textForMonth: String
    public var eventData: Any?
    public var recurringType: Event.RecurringType
    
    public init(ID: String, text: String = "", start: Date = Date(), end: Date = Date(), color: Event.Color? = Event.Color(UIColor.systemBlue), backgroundColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3), textColor: UIColor = .white, isAllDay: Bool = false, isContainsFile: Bool = false, textForMonth: String = "", eventData: Any? = nil, recurringType: Event.RecurringType = .none) {
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
    
    func prepareColor(_ color: Event.Color) -> (background: UIColor, text: UIColor) {
        let bgColor = color.value.withAlphaComponent(color.alpha)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let txtColor = UIColor(hue: hue, saturation: saturation,
                               brightness: UIScreen.isDarkMode ? brightness : brightness * 0.4,
                               alpha: alpha)
        
        return (bgColor, txtColor)
    }
}

extension Event {
    var hash: Int {
        return ID.hashValue
    }
}

public extension Event {
    var isNew: Bool {
        return ID == Event.idForNewEvent
    }
    
    enum RecurringType: Int {
        case everyDay, everyWeek, everyMonth, everyYear, none
    }
    
    struct Color {
        let value: UIColor
        let alpha: CGFloat
        
        public init(_ color: UIColor, alpha: CGFloat = 0.3) {
            self.value = color
            self.alpha = alpha
        }
    }
}

@available(swift, deprecated: 0.4.1, obsoleted: 0.4.2, renamed: "Event.RecurringType")
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
        startComponents.year = newDate?.year
        startComponents.month = newDate?.month
        startComponents.hour = start.hour
        startComponents.minute = start.minute
        
        var endComponents = DateComponents()
        endComponents.year = newDate?.year
        endComponents.month = newDate?.month
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
        case .everyYear where newDate?.year != start.year && newDate?.month == start.month && newDate?.day == start.day:
            startComponents.day = newDate?.day
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

protocol CalendarSettingProtocol: class {
    func reloadFrame(_ frame: CGRect)
    func updateStyle(_ style: Style)
    func setUI()
}

extension CalendarSettingProtocol {
    func setUI() {}
}

// MARK: - Data source protocol

public protocol CalendarDataSource: class {
    /// get events to display on view
    /// also this method returns a system events from iOS calendars if you set the property `systemCalendar` in style
    func eventsForCalendar(systemEvents: [EKEvent]) -> [Event]
    
    // deprecated method use func dequeueDayCell(:)
    //func willDisplayDate(_ date: Date?, events: [Event])
    
    /// Use this method to add a custom event view
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral?
    
    /// Use this method to add a custom header view (works on Day, Week, Year)
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView?
    
    /// Use this method to add a custom day cell
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell?
}

public extension CalendarDataSource {
    func willDisplayDate(_ date: Date?, events: [Event]) {}
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? { return nil }
    
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? { return nil }
    
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? { return nil }
}

// MARK: - Private Display data source

protocol DisplayDataSource: class {
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral?
    
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView?
    
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell?
    
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration?
}

extension DisplayDataSource {
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? { return nil }
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? { return nil }
    
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? { return nil }
    
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? { return nil }
}

// MARK: - Delegate protocol

public protocol CalendarDelegate: class {
    /// size cell for month view
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize?
    
    /// get a selecting date
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    
    /// get a selecting event
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    
    /// tap on more fro month view
    func didSelectMore(_ date: Date, frame: CGRect?)
    
    /// event's viewer for iPad
    func eventViewerFrame(_ frame: CGRect)
    
    /// drag & drop events and resize
    func didChangeEvent(_ event: Event, start: Date?, end: Date?)
    
    /// add new event
    func didAddNewEvent(_ event: Event, _ date: Date?)
    
    /// get current displaying events
    func didDisplayEvents(_ events: [Event], dates: [Date?])
    
    /// get next date when the calendar scrolls (works for month view)
    func willSelectDate(_ date: Date, type: CalendarType)
    
    /// deselect event on timeline
    func deselectEvent(_ event: Event, animated: Bool)
}

public extension CalendarDelegate {
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? { return nil }
    
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?) {}
    
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    
    func eventViewerFrame(_ frame: CGRect) {}
    
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {}
    
    func didAddEvent(_ date: Date?) {}
    
    func didAddNewEvent(_ event: Event, _ date: Date?) {}
    
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {}
    
    func willSelectDate(_ date: Date, type: CalendarType) {}
    
    func deselectEvent(_ event: Event, animated: Bool) {}
}

// MARK: - Private Display delegate

protocol DisplayDelegate: class {
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize?
    
    func didDisplayCalendarEvents(_ events: [Event], dates: [Date?], type: CalendarType)
    
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?)
    
    func didSelectCalendarMore(_ date: Date, frame: CGRect?)
    
    func getEventViewerFrame(_ frame: CGRect)
    
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?)
    
    func didAddCalendarEvent(_ event: Event, _ date: Date?)
    
    func deselectCalendarEvent(_ event: Event)
}

// MARK: EKEvent

public extension EKEvent {
    func transform(text: String? = nil) -> Event {
        let event = Event(ID: eventIdentifier,
                          text: text ?? title,
                          start: startDate,
                          end: endDate,
                          color: Event.Color(UIColor(cgColor: calendar.cgColor)),
                          isAllDay: isAllDay,
                          textForMonth: title)
        return event
    }
}
