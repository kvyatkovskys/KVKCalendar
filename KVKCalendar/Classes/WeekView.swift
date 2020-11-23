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
    
    weak var delegate: CalendarDataProtocol?
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
            self?.timelineView.moveEvents(offset: offset, stop: stop)
        }
        return view
    }()
    
    lazy var timelineView: TimelineView = {
        var timelineFrame = frame
        timelineFrame.origin.y = scrollHeaderDay.frame.height
        timelineFrame.size.height -= scrollHeaderDay.frame.height
        let view = TimelineView(type: .week, timeHourSystem: data.timeSystem, style: style, frame: timelineFrame)
        view.delegate = self
        view.dataSource = self
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.deselectCalendarEvent(event)
        }
        return view
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
    }
    
    func setDate(_ date: Date) {
        timelineView.firstAutoScrollIsCompleted = false
        data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(events: [Event]) {
        data.events = events
        timelineView.create(dates: visibleDates, events: events, selectedDate: data.date)
    }
    
    private func getVisibleDates(date: Date) {
        guard let scrollDate = getScrollDate(date: date),
            let idx = data.days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return }
        
        var endIdx: Int
        if idx < 6 {
            endIdx = 0
        } else {
            endIdx = (idx + 6) >= data.days.count ? (data.days.count - 1) : (idx + 6)
        }
        let visibleDates = data.days[idx...endIdx].map({ $0.date })
        
        guard self.visibleDates != visibleDates else { return }
        self.visibleDates = visibleDates
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
        getVisibleDates(date: selectDate)
        delegate?.didSelectCalendarDate(selectDate, type: type, frame: nil)
    }
}

extension WeekView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        topBackgroundView.frame.size.width = frame.width
        scrollHeaderDay.reloadFrame(frame)
        
        var timelineFrame = timelineView.frame
        timelineFrame.size.width = frame.width
        timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        timelineView.reloadFrame(timelineFrame)
        timelineView.create(dates: visibleDates, events: data.events, selectedDate: data.date)
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        scrollHeaderDay.updateStyle(style)
        timelineView.updateStyle(style)
        setUI()
        setDate(data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(topBackgroundView)
        topBackgroundView.addSubview(scrollHeaderDay)
        addSubview(timelineView)
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
