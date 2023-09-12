//
//  KVKCalendarView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 14.12.2020.
//

#if os(iOS)

import UIKit
import EventKit

extension KVKCalendarView {
    // MARK: Public methods
    
    /// **DEPRECATED**
    @available(*, deprecated, renamed: "CalendarDataSource.willDisplayEventViewer")
    public func addEventViewToDay(view: UIView) {}
    
    public func set(type: CalendarType, date: Date? = nil, animated: Bool = true) {
        parameters.type = type
        switchCalendarType(type)
        
        if let dt = date {
            scrollTo(dt, animated: animated)
        }
    }
    
    public func reloadData() {
        
        func reload(systemEvents: [EKEvent] = []) {
            let events = dataSource?.eventsForCalendar(systemEvents: systemEvents) ?? []
            
            switch parameters.type {
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
    
    public func scrollTo(_ date: Date, animated: Bool = true) {
        switch parameters.type {
        case .day:
            dayView.setDate(date, animated: false)
        case .week:
            weekView.setDate(date, animated: false)
        case .month:
            monthView.setDate(date, animated: animated)
        case .year:
            yearView.setDate(date, animated: animated)
        case .list:
            listView.setDate(date, animated: animated)
        }
    }
    
    public func deselectEvent(_ event: Event, animated: Bool) {
        switch parameters.type {
        case .day:
            dayView.timelinePage.timelineView?.deselectEvent(event, animated: animated)
        case .week:
            weekView.timelinePage.timelineView?.deselectEvent(event, animated: animated)
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
        switch parameters.type {
        case .month:
            monthView.showSkeletonVisible(visible)
        case .list:
            listView.showSkeletonVisible(visible)
        default:
            break
        }
    }
    
    // MARK: Private methods
    
    private var calendarQueue: DispatchQueue {
        DispatchQueue(label: "kvk.calendar.com", qos: .default, attributes: .concurrent)
    }
    
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
        
        calendarQueue.async { [weak self] in
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
    
    private func requestAccessSystemCalendars(_ calendars: Set<String>,
                                              store: EKEventStore,
                                              completion: @escaping (Bool) -> Void) {
        func proxyCompletion(access: Bool, status: EKAuthorizationStatus, error: Error?) {
            print("System calendars = \(calendars) - access = \(access), error = \(error?.localizedDescription ?? "nil"), status = \(status)")
            completion(access)
        }
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            completion(true)
        default:
            //           temporary disabled
            //            if #available(iOS 17.0, *) {
            //                store.requestFullAccessToEvents { (access, error) in
            //                    proxyCompletion(access: access, status: status, error: error)
            //                }
            //            } else {
            store.requestAccess(to: .event) { (access, error) in
                proxyCompletion(access: access, status: status, error: error)
            }
            //            }
        }
    }
    
    private func switchCalendarType(_ type: CalendarType) {
        parameters.type = type
        subviews.forEach { $0.removeFromSuperview() }
        
        switch parameters.type {
        case .day:
            addSubview(dayView)
        case .week:
            addSubview(weekView)
        case .month:
            addSubview(monthView)
        case .year:
            addSubview(yearView)
            setupConstraintsForView(yearView)
        case .list:
            addSubview(listView)
            setupConstraintsForView(listView)
            listView.setupConstraints()
            reloadData()
        }        
    }
    
    private func deactivateConstraintsForView(_ view: UIView) {
        NSLayoutConstraint.deactivate(view.constraints)
    }
    
    private func setupConstraintsForView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let top = view.topAnchor.constraint(equalTo: topAnchor)
        let bottom = view.bottomAnchor.constraint(equalTo: bottomAnchor)
        let left = view.leftAnchor.constraint(equalTo: leftAnchor)
        let right = view.rightAnchor.constraint(equalTo: rightAnchor)
        NSLayoutConstraint.activate([top, bottom, left, right])
    }
}

extension KVKCalendarView: DisplayDataSource {
    public func dequeueCell<T>(parameter: CellParameter, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarCellProtocol? where T : UIScrollView {
        dataSource?.dequeueCell(parameter: parameter, type: type, view: view, indexPath: indexPath)
    }
    
    public func dequeueHeader<T>(date: Date?, type: CalendarType, view: T, indexPath: IndexPath) -> KVKCalendarHeaderProtocol? where T : UIScrollView {
        dataSource?.dequeueHeader(date: date, type: type, view: view, indexPath: indexPath)
    }
    
    public func willDisplayCollectionView(frame: CGRect, type: CalendarType) -> UICollectionView? {
        dataSource?.willDisplayCollectionView(frame: frame, type: type)
    }
    
    public func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }

    public func willDisplayHeaderSubview(date: Date?, frame: CGRect, type: CalendarType) -> UIView? {
        dataSource?.willDisplayHeaderSubview(date: date, frame: frame, type: type)
    }
    
    /// **Temporary disabled**
    private func willDisplayHeaderView(date: Date?, frame: CGRect, type: CalendarType) -> UIView? {
        dataSource?.willDisplayHeaderView(date: date, frame: frame, type: type)
    }
    
    public func willDisplayEventViewer(date: Date, frame: CGRect) -> UIView? {
        dataSource?.willDisplayEventViewer(date: date, frame: frame)
    }
    
    @available(iOS 14.0, *)
    public func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        dataSource?.willDisplayEventOptionMenu(event, type: type)
    }
    
    public func dequeueMonthViewEvents(_ events: [Event], date: Date, frame: CGRect) -> UIView? {
        dataSource?.dequeueMonthViewEvents(events, date: date, frame: frame)
    }
    
    public func dequeueAllDayViewEvent(_ event: Event, date: Date, frame: CGRect) -> UIView? {
        dataSource?.dequeueAllDayViewEvent(event, date: date, frame: frame)
    }
    
    public func dequeueTimeLabel(_ label: TimelineLabel) -> (current: TimelineLabel, others: [UILabel])? {
        dataSource?.dequeueTimeLabel(label)
    }
    
    public func dequeueAllDayCornerHeader(date: Date, frame: CGRect) -> UIView? {
        dataSource?.dequeueAllDayCornerHeader(date: date, frame: frame)
    }

    public func dequeueCornerHeader(date: Date, frame: CGRect, type: CalendarType) -> UIView? {
        dataSource?.dequeueCornerHeader(date: date, frame: frame, type: type)
    }
    
    public func willDisplaySectionsInListView(_ sections: [ListViewData.SectionListView]) {
        dataSource?.willDisplaySectionsInListView(sections)
    }
    
}

extension KVKCalendarView: DisplayDelegate {
    public func sizeForHeader(_ date: Date?, type: CalendarType) -> CGSize? {
        delegate?.sizeForHeader(date, type: type)
    }
    
    public func sizeForCell(_ date: Date?, type: CalendarType) -> CGSize? {
        delegate?.sizeForCell(date, type: type)
    }
    
    func didDisplayEvents(_ events: [Event], dates: [Date?], type: CalendarType) {
        guard parameters.type == type else { return }
        
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
    
    public func willSelectDate(_ date: Date, type: CalendarType) {
        delegate?.willSelectDate(date, type: type)
    }
    
    public func didUpdateStyle(_ style: Style, type: CalendarType) {
        updateStyle(style)
        reloadData()
        delegate?.didUpdateStyle(style, type: type)
    }
    
    public func didDisplayHeaderTitle(_ date: Date, style: Style, type: CalendarType) {
        delegate?.didDisplayHeaderTitle(date, style: style, type: type)
    }
}

extension KVKCalendarView {
    
    public var style: Style {
        get {
            parameters.style
        }
        set {
            parameters.style = newValue
        }
    }
    
    public func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        
        viewCaches.values.forEach { (viewCache) in
            if let currentView = viewCache as? CalendarSettingProtocol, viewCache.frame != frame {
                currentView.reloadFrame(frame)
            }
        }
    }
    
    @available(swift, deprecated: 0.6.5, message: "Is no longer used.")
    public func updateDaysBySectionInWeekView(date: Date? = nil) {
        var updatedData = calendarData
        if let dt = date {
            updatedData = CalendarData(date: dt, years: 4, style: style)
        }
        weekView.reloadDays(data: updatedData, style: style)
        weekView.updateScrollableWeeks()
        weekView.reloadVisibleDates()
    }
    
    public func updateStyle(_ style: Style) {
        let updateDaysInWeek = self.style.week.daysInOneWeek != style.week.daysInOneWeek
        self.style = style.adaptiveStyle
        
        if updateDaysInWeek {
            weekView.reloadDays(data: calendarData, style: self.style)
        }
        
        reloadAllStyles(self.style, force: false)
        
        if updateDaysInWeek {
            weekView.reloadVisibleDates()
        }
        
        switch parameters.type {
        case .month:
            monthView.setDate(monthData.date, animated: true)
        case .year:
            yearView.setDate(yearData.date, animated: true)
        default:
            break
        }
    }
    
    func reloadAllStyles(_ style: Style, force: Bool) {
        viewCaches.values.forEach { (viewCache) in
            if let currentView = viewCache as? CalendarSettingProtocol {
                currentView.updateStyle(style, force: force)
            }
        }
    }

}

#endif
