//
//  DayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class DayView: UIView {
    
    private var parameters: Parameters
    private let tagEventViewer = -10
    private var timelineScale: CGFloat
    
    struct Parameters {
        var style: Style
        var data: DayData
    }
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    var scrollableWeekView = ScrollableWeekView(parameters: .init(frame: .zero,
                                                                  weeks: [],
                                                                  date: Date(),
                                                                  type: .day,
                                                                  style: Style()))
    
    var timelinePage = TimelinePageView(maxLimit: 0, pages: [], frame: .zero)
    
    private var topBackgroundView = UIView()
    private var isAvailableEventViewer: Bool {
        Platform.currentInterface != .phone
    }
    private var scrollToCurrentTimeOnlyOnInit: Bool?
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        self.timelineScale = parameters.style.timeline.scale?.min ?? 1
        super.init(frame: frame)
        
        if case .onlyOnInitForDate = parameters.style.timeline.scrollLineHourMode {
            scrollToCurrentTimeOnlyOnInit = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDate(_ date: Date, animated: Bool) {
        parameters.data.date = date
        scrollableWeekView.setDate(date)
    }
    
    func reloadData(_ events: [Event]) {
        parameters.data.recurringEvents = events.filter { $0.recurringType != .none }
        parameters.data.events = parameters.data.filterEvents(events, date: parameters.data.date)
        timelinePage.timelineView?.create(dates: [parameters.data.date],
                                          events: parameters.data.events,
                                          recurringEvents: parameters.data.recurringEvents,
                                          selectedDate: parameters.data.date)
    }
    
    func reloadEventViewerIfNeeded() {
        guard isAvailableEventViewer else { return }
        
        var defaultFrame = timelinePage.frame
        if let defaultWidth = style.timeline.widthEventViewer {
            defaultFrame.size.width = defaultWidth
        }
        updateEventViewer(frame: defaultFrame)
    }
    
    @discardableResult private func updateEventViewer(frame: CGRect) -> CGRect? {
        var viewerFrame = frame
        // hard reset the width when we change the orientation
        if UIDevice.current.orientation.isPortrait {
            viewerFrame.size.width = bounds.width * 0.5
            viewerFrame.origin.x = viewerFrame.width
        } else {
            viewerFrame.origin.x = bounds.width - viewerFrame.width
        }
        guard let eventViewer = dataSource?.willDisplayEventViewer(date: parameters.data.date,
                                                                   frame: viewerFrame) else { return nil }
        
        eventViewer.tag = tagEventViewer
        addSubview(eventViewer)
        return viewerFrame
    }
}

extension DayView: TimelineDelegate {
    
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayEvents(events, dates: dates, type: .day)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: .day, frame: frame)
    }
    
    func nextDate() {
        parameters.data.date = scrollableWeekView.calculateDateWithOffset(1, needScrollToDate: true)
    }
    
    func previousDate() {
        parameters.data.date = scrollableWeekView.calculateDateWithOffset(-1, needScrollToDate: true)
    }
    
    func didResizeEvent(_ event: Event, startTime: ResizeTime, endTime: ResizeTime) {
        var startComponents = DateComponents()
        startComponents.year = event.start.kvkYear
        startComponents.month = event.start.kvkMonth
        startComponents.day = event.start.kvkDay
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        let startDate = style.calendar.date(from: startComponents)
        
        var endComponents = DateComponents()
        endComponents.year = event.end.kvkYear
        endComponents.month = event.end.kvkMonth
        endComponents.day = event.end.kvkDay
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        let endDate = style.calendar.date(from: endComponents)
        
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var components = DateComponents()
        components.year = parameters.data.date.kvkYear
        components.month = parameters.data.date.kvkMonth
        components.day = parameters.data.date.kvkDay
        components.hour = hour
        components.minute = minute
        let date = style.calendar.date(from: components)
        delegate?.didAddNewEvent(event, date)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDay: Int?) {
        var startComponents = DateComponents()
        startComponents.year = event.start.kvkYear
        startComponents.month = event.start.kvkMonth
        startComponents.day = event.start.kvkDay
        startComponents.hour = hour
        startComponents.minute = minute
        let startDate = style.calendar.date(from: startComponents)
        
        let hourOffset = event.end.kvkHour - event.start.kvkHour
        let minuteOffset = event.end.kvkMinute - event.start.kvkMinute
        var endComponents = DateComponents()
        endComponents.year = event.end.kvkYear
        endComponents.month = event.end.kvkMonth
        endComponents.day = event.end.kvkDay
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = style.calendar.date(from: endComponents)
        
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
}

extension DayView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            parameters.style
        }
        set {
            parameters.style = newValue
            timelineScale = newValue.timeline.scale?.min ?? 1
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        var timelineFrame = timelinePage.frame
        
        if !style.headerScroll.isHidden {
            topBackgroundView.frame.size.width = frame.width
            scrollableWeekView.reloadFrame(frame)
            timelineFrame.size.height = frame.height - scrollableWeekView.frame.height
        } else {
            timelineFrame.size.height = frame.height
        }
        
        if isAvailableEventViewer {
            if let defaultWidth = style.timeline.widthEventViewer {
                timelineFrame.size.width = frame.width - defaultWidth
                
                if let idx = subviews.firstIndex(where: { $0.tag == tagEventViewer }) {
                    subviews[idx].removeFromSuperview()
                    var viewerFrame = timelineFrame
                    
                    let width: CGFloat
                    if UIDevice.current.orientation.isPortrait {
                        width = frame.width * 0.5
                        timelineFrame.size.width = frame.width - width
                    } else {
                        width = defaultWidth
                    }
                    
                    viewerFrame.size.width = width
                    if let resultViewerFrame = updateEventViewer(frame: viewerFrame) {
                        // notify when we did change the frame of viewer
                        delegate?.didChangeViewerFrame(resultViewerFrame)
                    }
                }
            } else {
                timelineFrame.size.width = frame.width
            }
        } else {
            timelineFrame.size.width = frame.width
        }
        
        timelinePage.frame = timelineFrame
        timelinePage.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePage.timelineView?.create(dates: [parameters.data.date],
                                          events: parameters.data.events,
                                          recurringEvents: parameters.data.recurringEvents,
                                          selectedDate: parameters.data.date)
        timelinePage.reloadCachedControllers()
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        let reload = self.style != style
        self.style = style
        setUI(reload: reload || force)
        reloadFrame(frame)
    }
    
    func setUI(reload: Bool) {
        subviews.forEach { $0.removeFromSuperview() }
        
        if reload {
            topBackgroundView = setupTopBackgroundView()
            scrollableWeekView = setupScrollableWeekView()
            scrollableWeekView.updateStyle(style, force: reload)
            
            if !parameters.style.headerScroll.isHidden {
                addSubview(topBackgroundView)
                topBackgroundView.addSubview(scrollableWeekView)
            }
            
            timelinePage = setupTimelinePageView()
            timelinePage.didSwitchTimelineView = { [weak self] (_, type) in
                guard let self = self else { return }
                
                let newTimeline = self.createTimelineView(frame: self.timelinePage.bounds)
                switch type {
                case .next:
                    self.nextDate()
                    self.timelinePage.addNewTimelineView(newTimeline, to: .end)
                case .previous:
                    self.previousDate()
                    self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
                }
                
                self.delegate?.didSelectDates([self.parameters.data.date], type: .day, frame: nil)
            }
            
            timelinePage.willDisplayTimelineView = { [weak self] (timeline, type) in
                guard let self = self else { return }
                
                let nextDate: Date
                switch type {
                case .next:
                    nextDate = self.style.calendar.date(byAdding: .day,
                                                        value: 1,
                                                        to: self.parameters.data.date) ?? self.parameters.data.date
                case .previous:
                    nextDate = self.style.calendar.date(byAdding: .day,
                                                        value: -1,
                                                        to: self.parameters.data.date) ?? self.parameters.data.date
                }
                
                timeline.create(dates: [nextDate],
                                events: self.parameters.data.events,
                                recurringEvents: self.parameters.data.recurringEvents,
                                selectedDate: self.parameters.data.date)
            }
            timelinePage.updateStyle(style, force: reload)
        }
        addSubview(timelinePage)
        timelinePage.isPagingEnabled = style.timeline.scrollDirections.contains(.horizontal)
        reloadEventViewerIfNeeded()
    }
    
    private func createTimelineView(frame: CGRect) -> TimelineView {
        var viewFrame = frame
        viewFrame.origin = .zero
        
        let view = TimelineView(parameters: .init(style: style, type: .day, scale: timelineScale,
                                                  scrollToCurrentTimeOnlyOnInit: scrollToCurrentTimeOnlyOnInit),
                                frame: viewFrame)
        view.delegate = self
        view.dataSource = dataSource
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.didDeselectEvent(event, animated: true)
        }
        view.didChangeParameters = { [weak self] (params) in
            if params.scale != self?.timelineScale {
                self?.timelineScale = params.scale
            }
            if params.scrollToCurrentTimeOnlyOnInit != self?.scrollToCurrentTimeOnlyOnInit {
                self?.scrollToCurrentTimeOnlyOnInit = params.scrollToCurrentTimeOnlyOnInit
            }
        }
        return view
    }
    
    private func setupTimelinePageView() -> TimelinePageView {
        var timelineFrame = frame
        
        if !style.headerScroll.isHidden {
            timelineFrame.origin.y = scrollableWeekView.frame.height
            timelineFrame.size.height -= scrollableWeekView.frame.height
        }
        
        if isAvailableEventViewer {
            if UIDevice.current.orientation.isPortrait {
                timelineFrame.size.width = UIScreen.main.bounds.width * 0.5
            } else {
                timelineFrame.size.width -= style.timeline.widthEventViewer ?? 0
            }
        }
        
        let timelineViews = Array(0..<style.timeline.maxLimitCachedPages).reduce([]) { (acc, _) -> [TimelineView] in
            acc + [createTimelineView(frame: timelineFrame)]
        }
        let page = TimelinePageView(maxLimit: style.timeline.maxLimitCachedPages,
                                    pages: timelineViews,
                                    frame: timelineFrame)
        return page
    }
    
    private func setupScrollableWeekView() -> ScrollableWeekView {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = ScrollableWeekView(parameters: .init(frame: CGRect(x: 0, y: 0,
                                                                      width: frame.width,
                                                                      height: heightView),
                                                        weeks: parameters.data.daysBySection,
                                                        date: parameters.data.date,
                                                        type: .day,
                                                        style: style))
        view.dataSource = dataSource
        view.didSelectDate = { [weak self] (date, type) in
            if let item = date {
                self?.parameters.data.date = item
                self?.delegate?.didSelectDates([item], type: type, frame: nil)
            }
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePage.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePage.changePage(type)
            let newTimeline = self.createTimelineView(frame: self.timelinePage.bounds)
            switch type {
            case .next:
                self.timelinePage.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        return view
    }
    
    private func setupTopBackgroundView() -> UIView {
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
    }
}

#endif
