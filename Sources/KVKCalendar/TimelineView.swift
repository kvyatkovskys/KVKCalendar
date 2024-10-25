//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
struct TimelineUIKitView: View {
    
    let params: TimelinePageWrapper.Parameters
    @Binding var date: Date
    @Binding var willDate: Date
    @Binding var event: KVKCalendar.Event?
    
    var body: some View {
        GeometryReader { (geometry) in
            TimelinePageWrapper(params: params,
                                frame: geometry.frame(in: .local),
                                date: $date,
                                willDate: $willDate,
                                event: $event)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    var style = Style()
    style.timeline.offsetTimeY = 50
    let events: [Event] = [
        .stub(id: "1", startFrom: -50, duration: 50),
        .stub(id: "2", startFrom: 60, duration: 30),
        .stub(id: "3", startFrom: -30, duration: 55),
        .stub(id: "4", startFrom: -80, duration: 30),
        .stub(id: "5", startFrom: -80, duration: 30)
    ]
    @State var event: Event?
    @State var date = Date.now
    return TimelineUIKitView(params: TimelinePageWrapper.Parameters(style: style, dates: Array(repeating: Date(), count: 7), events: events, recurringEvents: []), date: $date, willDate: .constant(.now), event: $event)
}

@available(iOS 17.0, *)
struct TimelinePageWrapper: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = TimelinePageVC
    
    struct Parameters {
        let style: Style
        let dates: [Date?]
        let events: [Event]
        let recurringEvents: [Event]
    }
    
    var params: TimelinePageWrapper.Parameters
    var frame: CGRect
    @Binding var date: Date
    @Binding var willDate: Date
    @Binding var event: KVKCalendar.Event?
    
    func makeUIViewController(context: Context) -> TimelinePageVC {
        setupTimelinePageView()
    }
    
    func updateUIViewController(_ uiViewController: TimelinePageVC, context: Context) {
        uiViewController.didSwitchTimelineView = { [weak uiViewController] (_, type) in
            let newView = createTimelineView()
            uiViewController?.addNewTimeline(newView, for: type)
            date = switchDateBy(type)
        }
        uiViewController.willDisplayTimelineView = { (view, type) in
            view.reloadFrame(frame)
            view.reloadTimeline(params: params,
                                date: date,
                                event: $event)
            willDate = switchDateBy(type)
        }
        uiViewController.reloadPages(with: params,
                                     date: date,
                                     event: $event)
    }
    
    private func switchDateBy(_ type: TimelinePageVC.SwitchPageType) -> Date {
        switch type {
        case .previous:
            params.style.calendar.date(byAdding: .day, value: -params.dates.count, to: date) ?? date
        case .next:
            params.style.calendar.date(byAdding: .day, value: params.dates.count, to: date) ?? date
        }
    }
    
    private func setupTimelinePageView() -> TimelinePageVC {
        let timelineViews = Array(0..<params.style.timeline.maxLimitCachedPages).reduce([]) { (acc, _) -> [TimelineView] in
            acc + [createTimelineView()]
        }
        let page = TimelinePageVC(maxLimit: params.style.timeline.maxLimitCachedPages,
                                  pages: timelineViews)
        return page
    }
    
    private func createTimelineView() -> TimelineView {
        let view = TimelineView(parameters: TimelineView.Parameters(style: params.style, type: .week), frame: frame)
        view.setup(dates: params.dates,
                   events: params.events,
                   recurringEvents: params.recurringEvents,
                   selectedDate: date,
                   selectedEvent: $event)
        return view
    }
}

public final class TimelineView: UIView, EventDateProtocol, CalendarTimer {
    
    struct Parameters {
        var style: Style
        var type: CalendarType
        var scale: CGFloat = 1
        var scrollToCurrentTimeOnlyOnInit: Bool? = false
    }
    
    weak var delegate: TimelineDelegate?
    weak var dataSource: DisplayDataSource?
    
    var deselectEvent: ((Event) -> Void)?
    var didChangeParameters: ((Parameters) -> Void)?
    
    var paramaters: Parameters {
        didSet {
            timeSystem = paramaters.style.timeSystem
            
            if oldValue.scale != paramaters.scale
                || oldValue.scrollToCurrentTimeOnlyOnInit != paramaters.scrollToCurrentTimeOnlyOnInit {
                didChangeParameters?(paramaters)
            }
        }
    }
    var eventPreview: UIView?
    var eventResizePreview: ResizeEventView?
    lazy var eventPreviewSize: CGSize = {
        getEventPreviewSize()
    }()

    var isResizableEventEnable = false
    var forceDisableScrollToCurrentTime = false
    var potentiallyCenteredLabel: TimelineLabel?
    
    let timeLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var calculatedCurrentLineViewFrame: CGRect {
        frame
    }
    
    private(set) var tagCurrentHourLine = -10
    private(set) var tagEventPagePreview = -20
    private(set) var tagVerticalLine = -30
    private let tagShadowView = -40
    private let tagBackgroundView = -50
    private(set) var tagAllDayEventView = -70
    private(set) var tagStubEvent = -80
    public private(set) var timeLabels = [TimelineLabel]()
    var timeLabelsDict = [Int: TimelineLabel]()
    private(set) var timeSystem: TimeHourSystem
    private let timerKey = "CurrentHourTimerKey"
    private(set) var events = [Event]()
    private(set) var recurringEvents = [Event]()
    private(set) var dates = [Date]()
    private(set) var newDates = [Date?]()
    private(set) var selectedDate: Date
    private(set) var eventLayout: TimelineEventLayout
    
    private(set) lazy var shadowView: ShadowDayView = {
        let view = ShadowDayView()
        view.backgroundColor = style.timeline.shadowColumnColor
        view.alpha = style.timeline.shadowColumnAlpha
        view.tag = tagShadowView
        return view
    }()
    
    public private(set) lazy var movingMinuteLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.adjustsFontSizeToFitWidth = true
        label.textColor = style.timeline.movingMinutesColor
        label.textAlignment = .left
        label.font = style.timeline.timeFont
        label.isHidden = !isDisplayedMovingTime
        return label
    }()
    
    private(set) lazy var currentLineView: CurrentLineView = {
        let view = CurrentLineView(parameters: .init(style: style),
                                   frame: CGRect(x: 0, y: 0, width: scrollView.frame.width, height: 15))
        view.tag = tagCurrentHourLine
        return view
    }()
    
    private var centerYCurrentLine = NSLayoutConstraint()
    private(set) lazy var currentLine: CurrentLineView = {
        let view = CurrentLineView(parameters: .init(style: style))
        view.tag = tagCurrentHourLine
        return view
    }()
    
    public private(set) lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.delegate = self
        return scroll
    }()
    
    private(set) lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDefaultTapGesture(gesture:)))

    private(set) lazy var longTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addNewEvent))
    
    init(parameters: Parameters,
         frame: CGRect = .zero,
         newFlow: Bool = false) {
        self.paramaters = parameters
        self.timeSystem = parameters.style.timeSystem
        self.eventLayout = parameters.style.timeline.eventLayout
        self.selectedDate = Date()
        super.init(frame: frame)
        
        timeLabelFormatter.locale = style.locale

        addSubview(scrollView)
        setupConstraints()
        
        addGestureRecognizer(tapGestureRecognizer)
        
        // long tap to create a new event preview
        addGestureRecognizer(longTapGestureRecognizer)
        
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
    
    private func setOffsetScrollView(offsetY: CGFloat, force: Bool = false) {
        switch paramaters.type {
        case .day:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        case .week where scrollView.contentInset.top < offsetY || force:
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
        default:
            break
        }
    }
    
    private func setupCurrentLineConstraints(pointY: CGFloat, time: TimelineLabel) {
        currentLine.removeFromSuperview()
        scrollView.addSubview(currentLine)
        currentLine.translatesAutoresizingMaskIntoConstraints = false
        let leading = currentLine.leadingAnchor.constraint(equalTo: leadingAnchor)
        let centerY = currentLine.centerYAnchor.constraint(equalTo: time.centerYAnchor, constant: pointY)
        let height = currentLine.heightAnchor.constraint(equalToConstant: 14)
        let trailing = currentLine.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([leading, centerY, height, trailing])
        currentLine.setNeedsLayout()
    }
    
    private func movingCurrentLine() {
        guard !isValidTimer(timerKey) && isDisplayedCurrentTime else { return }
        
        func action() {
            let nextDate = Date().kvkConvertTimeZone(TimeZone.current, to: style.timezone)
            guard currentLine.valueHash != nextDate.kvkMinute.hashValue,
                  let time = getTimeLabel(hour: nextDate.kvkHour) else { return }
            
            let pointY = calculateYByMinute(nextDate.kvkMinute, time: time)
            setupCurrentLineConstraints(pointY: pointY, time: time)
            currentLine.valueHash = nextDate.kvkMinute.hashValue
            currentLine.date = nextDate
            
            if isDisplayedTimes {
                time.isHidden = time.yTime == currentLineView.frame.origin.y
            }
        }
        
        startTimer(timerKey, repeats: true, addToRunLoop: true, action: action)
    }
    
    private func movingCurrentLineHour() {
        guard !isValidTimer(timerKey) && isDisplayedCurrentTime else { return }
        
        let action = { [weak self] in
            guard let self = self else { return }
            
            let nextDate = Date().kvkConvertTimeZone(TimeZone.current, to: self.style.timezone)
            guard self.currentLineView.valueHash != nextDate.kvkMinute.hashValue,
                  let time = self.getTimelineLabel(hour: nextDate.kvkHour) else { return }
            
            var pointY = time.frame.origin.y
            if !self.subviews.filter({ $0.tag == self.tagAllDayEventView }).isEmpty, self.style.allDay.isPinned {
                pointY -= self.style.allDay.height
            }
            
            pointY = self.calculatePointYByMinute(nextDate.kvkMinute, time: time)
            
            self.currentLineView.frame.origin.y = pointY - (self.currentLineView.frame.height * 0.5)
            self.currentLineView.valueHash = nextDate.kvkMinute.hashValue
            self.currentLineView.date = nextDate
            
            if self.isDisplayedTimes && style.timeline.lineHourStyle == .withTime {
                if let timeNext = self.getTimelineLabel(hour: nextDate.kvkHour + 1) {
                    timeNext.isHidden = self.currentLineView.frame.intersects(timeNext.frame)
                }
                time.isHidden = time.frame.intersects(self.currentLineView.frame)
            }
        }
        
        startTimer(timerKey, repeats: true, addToRunLoop: true, action: action)
    }
    
    private func showCurrentLine() {
        stopTimer(timerKey)
        currentLine.valueHash = nil
        currentLine.isHidden = !isDisplayedCurrentTime
        guard style.timeline.showLineHourMode.showForDates(dates) else { return }
        
        currentLine.updateStyle(style, force: true)
        movingCurrentLine()
    }
    
    private func showCurrentLineHour() {
        currentLineView.isHidden = !isDisplayedCurrentTime
        let date = Date().kvkConvertTimeZone(TimeZone.current, to: style.timezone)
        guard style.timeline.showLineHourMode.showForDates(dates),
              let time = getTimelineLabel(hour: date.kvkHour) else {
            stopTimer(timerKey)
            return
        }

        currentLineView.reloadFrame(calculatedCurrentLineViewFrame)
        currentLineView.updateStyle(style, force: true)
        currentLineView.setOffsetForTime(timeLabels.first?.frame.origin.x ?? 0)
        let pointY = calculatePointYByMinute(date.kvkMinute, time: time)
        currentLineView.frame.origin.y = pointY - (currentLineView.frame.height * 0.5)
        scrollView.addSubview(currentLineView)
        movingCurrentLineHour()
        
        if isDisplayedTimes && style.timeline.lineHourStyle == .withTime {
            if let timeNext = getTimelineLabel(hour: date.kvkHour + 1) {
                timeNext.isHidden = currentLineView.frame.intersects(timeNext.frame)
            }
            time.isHidden = currentLineView.frame.intersects(time.frame)
        }
    }
    
    private func calculatePointYByMinute(_ minute: Int, time: TimelineLabel) -> CGFloat {
        let pointY: CGFloat
        if 1...59 ~= minute {
            let minutePercent = 59.0 / CGFloat(minute)
            let newY = (calculatedTimeY + time.frame.height) / minutePercent
            let summY = (CGFloat(time.tag) * (calculatedTimeY + time.frame.height)) + (time.frame.height / 2)
            if time.hashTime == 0 {
                pointY = newY + (time.frame.height / 2)
            } else {
                pointY = summY + newY
            }
        } else {
            pointY = (CGFloat(time.tag) * (calculatedTimeY + time.frame.height)) + (time.frame.height / 2)
        }
        return pointY
    }
    
    private func calculateYInTimeline(_ minute: Int, time: TimelineLabel) -> CGFloat {
        switch minute {
        case let x where 1...59 ~= x:
            let minutePercent = 59.0 / CGFloat(minute)
            let newY = (calculatedTimeY + style.timeline.heightTime) / minutePercent
            return time.yTime + newY
        default:
            return time.yTime
        }
    }
    
    private func calculateYByMinute(_ minute: Int, time: TimelineLabel) -> CGFloat {
        if 1...59 ~= minute {
            let minutePercent = 59.0 / CGFloat(minute)
            return (calculatedTimeY + style.timeline.heightTime) / minutePercent
        } else {
            return 0
        }
    }
    
    private func scrollToCurrentTime(_ startHour: Int) {
        guard style.timeline.scrollLineHourMode.scrollForDates(dates) && isDisplayedCurrentTime else { return }

        let date = Date()
        guard let time = getTimeLabel(hour: date.kvkHour)else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }

        if let value = paramaters.scrollToCurrentTimeOnlyOnInit {
            if value {
                paramaters.scrollToCurrentTimeOnlyOnInit = false
                // some delay to save a visible scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.scrollView.setContentOffset(time.frame.origin, animated: true)
                }
            }
        } else {
            scrollView.setContentOffset(time.frame.origin, animated: true)
        }
    }
    
    private func scrollToHour(_ hour: Int) {
        guard let time = getTimeLabel(hour: hour) else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
        scrollView.setContentOffset(time.frame.origin, animated: true)
    }
    
    private typealias EventOrder = (Event, Event) -> Bool
    private func sortedEvent(_ lhs: Event,
                             rhs: Event) -> Bool {
        let predicates: [EventOrder] = [
            { $0.style?.defaultWidth != nil && !($1.style?.defaultWidth != nil) },
            { $0.start.kvkHour < $1.start.kvkHour }
        ]
        
        for predicate in predicates {
            if !predicate(lhs, rhs) && !predicate(rhs, lhs) {
                continue
            }
            return predicate(lhs, rhs)
        }
        return false
    }
    
    @available(iOS 17.0, *)
    func setup(dates: [Date?],
               events: [Event],
               recurringEvents: [Event],
               selectedDate: Date,
               selectedEvent: Binding<Event?>) {
        isResizableEventEnable = false
        
        // save parameters
        self.newDates = dates
        self.events = events
        self.recurringEvents = recurringEvents
        self.selectedDate = selectedDate
        
        // calculate a start hour
        let startHour: Int
        if !style.timeline.startFromFirstEvent {
            startHour = style.timeline.startHour
        } else {
            if dates.count > 1 {
                startHour = events
                    .sorted(by: { $0.start.kvkHour < $1.start.kvkHour })
                    .first?.start.kvkHour ?? style.timeline.startHour
            } else {
                startHour = events
                    .filter { compareStartDate(selectedDate, with: $0) }
                    .sorted(by: { $0.start.kvkHour < $1.start.kvkHour })
                    .first?.start.kvkHour ?? style.timeline.startHour
            }
        }
        
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        // add time label to timeline
        let labels = createAndAddTimesLabel(start: startHour, end: style.timeline.endHour)
        // add horizontal separator lines
        let lines = createAndAddHorizontalLines(times: labels.times)
        // show current line if needed
        showCurrentLine()
        
        dates.enumerated().forEach { (item) in
            let date = item.element
            let index = item.offset
            // add vertical separator line
            let item = createAndAddVerticalLine(maxDates: dates.count, date: date, index: index, topLine: lines.first, bottomLine: lines.last)
            
            let eventsByDate = events
                .filter {
                    compareStartDate(date, with: $0)
                    || compareEndDate(date, with: $0)
                    || checkMultipleDate(date, with: $0)
                }
                .sorted(by: sortedEvent(_:rhs:))
            let recurringEventsByDate = prepareRecurringEvents(recurringEvents, eventsByDate: events, date: date)
            let sortedEventsByDate = (eventsByDate + recurringEventsByDate).sorted(by: { $0.start < $1.start })
            do {
                let pageFrame = CGRect(origin: frame.origin, size: CGSize(width: item.1, height: frame.height))
                let context = TimelineEventLayoutContext(style: style, type: paramaters.type, pageFrame: pageFrame, startHour: startHour, timeLabels: labels.times, calculatedTimeY: calculatedTimeY, calculatePointYByMinute: calculateYInTimeline(_:time:), getTimelineLabel: getTimeLabel(hour:))
                let eventsAndRects: [TimelineColumnView.Container] = sortedEventsByDate.reduce([]) { (acc, event) in
                    let rectEvent = context.getEventRectNew(start: event.start, end: event.end, date: date, style: event.style)
                    return acc + [TimelineColumnView.Container(event: event, rect: rectEvent)]
                }
                let crossEvents = context.calculateCrossEvents(forEvents: sortedEventsByDate)
                createAndAddColumn(crossEvents: crossEvents,
                                   eventsAndRects: eventsAndRects,
                                   selectedEvent: selectedEvent,
                                   maxIndex: dates.count - 1,
                                   index: index,
                                   width: item.1,
                                   vLine: item.0)
            }
        }
        
        // scroll to specific position if needed
        if !forceDisableScrollToCurrentTime {
            if let preferredHour = style.timeline.scrollToHour, !style.timeline.startFromFirstEvent {
                scrollToHour(preferredHour)
            } else {
                scrollToCurrentTime(startHour)
            }
        }
    }
    
    func create(dates: [Date], events: [Event], recurringEvents: [Event], selectedDate: Date) {
        isResizableEventEnable = false
        delegate?.didDisplayEvents(events, dates: dates)
        
        self.dates = dates
        self.events = events
        self.recurringEvents = recurringEvents
        self.selectedDate = selectedDate
        
        if style.allDay.isPinned {
            subviews.filter { $0.tag == tagAllDayEventView }.forEach { $0.removeFromSuperview() }
        }
        subviews.filter { $0.tag == tagStubEvent }.forEach { $0.removeFromSuperview() }
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
                startHour = filteredEvents
                    .sorted(by: { $0.start.kvkHour < $1.start.kvkHour })
                    .first?.start.kvkHour ?? style.timeline.startHour
            } else {
                startHour = filteredEvents
                    .filter { compareStartDate(selectedDate, with: $0) }
                    .sorted(by: { $0.start.kvkHour < $1.start.kvkHour })
                    .first?.start.kvkHour ?? style.timeline.startHour
            }
        }
        
        // add time label to timeline
        let labels = createTimesLabel(start: startHour, end: style.timeline.endHour)
        timeLabels = labels.times
        // add separator line
        let horizontalLines = createHorizontalLines(times: timeLabels)
        // calculate all height by time label minus the last offset
        timeLabels.forEach { scrollView.addSubview($0) }
        labels.items.forEach { scrollView.addSubview($0) }
        horizontalLines.forEach { scrollView.addSubview($0) }
        
        let leftOffset = leftOffsetWithAdditionalTime
        let widthPage = (frame.width - leftOffset) / CGFloat(dates.count)
        let heightPage = scrollView.contentSize.height
        var allDayEvents = [AllDayView.PrepareEvents]()
        var topStackViews = [StubStackView]()
        var allHeightEvents = [CGFloat]()
        
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
            
            let eventsByDate = filteredEvents
                .filter {
                    compareStartDate(date, with: $0)
                    || compareEndDate(date, with: $0)
                    || checkMultipleDate(date, with: $0)
                }
                .sorted(by: sortedEvent(_:rhs:))
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
                    guard !eventsByDate.contains(where: { $0.id == event.id })
                            && (date.compare(event.start) == .orderedDescending
                                || style.event.showRecurringEventInPast) else { return acc }
                    
                    guard let recurringEvent = event.updateDate(newDate: date, calendar: style.calendar) else {
                        return acc
                    }
                    
                    var result = [recurringEvent]
                    let previousDate = style.calendar.date(byAdding: .day, value: -1, to: date)
                    if recurringEvent.start.kvkDay != recurringEvent.end.kvkDay,
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
                let context = TimelineEventLayoutContext(style: style, type: paramaters.type, pageFrame: .init(x: pointX, y: 0, width: widthPage, height: heightPage), startHour: startHour, timeLabels: timeLabels, calculatedTimeY: calculatedTimeY, calculatePointYByMinute: calculatePointYByMinute(_:time:), getTimelineLabel: getTimelineLabel(hour:))
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
                    
                    if !isDisplayedTimes {
                        allHeightEvents.append(view.bounds.height + style.timeline.offsetEvent)
                    }
                    view.delegate = self
                    scrollView.addSubview(view)
                }
            }
            
            if !style.timeline.isHiddenStubEvent && !groupAllEvents.isEmpty {
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
                
                let topStackView = createStackView(day: date.kvkDay, type: .top, frame: topStackFrame)
                topStackViews.append(topStackView)
                addSubview(topStackView)
                addSubview(createStackView(day: date.kvkDay, type: .bottom, frame: bottomStackFrame))
            }
        }
        
        if let maxAllDayEvents = allDayEvents.max(by: { $0.events.count < $1.events.count })?.events.count,
           let allDayView = createAllDayEvents(events: allDayEvents, maxEvents: maxAllDayEvents) {
            let offsetY: CGFloat
            
            if style.allDay.isPinned {
                offsetY = allDayView.frame.origin.y + allDayView.frame.height
                addSubview(allDayView)
                topStackViews.forEach {
                    $0.frame.origin.y = offsetY + 5
                }
            } else {
                offsetY = allDayView.frame.height
                scrollView.addSubview(allDayView)
            }
            
            setOffsetScrollView(offsetY: offsetY)
        } else {
            setOffsetScrollView(offsetY: 0, force: true)
        }
        
        if !isDisplayedTimes {
            var allHeight = allHeightEvents.reduce(0, { $0 + $1 })
            if frame.height > allHeight {
                allHeight = frame.height
            }
            scrollView.contentSize = CGSize(width: frame.width, height: allHeight)
        } else {
            let heightAllTimes = timeLabels.reduce(0, { $0 + ($1.frame.height + calculatedTimeY) }) - calculatedTimeY
            scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes)
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
    
    private func prepareRecurringEvents(_ events: [Event],
                                        eventsByDate: [Event],
                                        date: Date?) -> [Event] {
        let recurringEventsByDate: [Event]
        if !events.isEmpty, let date {
            recurringEventsByDate = recurringEvents.reduce([], { (acc, event) -> [Event] in
                // TODO: need fix
                // there's still a problem with the second recurring event when an event is created for severel dates
                guard !eventsByDate.contains(where: { $0.id == event.id })
                        && (date.compare(event.start) == .orderedDescending
                            || style.event.showRecurringEventInPast) else { return acc }
                
                guard let recurringEvent = event.updateDate(newDate: date, calendar: style.calendar) else {
                    return acc
                }
                
                var result = [recurringEvent]
                let previousDate = style.calendar.date(byAdding: .day, value: -1, to: date)
                if recurringEvent.start.kvkDay != recurringEvent.end.kvkDay,
                   let recurringPrevEvent = event.updateDate(newDate: previousDate ?? date, calendar: style.calendar) {
                    result.append(recurringPrevEvent)
                }
                return acc + result
            })
        } else {
            recurringEventsByDate = []
        }
        return recurringEventsByDate
    }
}

#endif
