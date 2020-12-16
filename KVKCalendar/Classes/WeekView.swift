//
//  WeekView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekView: UIView {
    private var visibleDates: [Date?] = []
    private var data: WeekData
    private var style: Style
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = ScrollDayHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView),
                                       days: data.days,
                                       date: data.date,
                                       type: .week,
                                       style: style)
        view.didSelectDate = { [weak self] (date, type) in
            self?.didSelectDateScrollHeader(date, type: type)
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePages.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePages.changePage(type)
            let newTimeline = self.createTimelineView(frame: CGRect(origin: .zero, size: self.timelinePages.bounds.size))
            
            switch type {
            case .next:
                self.timelinePages.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.timelinePages.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        return view
    }()
    
    private func createTimelineView(frame: CGRect) -> TimelineView {
        var viewFrame = frame
        viewFrame.origin = .zero
        
        let view = TimelineView(type: .week, timeHourSystem: data.timeSystem, style: style, frame: viewFrame)
        view.delegate = self
        view.dataSource = self
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.deselectCalendarEvent(event)
        }
        return view
    }
    
    lazy var timelinePages: TimelinePageView = {
        var timelineFrame = frame
        
        if !style.headerScroll.isHidden {
            timelineFrame.origin.y = scrollHeaderDay.frame.height
            timelineFrame.size.height -= scrollHeaderDay.frame.height
        }
        
        let timelineViews = Array(0...9).reduce([]) { (acc, _) -> [TimelineView] in
            return acc + [createTimelineView(frame: timelineFrame)]
        }
        let page = TimelinePageView(pages: timelineViews, frame: timelineFrame)
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
        label.textColor = style.headerScroll.colorTitleCornerDate
        return label
    }()
    
    init(data: WeekData, frame: CGRect, style: Style) {
        self.style = style
        self.data = data
        super.init(frame: frame)
        setUI()
        
        timelinePages.didSwitchTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let newTimeline = self.createTimelineView(frame: self.timelinePages.frame)
            
            switch type {
            case .next:
                self.nextDate()
                self.timelinePages.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.previousDate()
                self.timelinePages.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        
        timelinePages.willDisplayTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let nextDate: Date?
            switch type {
            case .next:
                nextDate = self.style.calendar.date(byAdding: .day, value: 7, to: self.data.date)
            case .previous:
                nextDate = self.style.calendar.date(byAdding: .day, value: -7, to: self.data.date)
            }
            
            if let offset = self.timelinePages.timelineView?.contentOffset {
                timeline.contentOffset = offset
            }
            
            timeline.create(dates: self.getVisibleDatesFor(date: nextDate ?? self.data.date), events: self.data.events, selectedDate: self.data.date)
        }
    }
    
    func setDate(_ date: Date) {
        data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(events: [Event]) {
        data.events = events
        timelinePages.timelineView?.create(dates: visibleDates, events: events, selectedDate: data.date)
    }
    
    private func getVisibleDatesFor(date: Date) -> [Date?] {
        guard let scrollDate = getScrollDate(date: date),
            let idx = data.days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return [] }
        
        let endIdx = idx + 7
        let newVisibleDates = data.days[idx..<endIdx].map({ $0.date })
        return newVisibleDates
    }
    
    private func getScrollDate(date: Date) -> Date? {
        return style.startWeekDay == .sunday ? date.startSundayOfWeek : date.startMondayOfWeek
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WeekView: DisplayDataSource {
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
}

extension WeekView {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType) {
        guard let selectDate = date else { return }
        
        data.date = selectDate
        let newDates = getVisibleDatesFor(date: selectDate)
        if visibleDates != newDates {
            visibleDates = newDates
        }
        delegate?.didSelectCalendarDate(selectDate, type: type, frame: nil)
    }
}

extension WeekView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        var timelineFrame = timelinePages.frame
        timelineFrame.size.width = frame.width
        
        if !style.headerScroll.isHidden {
            topBackgroundView.frame.size.width = frame.width
            scrollHeaderDay.reloadFrame(frame)
            timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        } else {
            timelineFrame.size.height = frame.height
        }
        
        timelinePages.frame = timelineFrame
        timelinePages.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePages.timelineView?.create(dates: visibleDates, events: data.events, selectedDate: data.date)
        timelinePages.reloadCacheControllers()
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        scrollHeaderDay.updateStyle(style)
        timelinePages.timelineView?.updateStyle(style)
        setUI()
        setDate(data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(topBackgroundView)
        topBackgroundView.addSubview(scrollHeaderDay)
        addSubview(timelinePages)
    }
}

extension WeekView: TimelineDelegate {
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayCalendarEvents(events, dates: dates, type: .week)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 7, needScrollToDate: true)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -7, needScrollToDate: true)
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
                
        delegate?.didChangeCalendarEvent(event, start: startDate, end: endDate)
    }
    
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var components = DateComponents()
        components.year = event.start.year
        components.month = event.start.month
        components.day = event.start.day
        components.hour = hour
        components.minute = minute
        let newDate = style.calendar.date(from: components)
        delegate?.didAddCalendarEvent(event, newDate)
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
        
        delegate?.didChangeCalendarEvent(event, start: startDate, end: endDate)
    }
}
