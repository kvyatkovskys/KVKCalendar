//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class TimelineView: UIView, EventDateProtocol, CalendarTimer {
    
    struct Parameters {
        var style: Style
        var type: CalendarType
        var scale: CGFloat = 1
        var scrollToCurrentTimeOnlyOnInit: Bool?
    }
    
    weak var delegate: TimelineDelegate?
    weak var dataSource: DisplayDataSource?
    
    var deselectEvent: ((Event) -> Void)?
    var didChangeParameters: ((Parameters) -> Void)?
    
    var paramaters: Parameters {
        didSet {
            timeSystem = paramaters.style.timeSystem
            availabilityHours = timeSystem.hours
            
            if oldValue.scale != paramaters.scale
                || oldValue.scrollToCurrentTimeOnlyOnInit != paramaters.scrollToCurrentTimeOnlyOnInit {
                didChangeParameters?(paramaters)
            }
        }
    }
    var eventPreview: UIView?
    var eventResizePreview: ResizeEventView?
    var eventPreviewSize = CGSize(width: 150, height: 150)
    var isResizableEventEnable = false
    var forceDisableScrollToCurrentTime = false
    var potentiallyCenteredLabel: TimelineLabel?
    
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
    private(set) var recurringEvents = [Event]()
    private(set) var dates = [Date]()
    private(set) var selectedDate: Date
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
        let view = CurrentLineView(parameters: .init(style: style),
                                   frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 15))
        view.tag = tagCurrentHourLine
        return view
    }()
    
    private(set) lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.delegate = self
        return scroll
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.paramaters = parameters
        self.timeSystem = parameters.style.timeSystem
        self.availabilityHours = timeSystem.hours
        self.eventLayout = parameters.style.timeline.eventLayout
        self.selectedDate = Date()
        super.init(frame: frame)
        
        addSubview(scrollView)
        setupConstraints()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(forceDeselectEvent))
        addGestureRecognizer(tap)
        
        if style.timeline.scale != nil {
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchZooming))
            addGestureRecognizer(pinch)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopTimer(timerKey)
    }
    
    private func setOffsetScrollView(offsetY: CGFloat) {
        switch paramaters.type {
        case .day:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        case .week where scrollView.contentInset.top < offsetY:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        default:
            break
        }
    }
    
    private func movingCurrentLineHour() {
        guard !isValidTimer(timerKey) else { return }
        
        let action = { [weak self] in
            guard let self = self else { return }
            
            let nextDate = Date().convertTimeZone(TimeZone.current, to: self.style.timezone)
            guard self.currentLineView.valueHash != nextDate.minute.hashValue,
                  let time = self.getTimelineLabel(hour: nextDate.hour) else { return }
            
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
        let date = Date().convertTimeZone(TimeZone.current, to: style.timezone)
        guard style.timeline.showLineHourMode.showForDates(dates), let time = getTimelineLabel(hour: date.hour) else {
            stopTimer(timerKey)
            return
        }

        currentLineView.reloadFrame(frame)
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
            let newY = (calculatedTimeY + time.frame.height) / minutePercent
            let summY = (CGFloat(time.tag) * (calculatedTimeY + time.frame.height)) + (time.frame.height / 2)
            if time.tag == 0 {
                pointY = newY + (time.frame.height / 2)
            } else {
                pointY = summY + newY
            }
        } else {
            pointY = (CGFloat(time.tag) * (calculatedTimeY + time.frame.height)) + (time.frame.height / 2)
        }
        return pointY
    }
    
    private func scrollToCurrentTime(_ startHour: Int) {
        guard style.timeline.scrollLineHourMode.scrollForDates(dates) else { return }
        
        let date = Date()
        guard let time = getTimelineLabel(hour: date.hour)else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
        
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y - 10
        
        if let value = paramaters.scrollToCurrentTimeOnlyOnInit {
            if value {
                paramaters.scrollToCurrentTimeOnlyOnInit = false
                // some delay to save a visible scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.scrollView.scrollRectToVisible(frame, animated: true)
                }
            }
        } else {
            scrollView.scrollRectToVisible(frame, animated: true)
        }
    }
    
    private func scrollToHour(_ hour: Int) {
        guard let time = getTimelineLabel(hour: hour.hashValue) else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
        
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y - 10
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func create(dates: [Date], events: [Event], recurringEvents: [Event], selectedDate: Date?) {
        isResizableEventEnable = false
        delegate?.didDisplayEvents(events, dates: dates)
        
        self.dates = dates
        self.events = events
        self.recurringEvents = recurringEvents
        self.selectedDate = selectedDate ?? Date()
        
        if style.allDay.isPinned {
            subviews.filter { $0.tag == tagAllDayEventView }.forEach { $0.removeFromSuperview() }
        }
        subviews.filter { $0.tag == tagStubEvent || $0.tag == tagVerticalLine }.forEach { $0.removeFromSuperview() }
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.filter { $0.name == "\(tagVerticalLine)" }.forEach { $0.removeFromSuperlayer() }
        
        // filtering events
        let eventValues = events.splitEvents
        let filteredEvents = eventValues[.usual] ?? []
        let filteredAllDayEvents = eventValues[.allDay] ?? []
        
        // calculate a start hour
        let startHour: Int
        if !style.timeline.startFromFirstEvent {
            startHour = style.timeline.startHour
        } else {
            if dates.count > 1 {
                startHour = filteredEvents.sorted(by: { $0.start.hour < $1.start.hour })
                    .first?.start.hour ?? style.timeline.startHour
            } else {
                startHour = filteredEvents.filter { compareStartDate(selectedDate, with: $0) }
                .sorted(by: { $0.start.hour < $1.start.hour })
                .first?.start.hour ?? style.timeline.startHour
            }
        }
        
        // add time label to timeline
        timeLabels = createTimesLabel(start: startHour)
        // add separator line
        let lines = createHorizontalLines(times: timeLabels)
        
        // calculate all height by time label minus the last offset
        let heightAllTimes = timeLabels.reduce(0, { $0 + ($1.frame.height + calculatedTimeY) }) - calculatedTimeY
        scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes)
        timeLabels.forEach { scrollView.addSubview($0) }
        lines.forEach { scrollView.addSubview($0) }
        
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        let widthPage = (frame.width - leftOffset) / CGFloat(dates.count)
        let heightPage = scrollView.contentSize.height
        var allDayEvents = [AllDayView.PrepareEvents]()
        var topStackViews = [StubStackView]()
        
        // horror 👹
        dates.enumerated().forEach { (idx, date) in
            let pointX: CGFloat
            if idx == 0 {
                pointX = leftOffset
            } else {
                pointX = CGFloat(idx) * widthPage + leftOffset
            }
            
            let verticalLine = createVerticalLine(pointX: pointX, date: date)
            layer.addSublayer(verticalLine)
            
            let eventsByDate = filteredEvents.filter {
                compareStartDate(date, with: $0)
                || compareEndDate(date, with: $0)
                || checkMultipleDate(date, with: $0)
            }
            let allDayEventsForDate = filteredAllDayEvents.filter {
                compareStartDate(date, with: $0)
                || compareEndDate(date, with: $0)
                || checkMultipleDate(date, with: $0)
            }.compactMap { (oldEvent) -> Event in
                var updatedEvent = oldEvent
                updatedEvent.start = date
                updatedEvent.end = date
                return updatedEvent
            }
            
            let recurringEventsByDate: [Event]
            if !recurringEvents.isEmpty {
                recurringEventsByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                    // TODO: need fix
                    // there's still a problem with the second recurring event when an event is created for severel dates
                    guard !eventsByDate.contains(where: { $0.ID == event.ID })
                            && (date.compare(event.start) == .orderedDescending
                                || style.event.showRecurringEventInPast) else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: date, calendar: style.calendar) else {
                        return acc
                    }
                    
                    var result = [recurringEvent]
                    let previousDate = style.calendar.date(byAdding: .day, value: -1, to: date)
                    if recurringEvent.start.day != recurringEvent.end.day,
                       let recurringPrevEvent = event.updateDate(newDate: previousDate ?? date,
                                                                 calendar: style.calendar) {
                        result.append(recurringPrevEvent)
                    }
                    return acc + result
                })
            } else {
                recurringEventsByDate = []
            }
            
            let recurringValues = recurringEventsByDate.splitEvents
            let filteredRecurringEvents = recurringValues[.usual] ?? []
            let filteredAllDayRecurringEvents = recurringValues[.allDay] ?? []
            let sortedEventsByDate = (eventsByDate + filteredRecurringEvents).sorted(by: { $0.start < $1.start })
            let groupAllEvents = allDayEventsForDate + filteredAllDayRecurringEvents
            // creating an all day events
            allDayEvents.append(.init(events: groupAllEvents,
                                      date: date,
                                      xOffset: pointX - leftOffset,
                                      width: widthPage))
            
            do {
                let context = TimelineEventLayoutContext(style: style,
                                                         pageFrame: .init(x: pointX, y: 0,
                                                                          width: widthPage, height: heightPage),
                                                         startHour: startHour,
                                                         timeLabels: timeLabels,
                                                         calculatedTimeY: calculatedTimeY,
                                                         calculatePointYByMinute: calculatePointYByMinute(_:time:),
                                                         getTimelineLabel: getTimelineLabel(hour:))
                let rects = eventLayout.getEventRects(forEvents: sortedEventsByDate,
                                                      date: date,
                                                      context: context)
                zip(sortedEventsByDate, rects).forEach { (event, rect) in
                    let view: EventViewGeneral = {
                        if let view = dataSource?.willDisplayEventView(event, frame: rect, date: date) {
                            return view
                        } else {
                            let eventView = EventView(event: event, style: style, frame: rect)
                            if #available(iOS 14.0, *),
                               let item = dataSource?.willDisplayEventOptionMenu(event, type: paramaters.type)
                            {
                                eventView.addOptionMenu(item.menu, customButton: item.customButton)
                            }
                            return eventView
                        }
                    }()
                    
                    view.delegate = self
                    scrollView.addSubview(view)
                }
            }
            
            if !style.timeline.isHiddenStubEvent {
                let maxAllDayEventsFordDate = groupAllEvents.count
                var allDayHeight = style.allDay.height
                if 3...4 ~= maxAllDayEventsFordDate {
                    allDayHeight *= 2
                } else if maxAllDayEventsFordDate > 4 {
                    allDayHeight = style.allDay.maxHeight
                } else {
                    allDayHeight += 5
                }
                let yPoint = topStabStackOffsetY(allDayEventsIsPinned: style.allDay.isPinned,
                                                 height: allDayHeight)
                let topStackFrame = CGRect(x: pointX, y: yPoint,
                                           width: widthPage - style.timeline.offsetEvent,
                                           height: style.event.heightStubView)
                let bottomStackFrame = CGRect(x: pointX, y: frame.height - bottomStabStackOffsetY,
                                              width: widthPage - style.timeline.offsetEvent,
                                              height: style.event.heightStubView)
                
                let topStackView = createStackView(day: date.day, type: .top, frame: topStackFrame)
                topStackViews.append(topStackView)
                addSubview(topStackView)
                addSubview(createStackView(day: date.day, type: .bottom, frame: bottomStackFrame))
            }
        }
        
        if let maxAllDayEvents = allDayEvents.max(by: { $0.events.count < $1.events.count })?.events.count,
           let allDayView = createAllDayEvents(events: allDayEvents, maxEvents: maxAllDayEvents) {
            let offsetY = allDayView.frame.origin.y + allDayView.frame.height
            topStackViews.forEach {
                $0.frame.origin.y = offsetY + 5
            }
            
            setOffsetScrollView(offsetY: offsetY)
        }
        
        if !forceDisableScrollToCurrentTime {
            if let preferredHour = style.timeline.scrollToHour, !style.timeline.startFromFirstEvent {
                scrollToHour(preferredHour)
            } else {
                scrollToCurrentTime(startHour)
            }
        }
        
        showCurrentLineHour()
        addStubForInvisibleEvents()
    }
}

#endif
