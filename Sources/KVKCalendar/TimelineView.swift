//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class TimelineView: UIView, EventDateProtocol, CalendarTimer {
    
    weak var delegate: TimelineDelegate?
    weak var dataSource: DisplayDataSource?
    
    var deselectEvent: ((Event) -> Void)?
    
    var style: Style {
        didSet {
            timeSystem = style.timeSystem
            availabilityHours = timeSystem.hours
        }
    }
    var eventPreview: UIView?
    var eventResizePreview: ResizeEventView?
    var eventPreviewSize = CGSize(width: 150, height: 150)
    var isResizeEnableMode = false
    
    let timeLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private(set) var tagCurrentHourLine = -10
    private(set) var tagEventPagePreview = -20
    private(set) var tagVerticalLine = -30
    private let tagShadowView = -40
    private let tagBackgroundView = -50
    private(set) var tagAllDayEventView = -70
    private(set) var tagStubEvent = -80
    private(set) var timeLabels = [TimelineLabel]()
    private(set) var availabilityHours: [String]
    private var timeSystem: TimeHourSystem
    private let timerKey = "CurrentHourTimerKey"
    private(set) var events = [Event]()
    private(set) var dates = [Date?]()
    private(set) var selectedDate: Date?
    private(set) var type: CalendarType
    private(set) var eventLayout: TimelineEventLayout

    private(set) lazy var shadowView: ShadowDayView = {
        let view = ShadowDayView()
        view.backgroundColor = style.timeline.shadowColumnColor
        view.alpha = style.timeline.shadowColumnAlpha
        view.tag = tagShadowView
        return view
    }()
    
    private(set) lazy var movingMinuteLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.adjustsFontSizeToFitWidth = true
        label.textColor = style.timeline.movingMinutesColor
        label.textAlignment = .right
        label.font = style.timeline.timeFont
        return label
    }()
    
    private(set) lazy var currentLineView: CurrentLineView = {
        let view = CurrentLineView(style: style,
                                   frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 15))
        view.tag = tagCurrentHourLine
        return view
    }()
    
    private(set) lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.delegate = self
        return scroll
    }()
    
    init(type: CalendarType, style: Style, frame: CGRect) {
        self.type = type
        self.timeSystem = style.timeSystem
        self.availabilityHours = timeSystem.hours
        self.style = style
        self.eventLayout = style.timeline.eventLayout
        super.init(frame: frame)
        
        var scrollFrame = frame
        scrollFrame.origin.y = 0
        scrollView.frame = scrollFrame
        addSubview(scrollView)
        setUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(forceDeselectEvent))
        addGestureRecognizer(tap)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopTimer(timerKey)
    }
    
    private func setOffsetScrollView(allDayEventsCount: Int) {
        var offsetY: CGFloat = 0
        if allDayEventsCount > 0 {
            if 3...4 ~= allDayEventsCount {
                offsetY = style.allDay.height * 2
            } else if allDayEventsCount > 4 {
                offsetY = style.allDay.maxHeight
            } else {
                offsetY = style.allDay.height
            }
        }
        
        switch type {
        case .day:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        case .week where scrollView.contentInset.top < offsetY:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        default:
            break
        }
    }
    
    private func getTimelineLabel(hour: Int) -> TimelineLabel? {
        return scrollView.subviews .filter({ (view) -> Bool in
            guard let time = view as? TimelineLabel else { return false }
            return time.valueHash == hour.hashValue }).first as? TimelineLabel
    }
    
    private func movingCurrentLineHour() {
        guard !isValidTimer(timerKey) else { return }
                
        let action = { [weak self] in
            guard let self = self else { return }
            
            let nextDate = Date().convertTimeZone(TimeZone.current, to: self.style.timezone)
            guard self.currentLineView.valueHash != nextDate.minute.hashValue, let time = self.getTimelineLabel(hour: nextDate.hour) else { return }
            
            var pointY = time.frame.origin.y
            if !self.subviews.filter({ $0.tag == self.tagAllDayEventView }).isEmpty, self.style.allDay.isPinned {
                pointY -= self.style.allDay.height
            }
            
            pointY = self.calculatePointYByMinute(nextDate.minute, time: time)
            
            self.currentLineView.frame.origin.y = pointY - (self.currentLineView.frame.height * 0.5)
            self.currentLineView.valueHash = nextDate.minute.hashValue
            self.currentLineView.date = nextDate
            
            if let timeNext = self.getTimelineLabel(hour: nextDate.hour + 1) {
                timeNext.isHidden = self.currentLineView.frame.intersects(timeNext.frame)
            }
            time.isHidden = time.frame.intersects(self.currentLineView.frame)
        }
        
        startTimer(timerKey, repeats: true, addToRunLoop: true, action: action)
    }
    
    private func showCurrentLineHour() {
        currentLineView.removeFromSuperview()
        
        let date = Date().convertTimeZone(TimeZone.current, to: style.timezone)
        guard style.timeline.showLineHourMode.showForDates(dates), let time = getTimelineLabel(hour: date.hour) else {
            stopTimer(timerKey)
            return
        }
        
        let pointY = calculatePointYByMinute(date.minute, time: time)
        currentLineView.frame.origin.y = pointY - (currentLineView.frame.height * 0.5)
        scrollView.addSubview(currentLineView)
        movingCurrentLineHour()
        
        if let timeNext = getTimelineLabel(hour: date.hour + 1) {
            timeNext.isHidden = currentLineView.frame.intersects(timeNext.frame)
        }
        time.isHidden = currentLineView.frame.intersects(time.frame)
    }
    
    private func calculatePointYByMinute(_ minute: Int, time: TimelineLabel) -> CGFloat {
        let pointY: CGFloat
        if 1...59 ~= minute {
            let minutePercent = 59.0 / CGFloat(minute)
            let newY = (style.timeline.offsetTimeY + time.frame.height) / minutePercent
            let summY = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
            if time.tag == 0 {
                pointY = newY + (time.frame.height / 2)
            } else {
                pointY = summY + newY
            }
        } else {
            pointY = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
        }
        return pointY
    }
    
    private func scrollToCurrentTime(_ startHour: Int) {
        guard style.timeline.scrollLineHourMode.scrollForDates(dates) else { return }
        
        let date = Date().convertTimeZone(TimeZone.current, to: style.timezone)
        guard let time = getTimelineLabel(hour: date.hour)else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
                
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y - 10
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func create(dates: [Date?], events: [Event], selectedDate: Date?) {
        isResizeEnableMode = false
        delegate?.didDisplayEvents(events, dates: dates)
        
        self.dates = dates
        self.events = events
        self.selectedDate = selectedDate
        
        if style.allDay.isPinned {
            subviews.filter({ $0.tag == tagAllDayEventView }).forEach({ $0.removeFromSuperview() })
        }
        subviews.filter({ $0.tag == tagStubEvent || $0.tag == tagVerticalLine }).forEach({ $0.removeFromSuperview() })
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        
        // filter events
        let recurringEvents = events.filter({ $0.recurringType != .none })
        let allEventsForDates = events.filter { (event) -> Bool in
            return dates.contains(where: { compareStartDate($0, with: event) || compareEndDate($0, with: event) || (checkMultipleDate($0, with: event) && type == .day) })
        }
        let filteredEvents = allEventsForDates.filter({ !$0.isAllDay })
        let filteredAllDayEvents = allEventsForDates.filter({ $0.isAllDay })

        // calculate a start hour
        let startHour: Int
        if !style.timeline.startFromFirstEvent {
            startHour = 0
        } else {
            if dates.count > 1 {
                startHour = filteredEvents.sorted(by: { $0.start.hour < $1.start.hour }).first?.start.hour ?? style.timeline.startHour
            } else {
                startHour = filteredEvents.filter({ compareStartDate(selectedDate, with: $0) })
                    .sorted(by: { $0.start.hour < $1.start.hour })
                    .first?.start.hour ?? style.timeline.startHour
            }
        }
        
        // add time label to timeline
        timeLabels = createTimesLabel(start: startHour)
        // add separator line
        let lines = createLines(times: timeLabels)
        
        // calculate all height by time label minus the last offset
        let heightAllTimes = timeLabels.reduce(0, { $0 + ($1.frame.height + style.timeline.offsetTimeY) }) - style.timeline.offsetTimeY
        scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes)
        timeLabels.forEach({ scrollView.addSubview($0) })
        lines.forEach({ scrollView.addSubview($0) })

        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        let widthPage = (frame.width - leftOffset) / CGFloat(dates.count)
        let heightPage = scrollView.contentSize.height
        var allDayEvents = [AllDayView.PrepareEvents]()
        
        // horror
        for (idx, date) in dates.enumerated() {
            let pointX: CGFloat
            if idx == 0 {
                pointX = leftOffset
            } else {
                pointX = CGFloat(idx) * widthPage + leftOffset
            }
            
            let verticalLine = createVerticalLine(pointX: pointX, date: date)
            addSubview(verticalLine)
            bringSubviewToFront(verticalLine)
            
            let eventsByDate = filteredEvents.filter({ compareStartDate(date, with: $0) || compareEndDate(date, with: $0) || checkMultipleDate(date, with: $0) })
            let allDayEventsForDate = filteredAllDayEvents.filter({ compareStartDate(date, with: $0) || compareEndDate(date, with: $0) }).compactMap { (oldEvent) -> Event in
                var updatedEvent = oldEvent
                updatedEvent.start = date ?? oldEvent.start
                updatedEvent.end = date ?? oldEvent.end
                return updatedEvent
            }
            
            let recurringEventByDate: [Event]
            if !recurringEvents.isEmpty, let dt = date {
                recurringEventByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                    guard !eventsByDate.contains(where: { $0.ID == event.ID })
                            && dt.compare(event.start) == .orderedDescending else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: date, calendar: style.calendar) else {
                        return acc
                    }
                    
                    return acc + [recurringEvent]
                    
                })
            } else {
                recurringEventByDate = []
            }
            
            let filteredRecurringEvents = recurringEventByDate.filter({ !$0.isAllDay })
            let filteredAllDayRecurringEvents = recurringEventByDate.filter({ $0.isAllDay })
            let sortedEventsByDate = (eventsByDate + filteredRecurringEvents).sorted(by: { $0.start < $1.start })
            
            // create an all day events
            allDayEvents.append(.init(events: allDayEventsForDate + filteredAllDayRecurringEvents,
                                      date: date,
                                      xOffset: pointX - leftOffset,
                                      width: widthPage))

            do {
                let context = TimelineEventLayoutContext(
                    style: style,
                    pageFrame: .init(x: pointX, y: 0, width: widthPage, height: heightPage),
                    startHour: startHour,
                    timeLabels: timeLabels,
                    calculatePointYByMinute: calculatePointYByMinute(_:time:),
                    getTimelineLabel: getTimelineLabel(hour:)
                )
                let rects = eventLayout.getEventRects(
                    forEvents: sortedEventsByDate,
                    date: date,
                    context: context
                )
                for (event, rect) in zip(sortedEventsByDate, rects) {
                    let view: EventViewGeneral = {
                        if let view = dataSource?.willDisplayEventView(event, frame: rect, date: date) {
                            return view
                        } else {
                            let eventView = EventView(event: event, style: style, frame: rect)
                            if #available(iOS 14.0, *), let item = dataSource?.willDisplayEventOptionMenu(event, type: self.type) {
                                eventView.addOptionMenu(item.menu, customButton: item.customButton)
                            }
                            return eventView
                        }
                    }()

                    view.delegate = self
                    scrollView.addSubview(view)
                }
            }
            
            if !style.timeline.isHiddenStubEvent, let day = date?.day {
                let y = topStabStackOffsetY(allDayEventsIsPinned: style.allDay.isPinned,
                                            eventsCount: (allDayEventsForDate + filteredAllDayRecurringEvents).count,
                                            height: style.allDay.height)
                let topStackFrame = CGRect(x: pointX, y: y, width: widthPage - style.timeline.offsetEvent, height: style.event.heightStubView)
                let bottomStackFrame = CGRect(x: pointX, y: frame.height - bottomStabStackOffsetY, width: widthPage - style.timeline.offsetEvent, height: style.event.heightStubView)
                
                addSubview(createStackView(day: day, type: .top, frame: topStackFrame))
                addSubview(createStackView(day: day, type: .bottom, frame: bottomStackFrame))
            }
        }
        
        if let maxEvents = allDayEvents.max(by: { $0.events.count < $1.events.count })?.events.count, maxEvents > 0 {
            setOffsetScrollView(allDayEventsCount: maxEvents)
            createAllDayEvents(events: allDayEvents, maxEvents: maxEvents)
        }
        scrollToCurrentTime(startHour)
        showCurrentLineHour()
        addStubInvisibleEvents()
    }
}
