//
//  WeekViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekViewCalendar: UIView {
    private var visibleDates: [Date?] = []
    weak var delegate: CalendarPrivateDelegate?
    
    private var data: WeekData
    private var style: Style
    
    lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenTitleDate {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightTitleDate
        }
        let offsetX = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        let view = ScrollDayHeaderView(frame: CGRect(x: offsetX, y: 0, width: frame.width - offsetX, height: heightView),
                                       days: data.days,
                                       date: data.date,
                                       type: .week,
                                       style: style)
        view.delegate = self
        return view
    }()
    
    private lazy var timelineView: TimelineView = {
        var timelineFrame = frame
        timelineFrame.origin.y = scrollHeaderDay.frame.height
        timelineFrame.size.height -= scrollHeaderDay.frame.height
        let view = TimelineView(type: .week, timeHourSystem: data.timeSystem, style: style, frame: timelineFrame)
        view.delegate = self
        return view
    }()
    
    private lazy var topBackgroundView: UIView = {
        let heightView: CGFloat
        if style.headerScroll.isHiddenTitleDate {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightTitleDate
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
        data.date = date
        scrollHeaderDay.setDate(date)
    }
    
    func reloadData(events: [Event]) {
        data.events = events
        timelineView.create(dates: visibleDates, events: events, selectedDate: data.date)
    }
    
    private func addCornerLabel() {
        if !style.headerScroll.isHiddenCornerTitleDate {
            titleInCornerLabel.frame = CGRect(x: 0, y: 0, width: scrollHeaderDay.frame.origin.x, height: style.headerScroll.heightHeaderWeek)
            setDateToTitleCorner(data.date)
            
            if subviews.contains(titleInCornerLabel) {
                titleInCornerLabel.removeFromSuperview()
            }
            addSubview(titleInCornerLabel)
        }
    }
    
    private func setDateToTitleCorner(_ date: Date?) {
        if let date = date, !style.headerScroll.isHiddenCornerTitleDate {
            titleInCornerLabel.text = style.headerScroll.formatterCornerTitle.string(from: date)
        }
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

extension WeekViewCalendar: ScrollDayHeaderDelegate {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType) {
        guard let selectDate = date else { return }
        
        data.date = selectDate
        getVisibleDates(date: selectDate)
        delegate?.didSelectCalendarDate(selectDate, type: type, frame: nil)
        setDateToTitleCorner(selectDate)
    }
}

extension WeekViewCalendar: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        topBackgroundView.frame.size.width = frame.width
        scrollHeaderDay.reloadFrame(frame)
        
        var timelineFrame = timelineView.frame
        timelineFrame.size.width = frame.width
        timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        timelineView.reloadFrame(timelineFrame)
        timelineView.create(dates: visibleDates, events: data.events, selectedDate: data.date)
        
        addCornerLabel()
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
        addCornerLabel()
    }
}

extension WeekViewCalendar: TimelineDelegate {
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayCalendarEvents(events, dates: dates, type: .week)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 7)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -7)
    }
    
    func swipeX(transform: CGAffineTransform, stop: Bool) {
        guard !stop else { return }
        
        scrollHeaderDay.scrollHeaderByTransform(transform)
    }
    
    func didAddEvent(minute: Int, hour: Int, point: CGPoint) {
        var date = data.date
        if let newDate = scrollHeaderDay.getDateByPointX(point.x) {
            date = newDate
        }
        
        var components = DateComponents()
        components.year = date.year
        components.month = date.month
        components.day = date.day
        components.hour = hour
        components.minute = minute
        let newDate = style.calendar.date(from: components)
        delegate?.didAddCalendarEvent(newDate)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var day = event.start.day
        if let newDate = scrollHeaderDay.getDateByPointX(point.x), day != newDate.day {
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
        endComponents.day = day
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = style.calendar.date(from: endComponents)
        
        delegate?.didChangeCalendarEvent(event, start: startDate, end: endDate)
    }
}
