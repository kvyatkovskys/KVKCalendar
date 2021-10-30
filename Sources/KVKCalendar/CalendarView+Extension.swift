//
//  CalendarView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 14.12.2020.
//

#if os(iOS)

import UIKit
import EventKit

extension CalendarView {
    // MARK: Public methods
    
    /// **DEPRECATED**
    @available(*, deprecated, renamed: "CalendarDataSource.willDisplayEventViewer")
    public func addEventViewToDay(view: UIView) {}
    
    public func set(type: CalendarType, date: Date? = nil) {
        self.type = type
        switchTypeCalendar(type: type)
        
        if let dt = date {
            scrollTo(dt)
        }
    }
    
    public func reloadData() {
        
        func reload(systemEvents: [EKEvent] = []) {
            let events = dataSource?.eventsForCalendar(systemEvents: systemEvents) ?? []
            
            switch type {
            case .day:
                dayView.reloadData(events)
            case .week:
                weekView.reloadData(events)
            case .month:
                monthView.reloadData(events)
            case .list:
                listView.reloadData(events)
            default:
                break
            }
        }
        
        if !style.systemCalendars.isEmpty {
            requestAccessSystemCalendars(style.systemCalendars, store: eventStore) { [weak self] (result) in
                guard let self = self else {
                    DispatchQueue.main.async {
                        reload()
                    }
                    return
                }
                
                if result {
                    self.getSystemEvents(store: self.eventStore, calendars: self.style.systemCalendars) { (systemEvents) in
                        DispatchQueue.main.async {
                            reload(systemEvents: systemEvents)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        reload()
                    }
                }
            }
        } else {
            reload()
        }
    }
    
    public func scrollTo(_ date: Date, animated: Bool? = nil) {
        switch type {
        case .day:
            dayView.setDate(date)
        case .week:
            weekView.setDate(date)
        case .month:
            monthView.setDate(date, animated: animated)
        case .year:
            yearView.setDate(date)
        case .list:
            listView.setDate(date)
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
    
    public func showSkeletonLoading(_ visible: Bool) {
        switch type {
        case .month:
            monthView.showSkeletonVisible(visible)
        case .list:
            listView.showSkeletonVisible(visible)
        default:
            break
        }
    }
    
    // MARK: Private methods
    
    private func getSystemEvents(store: EKEventStore, calendars: Set<String>, completion: @escaping ([EKEvent]) -> Void) {
        guard !calendars.isEmpty else {
            completion([])
            return
        }
        
        let systemCalendars = store.calendars(for: .event).filter({ calendars.contains($0.title) })
        guard !systemCalendars.isEmpty else {
            completion([])
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                completion([])
                return
            }
            
            var startOffset = 0
            var endOffset = 1
            if self.calendarData.yearsCount.count > 1 {
                startOffset = self.calendarData.yearsCount.first ?? 0
                endOffset = self.calendarData.yearsCount.last ?? 1
            }
            
            guard let startDate = self.style.calendar.date(byAdding: .year,
                                                           value: startOffset,
                                                           to: self.calendarData.date),
                  let endDate = self.style.calendar.date(byAdding: .year,
                                                         value: endOffset,
                                                         to: self.calendarData.date) else {
                        completion([])
                      return
                  }
            
            let predicate = store.predicateForEvents(withStart: startDate,
                                                     end: endDate,
                                                     calendars: systemCalendars)
            let items = store.events(matching: predicate)
            completion(items)
        }
    }
    
    private func requestAccessSystemCalendars(_ calendars: Set<String>, store: EKEventStore, completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        store.requestAccess(to: .event) { (access, error) in
            print("System calendars = \(calendars) - access = \(access), error = \(error?.localizedDescription ?? "nil"), status = \(status.rawValue)")
            completion(access)
        }
    }
    
    private func switchTypeCalendar(type: CalendarType) {
        self.type = type
        currentViewCache?.removeFromSuperview()
        
        switch self.type {
        case .day:
            addSubview(dayView)
            currentViewCache = dayView
        case .week:
            addSubview(weekView)
            currentViewCache = weekView
        case .month:
            addSubview(monthView)
            currentViewCache = monthView
        case .year:
            addSubview(yearView)
            currentViewCache = yearView
        case .list:
            addSubview(listView)
            currentViewCache = listView
            reloadData()
        }
        
        if let cacheView = currentViewCache as? CalendarSettingProtocol, cacheView.currentStyle != style {
            cacheView.updateStyle(style)
        }
    }
}

extension CalendarView: DisplayDataSource {
    public func dequeueCell<T>(dateParameter: DateParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol? where T : UIScrollView {
        return dataSource?.dequeueCell(dateParameter: dateParameter, type: type, view: view, indexPath: indexPath)
    }
    
    public func dequeueHeader<T>(date: Date?, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarHeaderProtocol? where T : UIScrollView {
        return dataSource?.dequeueHeader(date: date, type: type, view: view, indexPath: indexPath)
    }
    
    public func willDisplayCollectionView(frame: CGRect, type: CalendarType) -> UICollectionView? {
        return dataSource?.willDisplayCollectionView(frame: frame, type: type)
    }
    
    public func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }

    public func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? {
        return dataSource?.willDisplayHeaderSubview(date: date, frame: frame, type: type)
    }
    
    public func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
        return dataSource?.willDisplayEventViewer(date: date, frame: frame)
    }
    
    @available(iOS 14.0, *)
    public func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        return dataSource?.willDisplayEventOptionMenu(event, type: type)
    }
    
    public func dequeueMonthViewEvents(_ events: [Event], date: Date, frame: CGRect) -> UIView? {
        return dataSource?.dequeueMonthViewEvents(events, date: date, frame: frame)
    }
}

extension CalendarView: DisplayDelegate {
    public func sizeForHeader(_ date: Date?, type: CalendarType) -> CGSize? {
        delegate?.sizeForHeader(date, type: type)
    }
    
    public func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? {
        delegate?.sizeForCell(date, type: type)
    }
    
    func didDisplayEvents(_ events: [Event], dates: [Date?], type: CalendarType) {
        guard self.type == type else { return }
        
        delegate?.didDisplayEvents(events, dates: dates)
    }
    
    public func didSelectDates(_ dates: [Date], type: CalendarType, frame: CGRect?) {
        delegate?.didSelectDates(dates, type: type, frame: frame)
    }
    
    public func didDeselectEvent(_ event: Event, animated: Bool) {
        delegate?.didDeselectEvent(event, animated: animated)
    }
    
    public func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: type, frame: frame)
    }
    
    public func didSelectMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectMore(date, frame: frame)
    }
    
    public func didAddNewEvent(_ event: Event, _ date: Date?) {
        delegate?.didAddNewEvent(event, date)
    }
    
    public func didChangeEvent(_ event: Event, start: Date?, end: Date?) {
        delegate?.didChangeEvent(event, start: start, end: end)
    }
    
    public func didChangeViewerFrame(_ frame: CGRect) {
        var newFrame = frame
        newFrame.origin = .zero
        delegate?.didChangeViewerFrame(newFrame)
    }
}

extension CalendarView: CalendarSettingProtocol {
    var currentStyle: Style {
        return style
    }
    
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        
        if let currentView = currentViewCache as? CalendarSettingProtocol {
            currentView.reloadFrame(frame)
        }
    }
    
    public func updateStyle(_ style: Style) {
        self.style = style.checkStyle
        
        if let currentView = currentViewCache as? CalendarSettingProtocol {
            currentView.updateStyle(self.style)
        }
    }
    
    func setUI() {
        
    }
}

#endif
