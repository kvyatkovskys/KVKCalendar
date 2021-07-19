//
//  CalendarModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 25.02.2020.
//

import UIKit
import EventKit

public struct DateParameter {
    public var date: Date?
    public var type: DayType?
}

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
    
    @available(*, deprecated, renamed: "current")
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
    case day, week, month, year, list
}

// MARK: Event model

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
    public var text: String = ""
    public var start: Date = Date()
    public var end: Date = Date()
    public var color: Event.Color? = Event.Color(.systemBlue) {
        didSet {
            guard let tempColor = color else { return }
            
            let value = prepareColor(tempColor)
            backgroundColor = value.background
            textColor = value.text
        }
    }
    public var backgroundColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3)
    public var textColor: UIColor = .white
    public var isAllDay: Bool = false
    public var isContainsFile: Bool = false
    public var textForMonth: String = ""
    public var textForList: String = ""
    
    @available(swift, deprecated: 0.4.6, obsoleted: 0.4.7, renamed: "data")
    public var eventData: Any? = nil
    public var data: Any? = nil
    
    public var recurringType: Event.RecurringType = .none
    
    ///individual event customization
    ///(in-progress) works only with a default height
    public var style: EventStyle? = nil
    
    public init(ID: String) {
        self.ID = ID
        
        if let tempColor = color {
            let value = prepareColor(tempColor)
            backgroundColor = value.background
            textColor = value.text
        }
    }
    
    func prepareColor(_ color: Event.Color, brightnessOffset: CGFloat = 0.4) -> (background: UIColor, text: UIColor) {
        let bgColor = color.value.withAlphaComponent(color.alpha)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let txtColor = UIColor(hue: hue, saturation: saturation,
                               brightness: UIScreen.isDarkMode ? brightness : brightness * brightnessOffset,
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

protocol CalendarSettingProtocol: AnyObject {
    
    var currentStyle: Style { get }
    
    func reloadFrame(_ frame: CGRect)
    func updateStyle(_ style: Style)
    func reloadData(_ events: [Event])
    func setDate(_ date: Date)
    func setUI()
    
}

extension CalendarSettingProtocol {
    
    func reloadData(_ events: [Event]) {}
    func setDate(_ date: Date) {}
    
}

// MARK: - Data source protocol

public protocol CalendarDataSource: AnyObject {
    /// get events to display on view
    /// also this method returns a system events from iOS calendars if you set the property `systemCalendar` in style
    func eventsForCalendar(systemEvents: [EKEvent]) -> [Event]
    
    func willDisplayDate(_ date: Date?, events: [Event])
    
    /// Use this method to add a custom event view
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral?
    
    /// Use this method to add a custom header view (works on Day, Week, Month)
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView?
    
    /// Use the method to replace the collectionView. Works for month/year View
    func willDisplayCollectionView(frame: CGRect, type: CalendarType) -> UICollectionView?
    
    func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView?
    
    /// The method is **DEPRECATED**
    /// Use a new **dequeueCell**
    @available(*, deprecated, renamed: "dequeueCell")
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell?
    
    /// The method is **DEPRECATED**
    /// Use a new **dequeueHeader**
    @available(*, deprecated, renamed: "dequeueHeader")
    func dequeueHeaderView(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView?
    
    /// The method is **DEPRECATED**
    /// Use a new **dequeueCell**
    @available(*, deprecated, renamed: "dequeueCell")
    func dequeueListCell(date: Date?, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell?
    
    /// Use this method to add a custom day cell
    func dequeueCell<T: UIScrollView>(dateParameter: DateParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol?
    
    /// Use this method to add a header view
    func dequeueHeader<T: UIScrollView>(date: Date?, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarHeaderProtocol?
    
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)?
}

public extension CalendarDataSource {
    func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? { return nil }
    
    func willDisplayDate(_ date: Date?, events: [Event]) {}
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? { return nil }
    
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? { return nil }
    
    func willDisplayCollectionView(frame: CGRect, type: CalendarType) -> UICollectionView? { return nil }

    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? { return nil }
    
    func dequeueHeaderView(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView? { return nil }

    func dequeueListCell(date: Date?, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell? { return nil }
    
    func dequeueCell<T: UIScrollView>(dateParameter: DateParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol? { return nil }
    
    func dequeueHeader<T: UIScrollView>(date: Date?, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarHeaderProtocol? { return nil }
    
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        return nil
    }
}

// MARK: - Delegate protocol

public protocol CalendarDelegate: AnyObject {
    func sizeForHeader(_ date: Date?, type: CalendarType) -> CGSize?
    
    /// size cell for (month, year, list) view
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize?
    
    /// The method is **DEPRECATED**
    /// Use a new **didSelectDates**
    @available(*, deprecated, renamed: "didSelectDates")
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    
    /// get selected dates
    func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?)
    
    /// get a selected event
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    
    /// tap on more fro month view
    func didSelectMore(_ date: Date, frame: CGRect?)
    
    /// The method is **DEPRECATED**
    /// Use a new **didChangeViewerFrame**
    @available(*, deprecated, renamed: "didChangeViewerFrame")
    func eventViewerFrame(_ frame: CGRect)
    
    /// event's viewer for iPad
    func didChangeViewerFrame(_ frame: CGRect)
    
    /// drag & drop events and resize
    func didChangeEvent(_ event: Event, start: Date?, end: Date?)
    
    /// add new event
    func didAddNewEvent(_ event: Event, _ date: Date?)
    
    /// get current displaying events
    func didDisplayEvents(_ events: [Event], dates: [Date?])
    
    /// get next date when the calendar scrolls (works for month view)
    func willSelectDate(_ date: Date, type: CalendarType)
    
    /// The method is **DEPRECATED**
    /// Use a new ** func didDeselectEvent**
    @available(*, deprecated, renamed: "didDeselectEvent")
    func deselectEvent(_ event: Event, animated: Bool)
    
    /// deselect event on timeline
    func didDeselectEvent(_ event: Event, animated: Bool)
}

public extension CalendarDelegate {
    func sizeForHeader(_ date: Date?, type: CalendarType) -> CGSize? { return nil }
    
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? { return nil }
    
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?) {}
    
    func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?)  {}
    
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    
    func eventViewerFrame(_ frame: CGRect) {}
    
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {}
        
    func didAddNewEvent(_ event: Event, _ date: Date?) {}
    
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {}
    
    func willSelectDate(_ date: Date, type: CalendarType) {}
    
    func deselectEvent(_ event: Event, animated: Bool) {}
    
    func didDeselectEvent(_ event: Event, animated: Bool) {}
    
    func didChangeViewerFrame(_ frame: CGRect) {}
}

// MARK: - Private Display dataSource

protocol DisplayDataSource: CalendarDataSource {}

extension DisplayDataSource {
    public func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] { return [] }
}

// MARK: - Private Display delegate

protocol DisplayDelegate: CalendarDelegate {
    func didDisplayEvents(_ events: [Event], dates: [Date?], type: CalendarType)
}

extension DisplayDelegate {
    public func willSelectDate(_ date: Date, type: CalendarType) {}
    
    func deselectEvent(_ event: Event, animated: Bool) {}
}

// MARK: - EKEvent

public extension EKEvent {
    func transform(text: String? = nil, textForMonth: String? = nil, textForList: String? = nil) -> Event {
        var event = Event(ID: eventIdentifier)
        event.text = text ?? title
        event.start = startDate
        event.end = endDate
        event.color = Event.Color(UIColor(cgColor: calendar.cgColor))
        event.isAllDay = isAllDay
        event.textForMonth = textForMonth ?? title
        event.textForList = textForList ?? title
        return event
    }
}

// MARK: - Protocols to customize calendar

public protocol KVKCalendarCellProtocol: AnyObject {}

extension UICollectionViewCell: KVKCalendarCellProtocol {}
extension UITableViewCell: KVKCalendarCellProtocol {}

public protocol KVKCalendarHeaderProtocol: AnyObject {}

extension UIView: KVKCalendarHeaderProtocol {}
