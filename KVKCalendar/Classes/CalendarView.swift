//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit
import EventKit

public final class CalendarView: UIView {
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource?
    public var selectedType: CalendarType {
        return type
    }
    
    private var style: Style
    private var type = CalendarType.day
    private var yearData: YearData
    private var weekData: WeekData
    private let monthData: MonthData
    private var dayData: DayData
    private var events: [Event] {
        return dataSource?.eventsForCalendar() ?? []
    }
    
    private let eventStore = EKEventStore()
    
    private var systemEvents: [Event] {
        let systemCalendars = eventStore.calendars(for: .event).filter({ style.systemCalendars.contains($0.title) })
        guard !systemCalendars.isEmpty else { return [] }
        
        return getSystemEvents(eventStore: eventStore, calendars: systemCalendars).compactMap({ $0.transform })
    }
    
    private lazy var dayView: DayView = {
        let day = DayView(data: dayData, frame: frame, style: style)
        day.delegate = self
        day.dataSource = self
        day.scrollHeaderDay.dataSource = self
        return day
    }()
    
    private lazy var weekView: WeekView = {
        let week = WeekView(data: weekData, frame: frame, style: style)
        week.delegate = self
        week.dataSource = self
        week.scrollHeaderDay.dataSource = self
        return week
    }()
    
    private lazy var monthView: MonthView = {
        let month = MonthView(data: monthData, frame: frame, style: style)
        month.delegate = self
        month.dataSource = self
        month.willSelectDate = { [weak self] (date) in
            self?.delegate?.willSelectDate(date, type: .month)
        }
        return month
    }()
    
    private lazy var yearView: YearView = {
        let year = YearView(data: monthData.data, frame: frame, style: style)
        year.delegate = self
        year.dataSource = self
        return year
    }()
    
    public init(frame: CGRect, date: Date = Date(), style: Style = Style(), years: Int = 4) {
        self.style = style.checkStyle
        self.yearData = YearData(date: date, years: years, style: style)
        self.dayData = DayData(yearData: yearData, timeSystem: style.timeSystem, startDay: style.startWeekDay)
        self.weekData = WeekData(yearData: yearData, timeSystem: style.timeSystem, startDay: style.startWeekDay)
        self.monthData = MonthData(yearData: yearData, startDay: style.startWeekDay, calendar: style.calendar, scrollDirection: style.month.scrollDirection)
        super.init(frame: frame)
        
        if let defaultType = style.defaultType {
            type = defaultType
        }
        
        set(type: type, date: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private methods
    
    private func getSystemEvents(eventStore: EKEventStore, calendars: [EKCalendar]) -> [EKEvent] {
            var startOffset = 0
            if yearData.yearsCount.count > 1 {
                startOffset = yearData.yearsCount.first ?? 0
            }
            var endOffset = 1
            if yearData.yearsCount.count > 1 {
                endOffset = yearData.yearsCount.last ?? 1
            }
            
            guard let startDate = style.calendar.date(byAdding: .year, value: startOffset, to: yearData.date),
                  let endDate = style.calendar.date(byAdding: .year, value: endOffset, to: yearData.date) else {
                return []
            }
            
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
            return eventStore.events(matching: predicate)
        }
        
        private func authForSystemCalendar() {
            let status = EKEventStore.authorizationStatus(for: .event)
            
            switch (status) {
            case .notDetermined:
                requestAccessToSystemCalendar { [weak self] (_) in
                    self?.reloadData()
                }
            default:
                break
            }
        }
        
        private func requestAccessToSystemCalendar(completion: @escaping (Bool) -> Void) {
            eventStore.requestAccess(to: .event) { (access, error) in
                print(access, error ?? "")
                completion(access)
            }
        }
    
    private func switchTypeCalendar(type: CalendarType) {
        self.type = type
        subviews.filter({ $0 is DayView
            || $0 is WeekView
            || $0 is MonthView
            || $0 is YearView }).forEach({ $0.removeFromSuperview() })
        
        switch self.type {
        case .day:
            addSubview(dayView)
        case .week:
            addSubview(weekView)
        case .month:
            addSubview(monthView)
        case .year:
            addSubview(yearView)
        }
    }
    
    // MARK: Public methods
    
    public func addEventViewToDay(view: UIView) {
        dayView.addEventView(view: view)
    }
    
    public func set(type: CalendarType, date: Date) {
        self.type = type
        switchTypeCalendar(type: type)
        scrollTo(date)
    }
    
    public func reloadData() {
        let values = events
//        if !style.systemCalendars.isEmpty {
//            //authForSystemCalendar()
//        }
//        if systemEvents.isEmpty == false {
//            //values += systemEvents
//        }
        
        DispatchQueue.main.async { [weak self] in
            switch self?.type {
            case .day:
                self?.dayView.reloadData(events: values)
            case .week:
                self?.weekView.reloadData(events: values)
            case .month:
                self?.monthView.reloadData(events: values)
            default:
                break
            }
        }
    }
    
    public func scrollTo(_ date: Date) {
        switch type {
        case .day:
            dayView.setDate(date)
        case .week:
            weekView.setDate(date)
        case .month:
            monthView.setDate(date)
        case .year:
            yearView.setDate(date)
        }
    }
    
    public func deselectEvent(_ event: Event, animated: Bool) {
        switch type {
        case .day:
            dayView.timelineView.deselectEvent(event, animated: animated)
        case .week:
            weekView.timelineView.deselectEvent(event, animated: animated)
        default:
            break
        }
    }
    
    public func addEventsToSystemCalendars(events: [Event], calendars: [String], span: EKSpan = .thisEvent) throws {
        try eventStore.save(EKEvent(), span: span)
    }
    
    public func removeEventsFromSystemCalendar(events: [Event], calendars: [String], span: EKSpan = .thisEvent) throws {
        try eventStore.remove(EKEvent(), span: span)
    }
}

extension CalendarView: DisplayDataSource {
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
    
    func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? {
        return dataSource?.willDisplayHeaderSubview(date: date, frame: frame, type: type)
    }
    
    func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        return dataSource?.dequeueDateCell(date: date, type: type, collectionView: collectionView, indexPath: indexPath)
    }
    
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? {
        return nil //dataSource?.willDisplayContextMenu(event, date: date)
    }
}

extension CalendarView: CalendarDataProtocol {
    func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? {
        delegate?.sizeForCell(date, type: type)
    }
    
    func didDisplayCalendarEvents(_ events: [Event], dates: [Date?], type: CalendarType) {
        guard self.type == type else { return }
        
        delegate?.didDisplayEvents(events, dates: dates)
    }
    
    func didSelectCalendarDate(_ date: Date?, type: CalendarType, frame: CGRect?) {
        delegate?.didSelectDate(date, type: type, frame: frame)
    }
    
    func deselectCalendarEvent(_ event: Event) {
        delegate?.deselectEvent(event, animated: true)
    }
    
    func didSelectCalendarEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: type, frame: frame)
    }
    
    func didSelectCalendarMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectMore(date, frame: frame)
    }
    
    func didAddCalendarEvent(_ event: Event, _ date: Date?) {
        delegate?.didAddNewEvent(event, date)
    }
    
    func didChangeCalendarEvent(_ event: Event, start: Date?, end: Date?) {
        delegate?.didChangeEvent(event, start: start, end: end)
    }
    
    func getEventViewerFrame(_ frame: CGRect) {
        var newFrame = frame
        newFrame.origin = .zero
        delegate?.eventViewerFrame(newFrame)
    }
}

extension CalendarView: CalendarSettingProtocol {
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        dayView.reloadFrame(frame)
        weekView.reloadFrame(frame)
        monthView.reloadFrame(frame)
        yearView.reloadFrame(frame)
    }
    
    // TODO: in progress
    func updateStyle(_ style: Style) {
        self.style = style
        dayView.updateStyle(style)
        weekView.updateStyle(style)
        monthView.updateStyle(style)
        yearView.updateStyle(style)
    }
}
