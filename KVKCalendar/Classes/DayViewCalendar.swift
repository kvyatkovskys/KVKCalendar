//
//  DayViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class DayViewCalendar: UIView {
    fileprivate let style: Style
    weak var delegate: CalendarSelectDateDelegate?
    fileprivate var data: DayData
    
    fileprivate lazy var scrollHeaderDay: ScrollDayHeaderView = {
        let heightView: CGFloat
        if style.headerScrollStyle.isHiddenTitleDate {
            heightView = style.headerScrollStyle.heightHeaderWeek
        } else {
            heightView = style.headerScrollStyle.heightHeaderWeek + style.headerScrollStyle.heightTitleDate
        }
        let view = ScrollDayHeaderView(frame: CGRect(x: 0,
                                                     y: 0,
                                                     width: frame.width,
                                                     height: heightView),
                                       days: data.days,
                                       date: data.date,
                                       type: .day,
                                       style: style.headerScrollStyle,
                                       calendar: style.calendar)
        view.delegate = self
        return view
    }()
    
    fileprivate lazy var timelineView: TimelineView = {
        var timelineFrame = frame
        timelineFrame.origin.y = scrollHeaderDay.frame.height
        timelineFrame.size.height -= scrollHeaderDay.frame.height
        if UIDevice.current.userInterfaceIdiom == .pad {
            timelineFrame.size.width -= style.timelineStyle.widthEventViewer
        }
        let view = TimelineView(hours: data.timeSystem.hours, style: style, frame: timelineFrame)
        view.delegate = self
        return view
    }()
    
    fileprivate lazy var topBackgroundView: UIView = {
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
    
    init(data: DayData, frame: CGRect, style: Style) {
        self.style = style
        self.data = data
        super.init(frame: frame)
        addSubview(topBackgroundView)
        topBackgroundView.addSubview(scrollHeaderDay)
        addSubview(timelineView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addEventView(view: UIView) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        var timlineFrame = timelineView.frame
        timlineFrame.origin.x = timlineFrame.width
        timlineFrame.size.width = style.timelineStyle.widthEventViewer
        view.frame = timlineFrame
        view.tag = -1
        addSubview(view)
    }
    
    func setDate(date: Date) {
        data.date = date
        scrollHeaderDay.setDate(date: date)
        reloadData(events: data.events)
    }
    
    func reloadData(events: [Event]) {
        data.events = events
        timelineView.createTimelinePage(dates: [data.date], events: events, selectedDate: data.date)
    }
}

extension DayViewCalendar: ScrollDayHeaderProtocol {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType) {
        guard let selectDate = date else { return }
        data.date = selectDate
        delegate?.didSelectCalendarDate(selectDate, type: type)
    }
}

extension DayViewCalendar: TimelineDelegate {
    func didSelectEventInTimeline(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func nextDate() {
        scrollHeaderDay.selectDate(offset: 1)
    }
    
    func previousDate() {
        scrollHeaderDay.selectDate(offset: -1)
    }
}

extension DayViewCalendar: CalendarFrameDelegate {
    func reloadFrame(frame: CGRect) {
        self.frame = frame
        topBackgroundView.frame.size.width = frame.size.width
        scrollHeaderDay.reloadFrame(frame: frame)
        
        var timelineFrame = timelineView.frame
        timelineFrame.size.height = frame.size.height - scrollHeaderDay.frame.height
        if UIDevice.current.userInterfaceIdiom == .pad {
            timelineFrame.size.width = frame.size.width - style.timelineStyle.widthEventViewer
            if let idx = subviews.index(where: { $0.tag == -1 }) {
                let eventView = subviews[idx]
                var eventFrame = timelineFrame
                eventFrame.origin.x = eventFrame.width
                eventFrame.size.width = style.timelineStyle.widthEventViewer
                eventView.frame = eventFrame
            }
        }
        timelineView.reloadFrame(frame: timelineFrame)
        timelineView.createTimelinePage(dates: [data.date], events: data.events, selectedDate: data.date)
    }
}
