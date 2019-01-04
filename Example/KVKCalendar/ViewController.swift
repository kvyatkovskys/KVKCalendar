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
    var selectDate = Date()
    var events = [Event]()
    
    lazy var todayButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Today", style: .done, target: self, action: #selector(today))
        button.tintColor = .red
        return button
    }()
    
    lazy var calendarView: CalendarView = {
        var frame = view.frame
        frame.size.height -= (navigationController?.navigationBar.frame.height ?? 0) + UIApplication.shared.statusBarFrame.height
        var style = Style()
        style.monthStyle.isHiddenSeporator = false
        style.timelineStyle.offsetTimeY = 80
        style.timelineStyle.offsetEvent = 3
        style.allDayStyle.isPinned = true
        let calendar = CalendarView(frame: frame, style: style)
        calendar.delegate = self
        return calendar
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: CalendarType.allCases.map({ $0.rawValue.capitalized }))
        control.tintColor = .red
        control.selectedSegmentIndex = 1
        control.addTarget(self, action: #selector(switchCalendar), for: .valueChanged)
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(calendarView)
        navigationItem.titleView = segmentedControl
        navigationItem.rightBarButtonItem = todayButton
        
        calendarView.set(type: .week, date: Date())
        
        loadEvents { [unowned self] (events) in
            self.events = events
            self.calendarView.reloadData()
        }
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType) {
        selectDate = date ?? Date()
        calendarView.reloadData()
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        print(date, frame)
    }
    
    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
        print(event, type, frame)
    }
    
    func eventsForCalendar() -> [Event] {
        return events
    }
}

extension ViewController {
    func loadEvents(completion: ([Event]) -> Void) {
        var events = [Event]()
        
        let path = Bundle.main.path(forResource: "events", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        let result = try! decoder.decode(ItemData.self, from: data)
        
        for (idx, item) in result.data.enumerated() {
            let startDate = self.formatter(date: item.start)
            let endDate = self.formatter(date: item.end)
            let startTime = self.timeFormatter(date: startDate)
            let endTime = self.timeFormatter(date: endDate)
            
            var event = Event()
            event.id = idx
            event.text = item.title
            event.start = startDate
            event.end = endDate
            event.color = item.color
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
