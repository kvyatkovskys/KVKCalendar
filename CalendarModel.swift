//
//  CalendarModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01/05/2019.
//

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

protocol CalendarFrameProtocol {
    func reloadFrame(frame: CGRect)
}

protocol CalendarPrivateDelegate: AnyObject {
    func didSelectCalendarDate(_ date: Date?, type: CalendarType)
    func didSelectCalendarEvents(_ events: [Event])
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
    func didSelectDate(date: Date?, type: CalendarType)
    func didSelectEvents(_ events: [Event])
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func eventViewerFrame(_ frame: CGRect)
}

public extension CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType) {}
    func didSelectEvents(_ events: [Event]) {}
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {}
    func didSelectMore(_ date: Date, frame: CGRect?) {}
    func eventViewerFrame(_ frame: CGRect) {}
}
