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
    
    private lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScrollStyle.isHiddenTitleDate {
            heightView = style.headerScrollStyle.heightHeaderWeek
        } else {
            heightView = style.headerScrollStyle.heightHeaderWeek + style.headerScrollStyle.heightTitleDate
        }
        let offsetX = style.timelineStyle.widthTime + style.timelineStyle.offsetTimeX + style.timelineStyle.offsetLineLeft
        let view = ScrollDayHeaderView(frame: CGRect(x: offsetX,
                                                     y: 0,
                                                     width: frame.width - offsetX,
                                                     height: heightView),
                                       days: data.days,
                                       date: data.date,
                                       type: .week,
                                       style: style.headerScrollStyle,
                                       calendar: style.calendar)
        view.delegate = self
        return view
    }()
    
    private lazy var timelineView: TimelineView = {
        var timelineFrame = frame
        timelineFrame.origin.y = scrollHeaderDay.frame.height
        timelineFrame.size.height -= scrollHeaderDay.frame.height
        let view = TimelineView(timeHourSystem: data.timeSystem, style: style, frame: timelineFrame)
        view.delegate = self
        return view
    }()
    
    private lazy var topBackgroundView: UIView = {
        let heightView: CGFloat
        if style.headerScrollStyle.isHiddenTitleDate {
            heightView = style.headerScrollStyle.heightHeaderWeek
        } else {
            heightView = style.headerScrollStyle.heightHeaderWeek + style.headerScrollStyle.heightTitleDate
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView))
        view.backgroundColor = style.headerScrollStyle.backgroundColor
        return view
    }()
    
    init(data: WeekData, frame: CGRect, style: Style) {
        self.style = style
        self.data = data
        super.init(frame: frame)
        addSubview(topBackgroundView)
        topBackgroundView.addSubview(scrollHeaderDay)
        addSubview(timelineView)
    }
    
    func setDate(date: Date) {
        data.date = date
        scrollHeaderDay.setDate(date: date)
        reloadData(events: data.events)
    }
    
    func reloadData(events: [Event]) {
        data.events = events
        timelineView.createTimelinePage(dates: visibleDates, events: events, selectedDate: data.date)
    }
    
    private func getVisibleDates(date: Date) {
        guard let scrollDate = getScrollDate(date: date),
            let idx = data.days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day })
            else
        {
            return
        }
        
        let endIdx: Int
        if idx < 6 {
            endIdx = 0
        } else {
            endIdx = idx + 6
        }
        let visibleDates = data.days[idx...endIdx].map({ $0.date })
        
        guard self.visibleDates != visibleDates else { return }
        self.visibleDates = visibleDates
    }
    
    private func getScrollDate(date: Date) -> Date? {
        guard style.headerScrollStyle.startWeekDay == .sunday else {
            return date.startOfWeek
        }
        return date.startSundayOfWeek
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
        delegate?.didSelectCalendarDate(selectDate, type: type)
    }
}

extension WeekViewCalendar: CalendarFrameProtocol {
    func reloadFrame(frame: CGRect) {
        self.frame = frame
        topBackgroundView.frame.size.width = frame.width
        scrollHeaderDay.reloadFrame(frame: frame)
        
        var timelineFrame = timelineView.frame
        timelineFrame.size.width = frame.width
        timelineFrame.size.height = frame.height - scrollHeaderDay.frame.height
        timelineView.reloadFrame(frame: timelineFrame)
        timelineView.createTimelinePage(dates: visibleDates, events: data.events, selectedDate: data.date)
    }
}

extension WeekViewCalendar: TimelineDelegate {
    func didSelectEventInTimeline(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 7)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -7)
    }
    
    func swipeX(transform: CGAffineTransform) {
        
    }
}
