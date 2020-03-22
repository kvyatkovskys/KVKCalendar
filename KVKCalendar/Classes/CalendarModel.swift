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

extension Event: EventProtocol {
    public func compare(_ event: Event) -> Bool {
        return "\(id)".hashValue == "\(event.id)".hashValue
    }
}

public protocol EventProtocol {
    func compare(_ event: Event) -> Bool
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
    func didDisplayCalendarEvents(_ events: [Event], dates: [Date?], type: CalendarType)
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?)
    func didSelectCalendarMore(_ date: Date, frame: CGRect?)
    func calendarEventViewerFrame(_ frame: CGRect)
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?)
    func didAddCalendarEvent(_ date: Date?)
}

extension CalendarPrivateDelegate {
    func getEventViewerFrame(_ frame: CGRect) {}
}

public protocol CalendarDataSource: AnyObject {
    func eventsForCalendar() -> [Event]
}

public protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?)
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func eventViewerFrame(_ frame: CGRect)
    func didChangeEvent(_ event: Event, start: Date?, end: Date?)
    func didAddEvent(_ date: Date?)
    func didDisplayEvents(_ events: [Event], dates: [Date?])
}

public extension CalendarDelegate {
    func didSelectDate(_ date: Date?, type: CalendarType, frame: CGRect?) {}
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    func eventViewerFrame(_ frame: CGRect) {}
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {}
    func didAddEvent(_ date: Date?) {}
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {}
}
