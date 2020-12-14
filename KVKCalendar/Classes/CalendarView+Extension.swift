//
//  CalendarView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 14.12.2020.
//

import Foundation
import EventKit

extension CalendarView {
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
        if !style.systemCalendars.isEmpty {
            authForSystemCalendars()
        }
        
        let events = dataSource?.eventsForCalendar(systemEvents: systemEvents) ?? []
        
        switch type {
        case .day:
            dayView.reloadData(events: events)
        case .week:
            weekView.reloadData(events: events)
        case .month:
            monthView.reloadData(events: events)
        default:
            break
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
            dayView.timelinePages.timelineView?.deselectEvent(event, animated: animated)
        case .week:
            weekView.timelinePages.timelineView?.deselectEvent(event, animated: animated)
        default:
            break
        }
    }
    
    public func activateMovingEventInMonth(eventView: EventViewGeneral, snapshot: UIView, gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            monthView.didStartMoveEvent(eventView, snapshot: snapshot, gesture: gesture)
        case .cancelled, .ended, .failed:
            monthView.didEndMoveEvent(gesture: gesture)
        default:
            break
        }
    }
    
    public func movingEventInMonth(eventView: EventViewGeneral, snapshot: UIView, gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            monthView.didChangeMoveEvent(gesture: gesture)
        default:
            break
        }
    }
    
    // MARK: Private methods
    
    func getSystemEvents(eventStore: EKEventStore, calendars: [EKCalendar]) -> [EKEvent] {
        var startOffset = 0
        if calendarData.yearsCount.count > 1 {
            startOffset = calendarData.yearsCount.first ?? 0
        }
        var endOffset = 1
        if calendarData.yearsCount.count > 1 {
            endOffset = calendarData.yearsCount.last ?? 1
        }
        
        guard let startDate = style.calendar.date(byAdding: .year, value: startOffset, to: calendarData.date),
              let endDate = style.calendar.date(byAdding: .year, value: endOffset, to: calendarData.date) else {
            return []
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        return eventStore.events(matching: predicate)
    }
    
    private func authForSystemCalendars() {
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
        eventStore.requestAccess(to: .event) { [weak self] (access, error) in
            print("System calendars = \(self?.style.systemCalendars ?? []) - access = \(access), error = \(error?.localizedDescription ?? "nil")")
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

extension CalendarView: DisplayDelegate {
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
    
    // MARK: in progress
    func updateStyle(_ style: Style) {
        self.style = style
        dayView.updateStyle(style)
        weekView.updateStyle(style)
        monthView.updateStyle(style)
        yearView.updateStyle(style)
    }
}
