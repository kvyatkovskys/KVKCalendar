//
//  ViewController.swift
//  KVKCalendar
//
//  Created by kvyatkovskys on 01/02/2019.
//  Copyright (c) 2019 kvyatkovskys. All rights reserved.
//

import UIKit
import KVKCalendar
import EventKit

final class ViewController: UIViewController {
    private var events = [Event]()
    
    private var selectDate: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.date(from: "14.12.2020") ?? Date()
    }()
    
    private lazy var todayButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Today", style: .done, target: self, action: #selector(today))
        button.tintColor = .systemRed
        return button
    }()
    
    private lazy var reloadStyle: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadCalendarStyle))
        button.tintColor = .systemRed
        return button
    }()
    
    private var style: Style = {
        var style = Style()
        style.timeline.isHiddenStubEvent = false
        style.startWeekDay = .sunday
        style.systemCalendars = ["Calendar1", "Calendar2", "Calendar3"]
        if #available(iOS 13.0, *) {
            style.event.iconFile = UIImage(systemName: "paperclip")
        }
        return style
    }()
    
    private lazy var calendarView: CalendarView = {
        let calendar = CalendarView(frame: view.frame, date: selectDate, style: style)
        calendar.delegate = self
        calendar.dataSource = self
        return calendar
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let array = CalendarType.allCases
        let control = UISegmentedControl(items: array.map { $0.rawValue.capitalized })
        control.tintColor = .systemRed
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(switchCalendar), for: .valueChanged)
        return control
    }()
    
    private var eventViewer = EventViewer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        view.addSubview(calendarView)
        navigationItem.titleView = segmentedControl
        navigationItem.rightBarButtonItems = [todayButton, reloadStyle]
        
        loadEvents { (events) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.events = events
                self?.calendarView.reloadData()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = view.frame
        frame.origin.y = 0
        calendarView.reloadFrame(frame)
    }
    
    @objc private func reloadCalendarStyle() {
        style.timeSystem = style.timeSystem == .twentyFour ? .twelve : .twentyFour
        calendarView.updateStyle(style)
        calendarView.reloadData()
    }
    
    @objc private func today() {
        selectDate = Date()
        calendarView.scrollTo(selectDate, animated: true)
        calendarView.reloadData()
    }
    
    @objc private func switchCalendar(sender: UISegmentedControl) {
        let type = CalendarType.allCases[sender.selectedSegmentIndex]
        calendarView.set(type: type, date: selectDate)
        calendarView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        loadEvents { [weak self] (events) in
            self?.events = events
            self?.calendarView.reloadData()
        }
    }
}

// MARK: - Calendar delegate

extension ViewController: CalendarDelegate {
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
        var eventTemp = event
        guard let startTemp = start, let endTemp = end else { return }
        
        let startTime = timeFormatter(date: startTemp)
        let endTime = timeFormatter(date: endTemp)
        eventTemp.start = startTemp
        eventTemp.end = endTemp
        eventTemp.title = TextEvent(timeline: "\(startTime) - \(endTime)\n new time",
                                    month: "\(startTime) - \(endTime)\n new time",
                                    list: "\(startTime) - \(endTime)\n new time")
        
        if let idx = events.firstIndex(where: { $0.compare(eventTemp) }) {
            events.remove(at: idx)
            events.append(eventTemp)
            calendarView.reloadData()
        }
    }
    
    func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?) {
        selectDate = dates.first ?? Date()
        calendarView.reloadData()
    }
    
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
        print(type, event)
        switch type {
        case .day:
            eventViewer.text = event.title.timeline
        default:
            break
        }
    }
    
    func didDeselectEvent(_ event: Event, animated: Bool) {
        print(event)
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        print(date)
    }
    
    func didChangeViewerFrame(_ frame: CGRect) {
        eventViewer.reloadFrame(frame: frame)
    }
    
    func didAddNewEvent(_ event: Event, _ date: Date?) {
        var newEvent = event
        
        guard let start = date, let end = Calendar.current.date(byAdding: .minute, value: 30, to: start) else { return }
        
        let startTime = timeFormatter(date: start)
        let endTime = timeFormatter(date: end)
        newEvent.start = start
        newEvent.end = end
        newEvent.ID = "\(events.count + 1)"
        newEvent.title = TextEvent(timeline: "\(startTime) - \(endTime)\n new time",
                                   month: "\(startTime) - \(endTime)\n new time",
                                   list: "\(startTime) - \(endTime)\n new time")
        events.append(newEvent)
        calendarView.reloadData()
    }
}

// MARK: - Calendar datasource

extension ViewController: CalendarDataSource {
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        guard type == .day else { return nil }
        
        let action = UIAction(title: "Test", attributes: .destructive) { _ in
            print("test tap")
        }
        
        return (UIMenu(title: "Test menu", children: [action]), nil)
    }
    
    func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
        // if you want to get a system events, you need to set style.systemCalendars = ["test"]
        let mappedEvents = systemEvents.compactMap { (event) -> Event in
            let startTime = timeFormatter(date: event.startDate)
            let endTime = timeFormatter(date: event.endDate)
            
            return event.transform(text: "\(startTime) - \(endTime)\n\(event.title ?? "")")
        }
        
        return events + mappedEvents
    }
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        guard event.ID == "2" else { return nil }
        
        return CustomViewEvent(style: style, event: event, frame: frame)
    }
    
    func dequeueCell<T>(dateParameter: DateParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol? where T: UIScrollView {
        switch type {
        case .year where dateParameter.date?.month == Date().month:
            let cell = (view as? UICollectionView)?.kvkDequeueCell(indexPath: indexPath) { (cell: CustomDayCell) in
                cell.imageView.image = UIImage(named: "ic_stub")
            }
            return cell
        case .day, .week, .month:
            guard dateParameter.date?.day == Date().day && dateParameter.type != .empty else { return nil }
            
            let cell = (view as? UICollectionView)?.kvkDequeueCell(indexPath: indexPath) { (cell: CustomDayCell) in
                cell.imageView.image = UIImage(named: "ic_stub")
            }
            return cell
        case .list:
            guard dateParameter.date?.day == 14 else { return nil }
            
            let cell = (view as? UITableView)?.kvkDequeueCell { (cell) in
                cell.backgroundColor = .systemRed
            }
            return cell
        default:
            return nil
        }
    }
    
    func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
        eventViewer.frame = frame
        return eventViewer
    }
    
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? {
        guard type == .month && UIDevice.current.userInterfaceIdiom == .phone else { return nil }
        
        switch style.month.scrollDirection {
        case .vertical:
            return CGSize(width: view.bounds.width / 7, height: 70)
        case .horizontal:
            return nil
        @unknown default:
            return nil
        }
    }
}

// MARK: - load events

extension ViewController {
    func loadEvents(completion: ([Event]) -> Void) {
        let decoder = JSONDecoder()
        
        guard let path = Bundle.main.path(forResource: "events", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
              let result = try? decoder.decode(ItemData.self, from: data) else { return }
        
        let events = result.data.compactMap({ (item) -> Event in
            let startDate = formatter(date: item.start)
            let endDate = formatter(date: item.end)
            let startTime = timeFormatter(date: startDate)
            let endTime = timeFormatter(date: endDate)
            
            var event = Event(ID: item.id)
            event.start = startDate
            event.end = endDate
            event.color = Event.Color(item.color)
            event.isAllDay = item.allDay
            event.isContainsFile = !item.files.isEmpty
            
            if item.allDay {
                event.title = TextEvent(timeline: " \(item.title)",
                                        month: "\(item.title) \(startTime)",
                                        list: item.title)
            } else {
                event.title = TextEvent(timeline: "\(startTime) - \(endTime)\n\(item.title)",
                                        month: "\(item.title) \(startTime)",
                                        list: "\(startTime) - \(endTime) \(item.title)")
            }
            
            if item.id == "14" {
                event.recurringType = .everyDay
                var customeStyle = style.event
                customeStyle.defaultHeight = 40
                event.style = customeStyle
            }
            if item.id == "40" {
                event.recurringType = .everyDay
            }
            return event
        })
        completion(events)
    }
    
    func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.timeSystem.format
        return formatter.string(from: date)
    }
    
    func formatter(date: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: date) ?? Date()
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate { }

struct ItemData: Decodable {
    let data: [Item]
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([Item].self, forKey: CodingKeys.data)
    }
}

struct Item: Decodable {
    let id: String, title: String, start: String, end: String
    let color: UIColor, colorText: UIColor
    let files: [String]
    let allDay: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, start, end, color, files
        case colorText = "text_color"
        case allDay = "all_day"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: CodingKeys.id)
        title = try container.decode(String.self, forKey: CodingKeys.title)
        start = try container.decode(String.self, forKey: CodingKeys.start)
        end = try container.decode(String.self, forKey: CodingKeys.end)
        allDay = try container.decode(Int.self, forKey: CodingKeys.allDay) != 0
        files = try container.decode([String].self, forKey: CodingKeys.files)
        let strColor = try container.decode(String.self, forKey: CodingKeys.color)
        color = UIColor.hexStringToColor(hex: strColor)
        let strColorText = try container.decode(String.self, forKey: CodingKeys.colorText)
        colorText = UIColor.hexStringToColor(hex: strColorText)
    }
}

extension UIColor {
    static func hexStringToColor(hex: String) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count != 6 {
            return .systemGray
        }
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                       blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                       alpha: 1.0)
    }
}

final class CustomViewEvent: EventViewGeneral {
    override init(style: Style, event: Event, frame: CGRect) {
        super.init(style: style, event: event, frame: frame)
        
        let imageView = UIImageView(image: UIImage(named: "ic_stub"))
        imageView.frame = CGRect(origin: CGPoint(x: 3, y: 1), size: CGSize(width: frame.width - 6, height: frame.height - 2))
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        backgroundColor = event.backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
