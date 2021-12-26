//
//  WeekView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class WeekView: UIView {
    
    struct Parameters {
        var visibleDates: [Date?] = []
        var data: WeekData
        var style: Style
    }
    
    private var parameters: Parameters
    private var timelineScale: CGFloat
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = ScrollDayHeaderView(parameters: .init(frame: CGRect(x: 0, y: 0,
                                                                       width: frame.width, height: heightView),
                                                         days: parameters.data.days,
                                                         date: parameters.data.date,
                                                         type: .week,
                                                         style: style))
        view.didSelectDate = { [weak self] (date, type) in
            if let item = date {
                self?.parameters.data.date = item
                self?.didSelectDate(item, type: type)
            }
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePage.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePage.changePage(type)
            let newTimeline = self.createTimelineView(frame: CGRect(origin: .zero, size: self.timelinePage.bounds.size))
            
            switch type {
            case .next:
                self.timelinePage.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        return view
    }()
    
    private func createTimelineView(frame: CGRect) -> TimelineView {
        var viewFrame = frame
        viewFrame.origin = .zero
        
        let view = TimelineView(parameters: .init(style: style, type: .week, scale: timelineScale), frame: viewFrame)
        view.delegate = self
        view.dataSource = self
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.didDeselectEvent(event, animated: true)
        }
        view.didChangeScale = { [weak self] (newScale) in
            if newScale != self?.timelineScale {
                self?.timelineScale = newScale
            }
        }
        return view
    }
    
    lazy var timelinePage: TimelinePageView = {
        var timelineFrame = frame
        
        if !style.headerScroll.isHidden {
            timelineFrame.origin.y = scrollHeaderDay.frame.height
            timelineFrame.size.height -= scrollHeaderDay.frame.height
        }
        
        let timelineViews = Array(0..<style.timeline.maxLimitCachedPages).reduce([]) { (acc, _) -> [TimelineView] in
            return acc + [createTimelineView(frame: timelineFrame)]
        }
        let page = TimelinePageView(maxLimit: style.timeline.maxLimitCachedPages,
                                    pages: timelineViews,
                                    frame: timelineFrame)
        return page
    }()
    
    private lazy var topBackgroundView: UIView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView))
        view.backgroundColor = style.headerScroll.colorBackground
        return view
    }()
    
    private lazy var titleInCornerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = parameters.style.headerScroll.colorTitleCornerDate
        return label
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        self.timelineScale = parameters.style.timeline.scale?.min ?? 1
        super.init(frame: frame)
        setUI()
        
        timelinePage.didSwitchTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let newTimeline = self.createTimelineView(frame: self.timelinePage.frame)
            
            switch type {
            case .next:
                self.nextDate()
                self.timelinePage.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.previousDate()
                self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
            }
            
            self.didSelectDate(self.scrollHeaderDay.date, type: .week)
        }
        
        timelinePage.willDisplayTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let nextDate: Date?
            switch type {
            case .next:
                nextDate = self.parameters.style.calendar.date(byAdding: .day,
                                                               value: 7,
                                                               to: self.parameters.data.date)
            case .previous:
                nextDate = self.parameters.style.calendar.date(byAdding: .day,
                                                               value: -7,
                                                               to: self.parameters.data.date)
            }
            
            if let offset = self.timelinePage.timelineView?.contentOffset {
                timeline.contentOffset = offset
            }
            
            timeline.create(dates: self.getVisibleDatesFor(date: nextDate ?? self.parameters.data.date),
                            events: self.parameters.data.events,
                            selectedDate: self.parameters.data.date)
        }
    }
    
    func setDate(_ date: Date) {
        parameters.data.date = date
        scrollHeaderDay.setDate(date)
        parameters.visibleDates = getVisibleDatesFor(date: date)
    }
    
    func reloadData(_ events: [Event]) {
        parameters.data.events = events
        timelinePage.timelineView?.create(dates: parameters.visibleDates,
                                           events: events,
                                           selectedDate: parameters.data.date)
    }
    
    private func getVisibleDatesFor(date: Date) -> [Date?] {
        guard let scrollDate = getScrollDate(date: date),
              let idx = parameters.data.days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return [] }
        
        var endIdx = idx + 7
        if endIdx > parameters.data.days.count {
            endIdx = parameters.data.days.count
        }
        let newVisibleDates = parameters.data.days[idx..<endIdx].map({ $0.date })
        return newVisibleDates
    }
    
    private func getScrollDate(date: Date) -> Date? {
        style.startWeekDay == .sunday ? date.startSundayOfWeek : date.startMondayOfWeek
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WeekView: DisplayDataSource {
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
    
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        dataSource?.willDisplayEventOptionMenu(event, type: type)
    }
    
}

extension WeekView {
    
    private func didSelectDate(_ date: Date, type: CalendarType) {
        let newDates = getVisibleDatesFor(date: date)
        if parameters.visibleDates != newDates {
            parameters.visibleDates = newDates
        }
        delegate?.didSelectDates([date], type: type, frame: nil)
    }
    
}

extension WeekView: CalendarSettingProtocol {
    
    var style: Style {
        parameters.style
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        var timelineFrame = timelinePage.frame
        timelineFrame.size.width = frame.width
        
        if !style.headerScroll.isHidden {
            topBackgroundView.frame.size.width = frame.width
            scrollHeaderDay.reloadFrame(frame)
            timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        } else {
            timelineFrame.size.height = frame.height
        }
        
        timelinePage.frame = timelineFrame
        timelinePage.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePage.timelineView?.create(dates: parameters.visibleDates,
                                           events: parameters.data.events,
                                           selectedDate: parameters.data.date)
        timelinePage.reloadCacheControllers()
    }
    
    func updateStyle(_ style: Style) {
        parameters.style = style
        scrollHeaderDay.updateStyle(style)
        timelinePage.updateStyle(style)
        timelinePage.reloadPages()
        setUI()
        reloadFrame(frame)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(topBackgroundView)
        topBackgroundView.addSubview(scrollHeaderDay)
        addSubview(timelinePage)
        timelinePage.isPagingEnabled = style.timeline.scrollDirections.contains(.horizontal)
    }
    
}

extension WeekView: TimelineDelegate {
    
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayEvents(events, dates: dates, type: .week)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: .week, frame: frame)
    }
    
    func nextDate() {
        parameters.data.date = scrollHeaderDay.calculateDateWithOffset(7, needScrollToDate: true)
    }
    
    func previousDate() {
        parameters.data.date = scrollHeaderDay.calculateDateWithOffset(-7, needScrollToDate: true)
    }
    
    func swipeX(transform: CGAffineTransform, stop: Bool) {
        guard !stop else { return }
        
        scrollHeaderDay.scrollHeaderByTransform(transform)
    }
    
    func didResizeEvent(_ event: Event, startTime: ResizeTime, endTime: ResizeTime) {
        var startComponents = DateComponents()
        startComponents.year = event.start.year
        startComponents.month = event.start.month
        startComponents.day = event.start.day
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        let startDate = style.calendar.date(from: startComponents)
        
        var endComponents = DateComponents()
        endComponents.year = event.end.year
        endComponents.month = event.end.month
        endComponents.day = event.end.day
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        let endDate = style.calendar.date(from: endComponents)
                
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var components = DateComponents()
        components.year = event.start.year
        components.month = event.start.month
        components.day = event.start.day
        components.hour = hour
        components.minute = minute
        let newDate = style.calendar.date(from: components)
        delegate?.didAddNewEvent(event, newDate)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDay: Int?) {
        var day = event.start.day
        if let newDayEvent = newDay {
            day = newDayEvent
        } else if let newDate = scrollHeaderDay.getDateByPointX(point.x), day != newDate.day {
            day = newDate.day
        }
        
        var startComponents = DateComponents()
        startComponents.year = event.start.year
        startComponents.month = event.start.month
        startComponents.day = day
        startComponents.hour = hour
        startComponents.minute = minute
        let startDate = style.calendar.date(from: startComponents)
        
        let hourOffset = event.end.hour - event.start.hour
        let minuteOffset = event.end.minute - event.start.minute
        var endComponents = DateComponents()
        endComponents.year = event.end.year
        endComponents.month = event.end.month
        if event.end.day != event.start.day {
            let offset = event.end.day - event.start.day
            endComponents.day = day + offset
        } else {
            endComponents.day = day
        }
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = style.calendar.date(from: endComponents)
        
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
}

#endif
