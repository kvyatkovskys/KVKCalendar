//
//  DayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class DayView: UIView {
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    private var parameters: Parameters
    private let tagEventViewer = -10
    
    struct Parameters {
        var style: Style
        var data: DayData
    }
    
    lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = ScrollDayHeaderView(parameters: .init(frame: CGRect(x: 0, y: 0,
                                                                       width: frame.width,
                                                                       height: heightView),
                                                         days: parameters.data.days,
                                                         date: parameters.data.date,
                                                         type: .day,
                                                         style: style))
        view.didSelectDate = { [weak self] (date, type) in
            if let item = date {
                self?.parameters.data.date = item
                self?.delegate?.didSelectDates([item], type: type, frame: nil)
            }
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePages.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePages.changePage(type)
            let newTimeline = self.createTimelineView(frame: CGRect(origin: .zero,
                                                                    size: self.timelinePages.bounds.size))
            
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
        
        let view = TimelineView(type: .day, style: style, frame: viewFrame)
        view.delegate = self
        view.dataSource = self
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.didDeselectEvent(event, animated: true)
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
                timelineFrame.size.width -= style.timeline.widthEventViewer ?? 0
            }
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
        if let blur = style.headerScroll.backgroundBlurStyle {
            view.setBlur(style: blur)
        } else {
            view.backgroundColor = style.headerScroll.colorBackground
        }
        return view
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
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
            
            self.delegate?.didSelectDates([self.parameters.data.date], type: .day, frame: nil)
        }
        
        timelinePages.willDisplayTimelineView = { [weak self] (timeline, type) in
            guard let self = self else { return }
            
            let nextDate: Date?
            switch type {
            case .next:
                nextDate = self.style.calendar.date(byAdding: .day,
                                                           value: 1,
                                                           to: self.parameters.data.date)
            case .previous:
                nextDate = self.style.calendar.date(byAdding: .day,
                                                           value: -1,
                                                           to: self.parameters.data.date)
            }
            
            timeline.create(dates: [nextDate],
                            events: self.parameters.data.events,
                            selectedDate: self.parameters.data.date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDate(_ date: Date) {
        parameters.data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(_ events: [Event]) {
        parameters.data.events = events
        timelinePages.timelineView?.create(dates: [parameters.data.date],
                                           events: events,
                                           selectedDate: parameters.data.date)
    }
    
    func reloadEventViewer() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        var defaultFrame = timelinePages.frame
        if let defaultWidth = style.timeline.widthEventViewer {
            defaultFrame.size.width = defaultWidth
        }
        updateEventViewer(frame: defaultFrame)
    }
    
    @discardableResult private func updateEventViewer(frame: CGRect) -> CGRect? {
        var viewerFrame = frame
        // hard reset the width when we change the orientation
        if UIDevice.current.orientation.isPortrait {
            viewerFrame.size.width = UIScreen.main.bounds.width * 0.5
            viewerFrame.origin.x = viewerFrame.width
        } else {
            viewerFrame.origin.x = bounds.width - viewerFrame.width
        }
        guard let eventViewer = dataSource?.willDisplayEventViewer(date: parameters.data.date, frame: viewerFrame) else { return nil }
        
        eventViewer.tag = tagEventViewer
        addSubview(eventViewer)
        return viewerFrame
    }
}

extension DayView: DisplayDataSource {
    
    func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
        dataSource?.willDisplayEventView(event, frame: frame, date: date)
    }
    
    @available(iOS 14.0, *)
    func willDisplayEventOptionMenu(_ event: Event, type: CalendarType) -> (menu: UIMenu, customButton: UIButton?)? {
        dataSource?.willDisplayEventOptionMenu(event, type: type)
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
        parameters.data.date = scrollHeaderDay.calculateDateWithOffset(1, needScrollToDate: true)
    }
    
    func previousDate() {
        parameters.data.date = scrollHeaderDay.calculateDateWithOffset(-1, needScrollToDate: true)
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
        components.year = parameters.data.date.year
        components.month = parameters.data.date.month
        components.day = parameters.data.date.day
        components.hour = hour
        components.minute = minute
        let date = style.calendar.date(from: components)
        delegate?.didAddNewEvent(event, date)
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
                
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
}

extension DayView: CalendarSettingProtocol {
    
    var style: Style {
        parameters.style
    }
    
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
        
        timelinePages.frame = timelineFrame
        timelinePages.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePages.timelineView?.create(dates: [parameters.data.date],
                                           events: parameters.data.events,
                                           selectedDate: parameters.data.date)
        timelinePages.reloadCacheControllers()
    }
    
    func updateStyle(_ style: Style) {
        parameters.style = style
        scrollHeaderDay.updateStyle(style)
        timelinePages.updateStyle(style)
        timelinePages.reloadPages()
        setUI()
        reloadFrame(frame)
        reloadEventViewer()
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        if !parameters.style.headerScroll.isHidden {
            addSubview(topBackgroundView)
            topBackgroundView.addSubview(scrollHeaderDay)
        }
        addSubview(timelinePages)
        timelinePages.isPagingEnabled = style.timeline.scrollDirections.contains(.horizontal)
    }
}

#endif
