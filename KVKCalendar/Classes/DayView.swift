//
//  DayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class DayView: UIView {
    private var style: Style
    private var data: DayData

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
                                       type: .day,
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
        
        let view = TimelineView(type: .day, timeHourSystem: data.timeSystem, style: style, frame: viewFrame)
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
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if UIDevice.current.orientation.isPortrait {
                timelineFrame.size.width = UIScreen.main.bounds.width * 0.5
            } else {
                timelineFrame.size.width -= style.timeline.widthEventViewer
            }
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
        if let blur = style.headerScroll.backgroundBlurStyle {
            view.setBlur(style: blur)
        } else {
            view.backgroundColor = style.headerScroll.colorBackground
        }
        return view
    }()
    
    init(data: DayData, frame: CGRect, style: Style) {
        self.style = style
        self.data = data
        super.init(frame: frame)
        setUI()
        
        timelinePages.didSwitchTimelineView = { [weak self] (_, type) in
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
                nextDate = self.style.calendar.date(byAdding: .day, value: 1, to: self.data.date)
            case .previous:
                nextDate = self.style.calendar.date(byAdding: .day, value: -1, to: self.data.date)
            }
            
            timeline.create(dates: [nextDate], events: self.data.events, selectedDate: self.data.date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addEventView(view: UIView) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        var eventFrame = timelinePages.frame
        
        eventFrame.origin.x = eventFrame.width
        if UIDevice.current.orientation.isPortrait {
            eventFrame.size.width = UIScreen.main.bounds.width * 0.5
        } else {
            eventFrame.size.width = style.timeline.widthEventViewer
        }
        view.frame = eventFrame
        view.tag = -1
        addSubview(view)
        delegate?.getEventViewerFrame(eventFrame)
    }
    
    func setDate(_ date: Date) {
        data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(_ events: [Event]) {
        data.events = events
        timelinePages.timelineView?.create(dates: [data.date], events: events, selectedDate: data.date)
    }
}

extension DayView: DisplayDataSource {
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        return dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
    
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? {
        return dataSource?.willDisplayContextMenu(event, date: date)
    }
}

extension DayView {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType) {
        guard let selectDate = date else { return }
        
        data.date = selectDate
        delegate?.didSelectCalendarDate(selectDate, type: type, frame: nil)
    }
}

extension DayView: TimelineDelegate {
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayCalendarEvents(events, dates: dates, type: .day)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 1, needScrollToDate: true)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -1, needScrollToDate: true)
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
        components.year = data.date.year
        components.month = data.date.month
        components.day = data.date.day
        components.hour = hour
        components.minute = minute
        let date = style.calendar.date(from: components)
        delegate?.didAddCalendarEvent(event, date)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDay: Int?) {
        var startComponents = DateComponents()
        startComponents.year = event.start.year
        startComponents.month = event.start.month
        startComponents.day = event.start.day
        startComponents.hour = hour
        startComponents.minute = minute
        let startDate = style.calendar.date(from: startComponents)
        
        let hourOffset = event.end.hour - event.start.hour
        let minuteOffset = event.end.minute - event.start.minute
        var endComponents = DateComponents()
        endComponents.year = event.end.year
        endComponents.month = event.end.month
        endComponents.day = event.end.day
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = style.calendar.date(from: endComponents)
                
        delegate?.didChangeCalendarEvent(event, start: startDate, end: endDate)
    }
}

extension DayView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        var timelineFrame = timelinePages.frame
        
        if !style.headerScroll.isHidden {
            topBackgroundView.frame.size.width = frame.width
            scrollHeaderDay.reloadFrame(frame)
            timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        } else {
            timelineFrame.size.height = frame.height
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            timelineFrame.size.width = frame.width - style.timeline.widthEventViewer
            if let idx = subviews.firstIndex(where: { $0.tag == -1 }) {
                let eventView = subviews[idx]
                var eventFrame = timelineFrame
                
                let pointX: CGFloat
                let width: CGFloat
                if UIDevice.current.orientation.isPortrait {
                    width = frame.width * 0.5
                    pointX = frame.width - width
                    timelineFrame.size.width = frame.width - width
                } else {
                    pointX = eventFrame.width
                    width = style.timeline.widthEventViewer
                }
                
                eventFrame.origin.x = pointX
                eventFrame.size.width = width
                eventView.frame = eventFrame
                delegate?.getEventViewerFrame(eventFrame)
            }
        } else {
            timelineFrame.size.width = frame.width
        }
        
        timelinePages.frame = timelineFrame
        timelinePages.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePages.timelineView?.create(dates: [data.date], events: data.events, selectedDate: data.date)
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
        
        if !style.headerScroll.isHidden {
            addSubview(topBackgroundView)
            topBackgroundView.addSubview(scrollHeaderDay)
        }
        addSubview(timelinePages)
    }
}
