//
//  ViewController.swift
//  KVKCalendar
//
//  Created by kvyatkovskys on 01/02/2019.
//  Copyright (c) 2019 kvyatkovskys. All rights reserved.
//

import UIKit
import KVKCalendar

final class ViewController: UIViewController, CalendarDelegate {
    var selectDate = Date()
    
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
        let calendar = CalendarView(frame: frame, style: style)
        calendar.delegate = self
        return calendar
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: CalendarType.allCases.map({ $0.rawValue.capitalized }))
        control.tintColor = .red
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(switchCalendar), for: .valueChanged)
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(calendarView)
        calendarView.set(type: .day, date: Date())
        navigationItem.titleView = segmentedControl
        navigationItem.rightBarButtonItem = todayButton
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
    }

    func didSelectDate(date: Date?, type: CalendarType) {
        selectDate = date ?? Date()
    }
    
    func eventsForCalendar() -> [Event] {
        return []
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
