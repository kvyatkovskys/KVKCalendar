//
//  ViewController.swift
//  KVKCalendar
//
//  Created by kvyatkovskys on 01/02/2019.
//  Copyright (c) 2019 kvyatkovskys. All rights reserved.
//

import UIKit
import KVKCalendar

final class ViewController: UIViewController {
    private var events = [Event]()
    
    private var selectDate: Date = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.date(from: "14.12.2018") ?? Date()
    }()
    
    private lazy var todayButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Today", style: .done, target: self, action: #selector(today))
        button.tintColor = .red
        return button
    }()
    
    private lazy var calendarView: CalendarView = {
        var style = Style()
        if UIDevice.current.userInterfaceIdiom == .phone {
            style.monthStyle.isHiddenSeporator = true
            style.timelineStyle.widthTime = 40
            style.timelineStyle.offsetTimeX = 2
            style.timelineStyle.offsetLineLeft = 2
        } else {
            style.timelineStyle.widthEventViewer = 500
        }
        style.followInInterfaceStyle = true
        style.timelineStyle.offsetTimeY = 80
        style.timelineStyle.offsetEvent = 3
        style.timelineStyle.currentLineHourWidth = 40
        style.allDayStyle.isPinned = true
        //style.startWeekDay = .sunday
        style.timeHourSystem = .twelveHour
        
        let calendar = CalendarView(frame: view.frame, date: selectDate, style: style)
        calendar.delegate = self
        calendar.dataSource = self
        return calendar
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let array: [CalendarType]
        if UIDevice.current.userInterfaceIdiom == .pad {
            array = CalendarType.allCases
        } else {
            array = CalendarType.allCases.filter({ $0 != .year })
        }
        let control = UISegmentedControl(items: array.map({ $0.rawValue.capitalized }))
        control.tintColor = .red
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(switchCalendar), for: .valueChanged)
        return control
    }()
    
    private lazy var eventViewer: EventViewer = {
        let view = EventViewer(frame: CGRect(x: 0, y: 0, width: 500, height: calendarView.frame.height))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        view.addSubview(calendarView)
        navigationItem.titleView = segmentedControl
        navigationItem.rightBarButtonItem = todayButton
        
        calendarView.addEventViewToDay(view: eventViewer)
        
        loadEvents { [unowned self] (events) in
            self.events = events
            self.calendarView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = view.frame
        frame.origin.y = 0
        calendarView.reloadFrame(frame)
    }
    
    @objc func today(sender: UIBarButtonItem) {
        calendarView.scrollToDate(date: Date())
    }
    
    @objc func switchCalendar(sender: UISegmentedControl) {
        guard let type = CalendarType(rawValue: CalendarType.allCases[sender.selectedSegmentIndex].rawValue) else { return }
        switch type {
        case .day:
            calendarView.set(type: .day, date: selectDate)
        case .week:
            calendarView.set(type: .week, date: selectDate)
        case .month:
            calendarView.set(type: .month, date: selectDate)
        case .year:
            calendarView.set(type: .year, date: selectDate)
        }
        calendarView.reloadData()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        loadEvents { [unowned self] (events) in
            self.events = events
            self.calendarView.reloadData()
        }
    }
}

extension ViewController: CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType, frame: CGRect?) {
        selectDate = date ?? Date()
        calendarView.reloadData()
    }
    
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
        switch type {
        case .day:
            eventViewer.text = event.text
        default:
            break
        }
    }
    
    func eventViewerFrame(_ frame: CGRect) {
        eventViewer.reloadFrame(frame: frame)
    }
}

extension ViewController: CalendarDataSource {
    func eventsForCalendar() -> [Event] {
        return events
    }
}

extension ViewController {
    func loadEvents(completion: ([Event]) -> Void) {
        var events = [Event]()
        let decoder = JSONDecoder()
                
        guard let path = Bundle.main.path(forResource: "events", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let result = try? decoder.decode(ItemData.self, from: data) else { return }
        
        for (idx, item) in result.data.enumerated() {
            let startDate = self.formatter(date: item.start)
            let endDate = self.formatter(date: item.end)
            let startTime = self.timeFormatter(date: startDate)
            let endTime = self.timeFormatter(date: endDate)
            
            var event = Event()
            event.id = idx
            event.start = startDate
            event.end = endDate
            event.color = EventColor(item.color)
            event.isAllDay = item.allDay
            event.isContainsFile = !item.files.isEmpty
            event.textForMonth = item.title
            
            if item.allDay {
                event.text = "\(item.title)"
            } else {
                event.text = "\(startTime) - \(endTime)\n\(item.title)"
            }
            events.append(event)
        }
        completion(events)
    }
    
    func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func formatter(date: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: date) ?? Date()
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    
}

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
    let id: String
    let title: String
    let start: String
    let end: String
    let color: UIColor
    let colorText: UIColor
    let files: [String]
    let allDay: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case start
        case end
        case color
        case colorText = "text_color"
        case files
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
            return UIColor.gray
        }
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                       green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                       blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                       alpha: CGFloat(1.0)
        )
    }
}
