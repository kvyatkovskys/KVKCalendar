//
//  ViewController.swift
//  KVKCalendar
//
//  Created by kvyatkovskys on 01/02/2019.
//  Copyright (c) 2019 kvyatkovskys. All rights reserved.
//

import SwiftUI
import KVKCalendar
import EventKit

private struct KVKCalendarWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        KVKCalendarVC(isFromSUI: true)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

struct ViewControllerSUI: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                KVKCalendarWrapper()
                    .ignoresSafeArea(.container, edges: .bottom)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("KVKCalendar")
            }
        } else {
            NavigationView {
                KVKCalendarWrapper()
                    .edgesIgnoringSafeArea(.bottom)
            }
            .navigationViewStyle(.stack)
            .navigationBarTitle("KVKCalendar")
        }
    }
}

#Preview {
    ViewControllerSUI()
}

final class KVKCalendarVC: UIViewController, KVKCalendarSettings, KVKCalendarDataModel, UIPopoverPresentationControllerDelegate {
    
    var events = [Event]() {
        didSet {
            calendarView.reloadData()
        }
    }
    var selectDate = Date()
    @MainActor
    var style: Style {
        createCalendarStyle()
    }
    var eventViewer = EventViewer()
    
    private let isAutoLayoutMode: Bool
    private let isFromSUI: Bool
    
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
    
    private lazy var calendarView: KVKCalendarView = {
        let calendar: KVKCalendarView
        if isAutoLayoutMode {
            calendar = KVKCalendarView(date: selectDate, style: style)
        } else {
            var frame = view.frame
            frame.origin.y = 0
            calendar = KVKCalendarView(frame: frame, date: selectDate, style: style)
        }
        calendar.delegate = self
        calendar.dataSource = self
        return calendar
    }()
    
    private var calendarTypeBtn: UIBarButtonItem {
        if #available(iOS 14.0, *) {
            let btn = UIBarButtonItem(
                title: calendarView.selectedType.title,
                menu: createCalendarTypesMenu()
            )
            btn.style = .done
            btn.tintColor = .systemRed
            return btn
        } else {
            return UIBarButtonItem()
        }
    }
    
    init(isFromSUI: Bool = false) {
        self.isFromSUI = isFromSUI
        isAutoLayoutMode = isFromSUI
        super.init(nibName: nil, bundle: nil)
        selectDate = defaultDate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(calendarView)
        if isAutoLayoutMode {
            calendarView.translatesAutoresizingMaskIntoConstraints = false
            let top = calendarView.topAnchor.constraint(equalTo: view.topAnchor)
            let leading = calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailing = calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let bottom = calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            NSLayoutConstraint.activate([top, leading, trailing, bottom])
            calendarView.layoutIfNeeded()
        }
        setupNavBar()
        fetch()
    }
    
    override func viewWillLayoutSubviews() {
        guard !isAutoLayoutMode else { return }
        var frame = view.frame
        frame.origin.y = 0
        calendarView.reloadFrame(frame)
    }
    
    override func viewDidLayoutSubviews() {
        guard isAutoLayoutMode else { return }
        calendarView.layoutIfNeeded()
    }
    
    private func fetch(
        withDelay: Bool = true,
        updateStyle: Bool = false
    ) {
        Task {
            let result = await loadEvents(
                withStyle: style,
                withDelay: withDelay
            )
            await MainActor.run {
                events = result
                if updateStyle {
                    calendarView.updateStyle(style)
                }
            }
        }
    }
    
    @objc private func reloadCalendarStyle() {
        var updatedStyle = calendarView.style
        updatedStyle.timeSystem = calendarView.style.timeSystem == .twentyFour ? .twelve : .twentyFour
        calendarView.updateStyle(updatedStyle)
        calendarView.reloadData()
    }
    
    @objc private func today() {
        selectDate = Date()
        calendarView.scrollTo(selectDate, animated: true)
        calendarView.reloadData()
    }
    
    private func setupNavBar() {
        if isFromSUI {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                parent?.navigationItem.leftBarButtonItems = [calendarTypeBtn, todayButton]
                parent?.navigationItem.rightBarButtonItems = [reloadStyle]
            }
        } else {
            navigationItem.title = "KVKCalendar"
            navigationItem.leftBarButtonItems = [calendarTypeBtn, todayButton]
            navigationItem.rightBarButtonItems = [reloadStyle]
        }
    }
    
    @available(iOS 14.0, *)
    private func createCalendarTypesMenu() -> UIMenu {
        let actions: [UIMenuElement] = KVKCalendar.CalendarType.allCases.compactMap { (item) in
            UIAction(title: item.title, state: item == calendarView.selectedType ? .on : .off) { [weak self] (_) in
                guard let self = self else { return }
                self.calendarView.set(type: item, date: self.selectDate)
                self.calendarView.reloadData()
                self.setupNavBar()
            }
        }
        return UIMenu(children: actions)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // to track changing windows and theme of device
        fetch(withDelay: false, updateStyle: true)
    }
    
}

// MARK: - Calendar delegate

extension KVKCalendarVC: CalendarDelegate {
    func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
        if let result = handleChangingEvent(event, start: start, end: end) {
            events.replaceSubrange(result.range, with: result.events)
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
        if let newEvent = handleNewEvent(event, date: date) {
            events.append(newEvent)
        }
    }
}

// MARK: - Calendar datasource

extension KVKCalendarVC: CalendarDataSource {
    
    func willSelectDate(_ date: Date, type: CalendarType) {
        print(date, type)
    }
    
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        handleOptionMenu(type: type)
    }
    
    func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
        // if you want to get a system events, you need to set style.systemCalendars = ["test"]
        handleEvents(systemEvents: systemEvents)
    }
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        handleCustomEventView(event: event, style: style, frame: frame)
    }
    
    func dequeueCell<T>(parameter: CellParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol? where T: UIScrollView {
        handleCell(parameter: parameter, type: type, view: view, indexPath: indexPath)
    }
    
    func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
        eventViewer.frame = frame
        return eventViewer
    }
    
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? {
        handleSizeCell(type: type, stye: calendarView.style, view: view)
    }
}
