//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class TimelineView: UIView, CompareEventDateProtocol {
    weak var delegate: TimelineDelegate?
    
    private let tagCurrentHourLine = -10
    private let tagEventPagePreview = -20
    private let tagVerticalLine = -30
    private let tagShadowView = -40
    private var style: Style
    private let hours: [String]
    private let timeHourSystem: TimeHourSystem
    private var allEvents = [Event]()
    private var timer: Timer?
    private var eventPreview: EventPageView?
    private var dates = [Date?]()
    private var selectedDate: Date?
    private var isEnabledAutoScroll = true
    private let eventPreviewXOffset: CGFloat = 50
    private let eventPreviewYOffset: CGFloat = 60
    private let eventPreviewSize = CGSize(width: 100, height: 100)
    private let type: CalendarType
    
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = style.timeline.shadowColumnColor
        view.alpha = style.timeline.shadowColumnAlpha
        view.tag = tagShadowView
        return view
    }()
    
    private lazy var currentTimeLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.tag = tagCurrentHourLine
        label.textColor = style.timeline.currentLineHourColor
        label.textAlignment = .center
        label.font = style.timeline.currentLineHourFont
        label.adjustsFontSizeToFitWidth = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = timeHourSystem == .twentyFourHour ? "HH:mm" : "h:mm a"
        label.text = formatter.string(from: Date())
        label.valueHash = Date().minute.hashValue
        return label
    }()
    
    private lazy var movingMinutesLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.adjustsFontSizeToFitWidth = true
        label.textColor = style.timeline.movingMinutesColor
        label.textAlignment = .right
        label.font = style.timeline.timeFont
        return label
    }()
    
    private lazy var currentLineView: UIView = {
        let view = UIView()
        view.tag = tagCurrentHourLine
        view.backgroundColor = style.timeline.currentLineHourColor
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = style.timeline.backgroundColor
        return scroll
    }()
    
    init(type: CalendarType, timeHourSystem: TimeHourSystem, style: Style, frame: CGRect) {
        self.type = type
        self.timeHourSystem = timeHourSystem
        self.hours = timeHourSystem.hours
        self.style = style
        super.init(frame: frame)
        
        var scrollFrame = frame
        scrollFrame.origin.y = 0
        scrollView.frame = scrollFrame
        addSubview(scrollView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeEvent))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addEvent))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopTimer()
    }
    
    @objc private func addEvent(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: scrollView)
        let time = calculateChangeTime(pointY: point.y - style.timeline.offsetEvent - 6)
        if let minute = time.minute, let hour = time.hour {
            delegate?.didAddEvent(minute: minute, hour: hour, point: point)
        }
    }
    
    @objc private func swipeEvent(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let endGesure = abs(translation.x) > (frame.width / 3.5)
        let events = scrollView.subviews.filter({ $0 is EventPageView })
        var eventsAllDay: [UIView]
        
        if style.allDay.isPinned {
            eventsAllDay = subviews.filter({ $0 is AllDayEventView })
            eventsAllDay += subviews.filter({ $0 is AllDayTitleView })
        } else {
            eventsAllDay = scrollView.subviews.filter({ $0 is AllDayEventView })
            eventsAllDay += scrollView.subviews.filter({ $0 is AllDayTitleView })
        }
        
        let eventViews = events + eventsAllDay
        
        switch gesture.state {
        case .began, .changed:
            guard abs(velocity.y) < abs(velocity.x) else { break }
            guard endGesure else {
                delegate?.swipeX(transform: CGAffineTransform(translationX: translation.x, y: 0), stop: false)
                
                eventViews.forEach { (view) in
                    view.transform = CGAffineTransform(translationX: translation.x, y: 0)
                }
                break
            }
    
            gesture.state = .ended
        case .failed:
            delegate?.swipeX(transform: .identity, stop: false)
            identityViews(eventViews)
        case .cancelled, .ended:
            guard endGesure else {
                delegate?.swipeX(transform: .identity, stop: false)
                identityViews(eventViews)
                break
            }
            
            let previousDay = translation.x > 0
            let translationX = previousDay ? frame.width : -frame.width
            
            UIView.animate(withDuration: 0.2, animations: { [weak delegate = self.delegate] in
                delegate?.swipeX(transform: CGAffineTransform(translationX: translationX * 0.8, y: 0), stop: true)
                
                eventViews.forEach { (view) in
                    view.transform = CGAffineTransform(translationX: translationX, y: 0)
                }
            }) { [weak delegate = self.delegate] (_) in
                guard previousDay else {
                    delegate?.nextDate()
                    return
                }
                
                delegate?.previousDate()
            }
        case .possible:
            break
        @unknown default:
            fatalError()
        }
    }
    
    private func createTimesLabel(start: Int) -> [TimelineLabel] {
        var times = [TimelineLabel]()
        for (idx, hour) in hours.enumerated() where idx >= start {
            let yTime = (style.timeline.offsetTimeY + style.timeline.heightTime) * CGFloat(idx - start)
            
            let time = TimelineLabel(frame: CGRect(x: style.timeline.offsetTimeX,
                                                   y: yTime,
                                                   width: style.timeline.widthTime,
                                                   height: style.timeline.heightTime))
            time.font = style.timeline.timeFont
            time.textAlignment = .center
            time.textColor = style.timeline.timeColor
            time.text = hour
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let hourTmp = TimeHourSystem.twentyFourHour.hours[idx]
            time.valueHash = formatter.date(from: hourTmp)?.hour.hashValue
            time.tag = idx - start
            times.append(time)
        }
        return times
    }
    
    private func createLines(times: [TimelineLabel]) -> [UIView] {
        var lines = [UIView]()
        for (idx, time) in times.enumerated() {
            let xLine = time.frame.width + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
            let lineFrame = CGRect(x: xLine,
                                   y: time.center.y,
                                   width: frame.width - xLine,
                                   height: style.timeline.heightLine)
            let line = UIView(frame: lineFrame)
            line.backgroundColor = .gray
            line.tag = idx
            lines.append(line)
        }
        return lines
    }
    
    private func createVerticalLine(pointX: CGFloat) -> UIView {
        let frame = CGRect(x: pointX, y: 0, width: 0.5, height: (CGFloat(25) * (style.timeline.heightTime + style.timeline.offsetTimeY)) - 75)
        let line = UIView(frame: frame)
        line.tag = tagVerticalLine
        line.backgroundColor = .systemGray
        line.isHidden = !style.week.showVerticalDayDivider
        return line
    }
    
    private func countEventsInHour(events: [Event]) -> [CrossPageTree] {
        var eventsTemp = events
        var newCountsEvents = [CrossPageTree]()
        
        while !eventsTemp.isEmpty {
            guard let event = eventsTemp.first else { return newCountsEvents }
            
            if let idx = newCountsEvents.firstIndex(where: { $0.parent.start..<$0.parent.end ~= event.start.timeIntervalSince1970 }) {
                newCountsEvents[idx].children.append(Child(start: event.start.timeIntervalSince1970,
                                                           end: event.end.timeIntervalSince1970))
                newCountsEvents[idx].count = newCountsEvents[idx].children.count + 1
            } else if let idx = newCountsEvents.firstIndex(where: { $0.excludeToChildren(event) }) {
                newCountsEvents[idx].children.append(Child(start: event.start.timeIntervalSince1970,
                                                           end: event.end.timeIntervalSince1970))
                newCountsEvents[idx].count = newCountsEvents[idx].children.count + 1
            } else {
                newCountsEvents.append(CrossPageTree(parent: Parent(start: event.start.timeIntervalSince1970,
                                                                    end: event.end.timeIntervalSince1970),
                                                     children: []))
            }
            
            eventsTemp.removeFirst()
        }
        
        return newCountsEvents
    }
    
    private func createAlldayEvents(events: [Event], date: Date?, width: CGFloat, originX: CGFloat) {
        guard !events.isEmpty else { return }
        let pointY = style.allDay.isPinned ? 0 : -style.allDay.height
        let allDay = AllDayEventView(events: events,
                                     frame: CGRect(x: originX, y: pointY, width: width, height: style.allDay.height),
                                     style: style.allDay,
                                     date: date)
        allDay.delegate = self
        let titleView = AllDayTitleView(frame: CGRect(x: 0,
                                                      y: pointY,
                                                      width: style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft,
                                                      height: style.allDay.height),
                                        style: style.allDay)
        
        if subviews.filter({ $0 is AllDayTitleView }).isEmpty || scrollView.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            if style.allDay.isPinned {
                addSubview(titleView)
            } else {
                scrollView.addSubview(titleView)
            }
        }
        if style.allDay.isPinned {
            addSubview(allDay)
        } else {
            scrollView.addSubview(allDay)
        }
    }
    
    private func setOffsetScrollView() {
        var offsetY: CGFloat = 0
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty || !scrollView.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            offsetY = style.allDay.height
        }
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
    }
    
    private func getTimelineLabel(hour: Int) -> TimelineLabel? {
        return scrollView.subviews .filter({ (view) -> Bool in
            guard let time = view as? TimelineLabel else { return false }
            return time.valueHash == hour.hashValue }).first as? TimelineLabel
    }
    
    private func stopTimer() {
        if timer?.isValid ?? true {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func movingCurrentLineHour() {
        guard !(timer?.isValid ?? false) else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let nextDate = Date()
            guard self.currentTimeLabel.valueHash != nextDate.minute.hashValue else { return }
            guard let time = self.getTimelineLabel(hour: nextDate.hour) else { return }
            
            var pointY = time.frame.origin.y
            if !self.subviews.filter({ $0 is AllDayTitleView }).isEmpty, self.style.allDay.isPinned {
                pointY -= self.style.allDay.height
            }
            
            pointY = self.calculatePointYByMinute(nextDate.minute, time: time)
            
            self.currentTimeLabel.frame.origin.y = pointY - 7.5
            self.currentLineView.frame.origin.y = pointY
            self.currentTimeLabel.valueHash = nextDate.minute.hashValue
            
            let formatter = DateFormatter()
            formatter.dateFormat = self.timeHourSystem == .twentyFourHour ? "HH:mm" : "h:mm a"
            self.currentTimeLabel.text = formatter.string(from: nextDate)
            
            if let timeNext = self.getTimelineLabel(hour: nextDate.hour + 1) {
                timeNext.isHidden = self.currentTimeLabel.frame.intersects(timeNext.frame)
            }
            time.isHidden = time.frame.intersects(self.currentTimeLabel.frame)
        }
        
        guard let timer = timer else { return }
        RunLoop.current.add(timer, forMode: .default)
    }
    
    private func showCurrentLineHour() {
        let date = Date()
        guard style.timeline.showCurrentLineHour, let time = getTimelineLabel(hour: date.hour) else {
            currentLineView.removeFromSuperview()
            currentTimeLabel.removeFromSuperview()
            timer?.invalidate()
            return
        }
        
        var pointY = time.frame.origin.y
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty, style.allDay.isPinned {
            pointY -= style.allDay.height
        }
        
        pointY = calculatePointYByMinute(date.minute, time: time)
        
        currentTimeLabel.frame = CGRect(x: style.timeline.offsetTimeX,
                                        y: pointY - 8,
                                        width: style.timeline.currentLineHourWidth,
                                        height: 15)
        currentLineView.frame = CGRect(x: currentTimeLabel.frame.width + style.timeline.offsetTimeX + style.timeline.offsetLineLeft,
                                       y: pointY,
                                       width: scrollView.frame.width - style.timeline.offsetTimeX,
                                       height: 1)
        
        scrollView.addSubview(currentTimeLabel)
        scrollView.addSubview(currentLineView)
        movingCurrentLineHour()
        
        if let timeNext = getTimelineLabel(hour: date.hour + 1) {
            timeNext.isHidden = currentTimeLabel.frame.intersects(timeNext.frame)
        }
        time.isHidden = currentTimeLabel.frame.intersects(time.frame)
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
    
    private func identityViews(duration: TimeInterval = 0.4, delay: TimeInterval = 0.07, _ views: [UIView], action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        }, completion: nil)
    }
    
    private func scrollToCurrentTime(startHour: Int) {
        guard isEnabledAutoScroll else {
            isEnabledAutoScroll = true
            return
        }
        
        guard let time = getTimelineLabel(hour: Date().hour), style.timeline.scrollToCurrentHour else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
        
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func createTimelinePage(dates: [Date?], events: [Event], selectedDate: Date?) {
        delegate?.didDisplayEvents(events, dates: dates)
        self.dates = dates
        self.selectedDate = selectedDate
        
        subviews.filter({ $0 is AllDayEventView || $0 is AllDayTitleView }).forEach({ $0.removeFromSuperview() })
        scrollView.subviews.filter({ $0.tag != tagCurrentHourLine }).forEach({ $0.removeFromSuperview() })
        
        allEvents = events.filter { (event) -> Bool in
            let date = event.start
            return dates.contains(where: { $0?.day == date.day && $0?.month == date.month && $0?.year == date.year })
        }
        let filteredEvents = allEvents.filter({ !$0.isAllDay })
        let filteredAllDayEvents = events.filter({ $0.isAllDay })

        let start: Int
        if !style.timeline.startFromFirstEvent {
            start = 0
        } else {
            if dates.count > 1 {
                start = filteredEvents.sorted(by: { $0.start.hour < $1.start.hour }).first?.start.hour ?? style.timeline.startHour
            } else {
                start = filteredEvents.filter({ compareStartDate(event: $0, date: selectedDate) })
                    .sorted(by: { $0.start.hour < $1.start.hour })
                    .first?.start.hour ?? style.timeline.startHour
            }
        }
        
        // add time label to timline
        let times = createTimesLabel(start: start)
        // add seporator line
        let lines = createLines(times: times)
        
        // calculate all height by time label
        let heightAllTimes = times.reduce(0, { $0 + ($1.frame.height + style.timeline.offsetTimeY) })
        scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes + 20)
        times.forEach({ scrollView.addSubview($0) })
        lines.forEach({ scrollView.addSubview($0) })

        let offset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        let widthPage = (frame.width - offset) / CGFloat(dates.count)
        let heightPage = (CGFloat(times.count) * (style.timeline.heightTime + style.timeline.offsetTimeY)) - 75
        
        // horror
        for (idx, date) in dates.enumerated() {
            let pointX: CGFloat
            if idx == 0 {
                pointX = offset
            } else {
                pointX = CGFloat(idx) * widthPage + offset
            }
            scrollView.addSubview(createVerticalLine(pointX: pointX))
            
            let eventsByDate = filteredEvents
                .filter({ compareStartDate(event: $0, date: date) })
                .sorted(by: { $0.start < $1.start })
            
            let allDayEvents = filteredAllDayEvents.filter({ compareStartDate(event: $0, date: date) || compareEndDate(event: $0, date: date) })
            createAlldayEvents(events: allDayEvents, date: date, width: widthPage, originX: pointX)
            
            // count event cross in one hour
            let countEventsOneHour = countEventsInHour(events: eventsByDate)
            var pagesCached = [EventPageView]()
            
            if !eventsByDate.isEmpty {
                // create event
                var newFrame = CGRect(x: 0, y: 0, width: 0, height: heightPage)
                eventsByDate.forEach { (event) in
                    times.forEach({ (time) in
                        // calculate position 'y'
                        if event.start.hour.hashValue == time.valueHash {
                            newFrame.origin.y = calculatePointYByMinute(event.start.minute, time: time)
                        }
                        // calculate 'height' event
                        if event.end.hour.hashValue == time.valueHash {
                            let summHeight = (CGFloat(time.tag) * (style.timeline.offsetTimeY + time.frame.height)) - newFrame.origin.y + (time.frame.height / 2)
                            if 0..<59 ~= event.end.minute {
                                let minutePercent = 59.0 / CGFloat(event.end.minute)
                                let newY = (style.timeline.offsetTimeY + time.frame.height) / minutePercent
                                newFrame.size.height = summHeight + newY - style.timeline.offsetEvent
                            } else {
                                newFrame.size.height = summHeight - style.timeline.offsetEvent
                            }
                        }
                    })
                    
                    // calculate 'width' and position 'x'
                    var newWidth = widthPage
                    var newPointX = pointX
                    if let idx = countEventsOneHour.firstIndex(where: { $0.parent.start == event.start.timeIntervalSince1970 || $0.equalToChildren(event) }) {
                        let count = countEventsOneHour[idx].count
                        newWidth /= CGFloat(count)
                        
                        if count > 1 {
                            var stop = pagesCached.count
                            while stop != 0 {
                                for page in pagesCached where page.frame.origin.x.rounded() <= newPointX.rounded()
                                    && newPointX.rounded() <= (page.frame.origin.x + page.frame.width).rounded()
                                    && page.frame.origin.y.rounded() <= newFrame.origin.y.rounded()
                                    && newFrame.origin.y <= (page.frame.origin.y + page.frame.height).rounded() {
                                        newPointX = page.frame.origin.x.rounded() + newWidth
                                }
                                stop -= 1
                            }
                        }
                    }
                    newFrame.origin.x = newPointX
                    newFrame.size.width = newWidth - style.timeline.offsetEvent
                    
                    let page = EventPageView(event: event, style: style, frame: newFrame)
                    page.delegate = self
                    scrollView.addSubview(page)
                    pagesCached.append(page)
                }
            }
        }
        setOffsetScrollView()
        scrollToCurrentTime(startHour: start)
        showCurrentLineHour()
    }
}

extension TimelineView: EventPageDelegate {
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer) {
        delegate?.didSelectEvent(event, frame: gesture.view?.frame)
    }
    
    func didStartMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: scrollView)
        
        shadowView.removeFromSuperview()
        if let frame = moveShadowView(pointX: point.x) {
            shadowView.frame = frame
            scrollView.addSubview(shadowView)
        }
    
        eventPreview = nil
        eventPreview = EventPageView(event: eventPage.event,
                                     style: style,
                                     frame: CGRect(origin: CGPoint(x: point.x - eventPreviewXOffset, y: point.y - eventPreviewYOffset), size: eventPreviewSize))
        eventPreview?.alpha = 0.9
        eventPreview?.tag = tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if let eventTemp = eventPreview {
            scrollView.addSubview(eventTemp)
            showChangeMinutes(pointY: point.y)
            UIView.animate(withDuration: 0.3) {
                self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            UIImpactFeedbackGenerator().impactOccurred()
        }
    }
    
    func didEndMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        movingMinutesLabel.removeFromSuperview()
        shadowView.removeFromSuperview()
        
        var point = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        guard scrollView.frame.width >= (point.x + 30), (point.x - 10) >= leftOffset else { return }
        
        let pointTempY = (point.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangeTime(pointY: pointTempY)
        if let minute = time.minute, let hour = time.hour {
            isEnabledAutoScroll = false
            point.x -= eventPreviewXOffset
            delegate?.didChangeEvent(eventPage.event, minute: minute, hour: hour, point: point)
        }
    }
    
    func didChangeMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        guard scrollView.frame.width >= (point.x + 20), (point.x - 20) >= leftOffset else { return }
        
        var offset = scrollView.contentOffset
        if (point.y - 80) < scrollView.contentOffset.y, (point.y - eventPreviewSize.height) >= 0 {
            // scroll up
            offset.y -= 5
            scrollView.setContentOffset(offset, animated: false)
        } else if (point.y + 80) > (scrollView.contentOffset.y + scrollView.bounds.height), point.y + eventPreviewSize.height <= scrollView.contentSize.height {
            // scroll down
            offset.y += 5
            scrollView.setContentOffset(offset, animated: false)
        }
        
        eventPreview?.frame.origin = CGPoint(x: point.x - eventPreviewXOffset, y: point.y - eventPreviewYOffset)
        showChangeMinutes(pointY: point.y)
        
        if let frame = moveShadowView(pointX: point.x) {
            shadowView.frame = frame
        }
    }
    
    private func showChangeMinutes(pointY: CGFloat) {
        movingMinutesLabel.removeFromSuperview()
        
        let pointTempY = (pointY - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangeTime(pointY: pointTempY)
        if style.timeline.offsetTimeY > 50, let minute = time.minute, 0...59 ~= minute {
            let offset = eventPreviewYOffset - style.timeline.offsetEvent - 6
            movingMinutesLabel.frame =  CGRect(x: style.timeline.offsetTimeX, y: (pointY - offset) - style.timeline.heightTime,
                                               width: style.timeline.widthTime, height: style.timeline.heightTime)
            scrollView.addSubview(movingMinutesLabel)
            movingMinutesLabel.text = ":\(minute)"
        }
    }
    
    private func calculateChangeTime(pointY: CGFloat) -> (hour: Int?, minute: Int?) {
        let times = scrollView.subviews.filter({ ($0 is TimelineLabel) }).compactMap({ $0 as? TimelineLabel })
        guard let time = times.first( where: { $0.frame.origin.y >= pointY }) else { return (nil, nil) }

        let firstY = time.frame.origin.y - (style.timeline.offsetTimeY + style.timeline.heightTime)
        let percent = (pointY - firstY) / (style.timeline.offsetTimeY + style.timeline.heightTime)
        let newMinute = Int(60.0 * percent)
        return (time.tag - 1, newMinute)
    }
    
    private func moveShadowView(pointX: CGFloat) -> CGRect? {
        guard type == .week else { return nil }
        
        let lines = scrollView.subviews.filter({ $0.tag == tagVerticalLine })
        var width: CGFloat = 200
        if let firstLine = lines[safe: 0], let secondLine = lines[safe: 1] {
            width = secondLine.frame.origin.x - firstLine.frame.origin.x
        }
        guard let line = lines.first(where: { $0.frame.origin.x...($0.frame.origin.x + width) ~= pointX }) else { return nil }
        
        return CGRect(origin: line.frame.origin, size: CGSize(width: width, height: line.bounds.height))
    }
}

extension TimelineView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size = frame.size
        scrollView.frame.size = frame.size
        scrollView.contentSize.width = frame.size.width
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
}

extension TimelineView: AllDayEventDelegate {
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, frame: frame)
    }
}
