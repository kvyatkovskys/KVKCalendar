//
//  TimelineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

protocol TimelineDelegate: AnyObject {
    func didSelectEventInTimeline(_ event: Event, frame: CGRect?)
    func nextDate()
    func previousDate()
    func swipeX(transform: CGAffineTransform, stop: Bool)
}

final class TimelineView: UIView {
    weak var delegate: TimelineDelegate?
    
    private let tagCurrentHourLine = -10
    private let tagCurrentHourTime = -20
    private var style: Style
    private let hours: [String]
    private let timeHourSystem: TimeHourSystem
    private var allEvents = [Event]()
    private var timer: Timer?
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.tag = tagCurrentHourTime
        label.textColor = style.timelineStyle.currentLineHourColor
        label.textAlignment = .center
        label.font = style.timelineStyle.currentLineHourFont
        label.adjustsFontSizeToFitWidth = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = timeHourSystem == .twentyFourHour ? "HH:mm" : "H:mm a"
        label.text = formatter.string(from: Date())
        
        return label
    }()
    private lazy var currentLineView: UIView = {
        let view = UIView()
        view.tag = tagCurrentHourLine
        view.backgroundColor = style.timelineStyle.currentLineHourColor
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = style.timelineStyle.backgroundColor
        return scroll
    }()
    
    init(timeHourSystem: TimeHourSystem, style: Style, frame: CGRect) {
        self.timeHourSystem = timeHourSystem
        self.hours = timeHourSystem.hours
        self.style = style
        super.init(frame: frame)
        
        var scrollFrame = frame
        scrollFrame.origin.y = 0
        scrollView.frame = scrollFrame
        addSubview(scrollView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeGesure))
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func swipeGesure(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let endGesure = abs(translation.x) > (frame.width / 3.5)
        let events = scrollView.subviews.filter({ $0 is EventPageView })
        var eventsAllDay: [UIView]
        
        if style.allDayStyle.isPinned {
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
            let yTime = (style.timelineStyle.offsetTimeY + style.timelineStyle.heightTime) * CGFloat(idx - start)
            
            let time = TimelineLabel(frame: CGRect(x: style.timelineStyle.offsetTimeX,
                                                   y: yTime,
                                                   width: style.timelineStyle.widthTime,
                                                   height: style.timelineStyle.heightTime))
            time.font = style.timelineStyle.timeFont
            time.textAlignment = .center
            time.textColor = style.timelineStyle.timeColor
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
            let xLine = time.frame.width + style.timelineStyle.offsetTimeX + style.timelineStyle.offsetLineLeft
            let lineFrame = CGRect(x: xLine,
                                   y: time.center.y,
                                   width: frame.width - xLine,
                                   height: style.timelineStyle.heightLine)
            let line = UIView(frame: lineFrame)
            line.backgroundColor = .gray
            line.tag = idx
            lines.append(line)
        }
        return lines
    }
    
    private func createVerticalLine(pointX: CGFloat) -> UIView {
        let frame = CGRect(x: pointX, y: 0, width: 0.5, height: (CGFloat(25) * (style.timelineStyle.heightTime + style.timelineStyle.offsetTimeY)) - 75)
        let line = UIView(frame: frame)
        line.tag = -999
        line.backgroundColor = .lightGray
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
        let pointY = style.allDayStyle.isPinned ? 0 : -style.allDayStyle.height
        let allDay = AllDayEventView(events: events,
                                     frame: CGRect(x: originX, y: pointY, width: width, height: style.allDayStyle.height),
                                     style: style.allDayStyle,
                                     date: date)
        allDay.delegate = self
        let titleView = AllDayTitleView(frame: CGRect(x: 0,
                                                      y: pointY,
                                                      width: style.timelineStyle.widthTime + style.timelineStyle.offsetTimeX + style.timelineStyle.offsetLineLeft,
                                                      height: style.allDayStyle.height),
                                        style: style.allDayStyle)
        
        if subviews.filter({ $0 is AllDayTitleView }).isEmpty || scrollView.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            if style.allDayStyle.isPinned {
                addSubview(titleView)
            } else {
                scrollView.addSubview(titleView)
            }
        }
        if style.allDayStyle.isPinned {
            addSubview(allDay)
        } else {
            scrollView.addSubview(allDay)
        }
    }
    
    private func setOffsetScrollView() {
        var offsetY: CGFloat = 0
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty || !scrollView.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            offsetY = style.allDayStyle.height
        }
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func tapOnEvent(gesture: UITapGestureRecognizer) {
        guard let hashValue = gesture.view?.tag else { return }
        if let idx = allEvents.firstIndex(where: { "\($0.id)".hashValue == hashValue }) {
            let event = allEvents[idx]
            delegate?.didSelectEventInTimeline(event, frame: gesture.view?.frame)
        }
    }
    
    private func compareStartDate(event: Event, date: Date?) -> Bool {
        return event.start.year == date?.year && event.start.month == date?.month && event.start.day == date?.day
    }
    
    private func compareEndDate(event: Event, date: Date?) -> Bool {
        return event.end.year == date?.year && event.end.month == date?.month && event.end.day == date?.day
    }
    
    private func getTimelineLabel(hour: Int) -> TimelineLabel? {
        return scrollView.subviews .filter({ (view) -> Bool in
            guard let time = view as? TimelineLabel else { return false }
            return time.valueHash == hour.hashValue }).first as? TimelineLabel
    }
    
    private func currentLineHour() {
        let date = Date()
        var comps = style.calendar.dateComponents([.era, .year, .month, .day, .hour, .minute], from: date)
        comps.minute = (comps.minute ?? 0) + 1
        guard let nextMinute = style.calendar.date(from: comps) else { return }
        
        if #available(iOS 10.0, *) {
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            timer = Timer(fire: nextMinute, interval: 60, repeats: true) { [unowned self] _ in
                guard let time = self.getTimelineLabel(hour: date.hour) else { return }
                
                var pointY = time.frame.origin.y
                if !self.subviews.filter({ $0 is AllDayTitleView }).isEmpty {
                    if self.style.allDayStyle.isPinned {
                        pointY -= self.style.allDayStyle.height
                    }
                }
                
                pointY = self.calculatePointYByMinute(date.minute, time: time)
                
                self.currentTimeLabel.frame.origin.y = pointY - 5
                self.currentLineView.frame.origin.y = pointY
                
                let formatter = DateFormatter()
                formatter.dateFormat = self.timeHourSystem == .twentyFourHour ? "HH:mm" : "H:mm a"
                self.currentTimeLabel.text = formatter.string(from: date)
                
                if let timeNext = self.getTimelineLabel(hour: date.hour + 1) {
                    timeNext.isHidden = self.currentTimeLabel.frame.intersects(timeNext.frame)
                }
                time.isHidden = time.frame.intersects(self.currentTimeLabel.frame)
            }
            
            guard let timer = timer else { return }
            RunLoop.current.add(timer, forMode: .default)
        }
    }
    
    private func showCurrentLineHour() {
        guard style.timelineStyle.showCurrentLineHour else { return }
        
        let date = Date()
        guard let time = getTimelineLabel(hour: date.hour) else { return }
        
        var pointY = time.frame.origin.y
        if !subviews.filter({ $0 is AllDayTitleView }).isEmpty {
            if style.allDayStyle.isPinned {
                pointY -= style.allDayStyle.height
            }
        }
        
        pointY = calculatePointYByMinute(date.minute, time: time)
        
        currentTimeLabel.frame = CGRect(x: style.timelineStyle.offsetTimeX,
                                        y: pointY - 10,
                                        width: style.timelineStyle.currentLineHourWidth,
                                        height: 15)
        currentLineView.frame = CGRect(x: currentTimeLabel.frame.width + style.timelineStyle.offsetTimeX + style.timelineStyle.offsetLineLeft,
                                       y: pointY,
                                       width: scrollView.frame.width - style.timelineStyle.offsetTimeX,
                                       height: 1)
        
        scrollView.addSubview(currentTimeLabel)
        scrollView.addSubview(currentLineView)
        currentLineHour()
        
        if let timeNext = getTimelineLabel(hour: date.hour + 1) {
            timeNext.isHidden = currentTimeLabel.frame.intersects(timeNext.frame)
        }
        time.isHidden = currentTimeLabel.frame.intersects(time.frame)
    }
    
    private func calculatePointYByMinute(_ minute: Int, time: TimelineLabel) -> CGFloat {
        let pointY: CGFloat
        if 1...59 ~= minute {
            let minutePercent = 59.0 / CGFloat(minute)
            let newY = (style.timelineStyle.offsetTimeY + time.frame.height) / minutePercent
            let summY = (CGFloat(time.tag) * (style.timelineStyle.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
            if time.tag == 0 {
                pointY = newY + (time.frame.height / 2)
            } else {
                pointY = summY + newY
            }
        } else {
            pointY = (CGFloat(time.tag) * (style.timelineStyle.offsetTimeY + time.frame.height)) + (time.frame.height / 2)
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
    
    func scrollToCurrentTime(startHour: Int) {
        guard let time = getTimelineLabel(hour: Date().hour), style.timelineStyle.scrollToCurrentHour else {
            scrollView.setContentOffset(.zero, animated: true)
            return
        }
        
        var frame = scrollView.frame
        frame.origin.y = time.frame.origin.y
        scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func createTimelinePage(dates: [Date?], events: [Event], selectedDate: Date?) {
        subviews.filter({ $0 is AllDayEventView || $0 is AllDayTitleView }).forEach({ $0.removeFromSuperview() })
        scrollView.subviews.forEach({ $0.removeFromSuperview() })
        subviews.filter({ $0.tag == -999 }).forEach({ $0.removeFromSuperview() })
        
        allEvents = events.filter { (event) -> Bool in
            let date = event.start
            return dates.contains(where: { $0?.day == date.day && $0?.month == date.month && $0?.year == date.year })
        }
        let filteredEvents = allEvents.filter({ !$0.isAllDay })
        let filteredAllDayEvents = events.filter({ $0.isAllDay })

        let start: Int
        if dates.count > 1 {
            start = filteredEvents.sorted(by: { $0.start.hour < $1.start.hour }).first?.start.hour ?? style.timelineStyle.startHour
        } else {
            start = filteredEvents.filter({ compareStartDate(event: $0, date: selectedDate) })
                .sorted(by: { $0.start.hour < $1.start.hour })
                .first?.start.hour ?? style.timelineStyle.startHour
        }
        
        // add time label to timline
        let times = createTimesLabel(start: start)
        
        // add seporator line
        let lines = createLines(times: times)
        
        // calculate all height by time label
        let heightAllTimes = times.reduce(0, { $0 + ($1.frame.height + style.timelineStyle.offsetTimeY) })
        scrollView.contentSize = CGSize(width: frame.width, height: heightAllTimes + 20)
        times.forEach({ scrollView.addSubview($0) })
        lines.forEach({ scrollView.addSubview($0) })

        let offset = style.timelineStyle.widthTime + style.timelineStyle.offsetTimeX + style.timelineStyle.offsetLineLeft
        let widthPage = (frame.width - offset) / CGFloat(dates.count)
        let heightPage = (CGFloat(times.count) * (style.timelineStyle.heightTime + style.timelineStyle.offsetTimeY)) - 75
        
        // horror
        for (idx, date) in dates.enumerated() {
            let pointX: CGFloat
            if idx == 0 {
                pointX = offset
            } else {
                pointX = CGFloat(idx) * widthPage + offset
            }
            
            if style.weekStyle.showVerticalDayDivider {
                addSubview(createVerticalLine(pointX: pointX))
            }
            
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
                            let summHeight = (CGFloat(time.tag) * (style.timelineStyle.offsetTimeY + time.frame.height)) - newFrame.origin.y + (time.frame.height / 2)
                            if event.end.minute > 0 && event.end.minute <= 59 {
                                let minutePercent = 59.0 / CGFloat(event.end.minute)
                                let newY = (style.timelineStyle.offsetTimeY + time.frame.height) / minutePercent
                                newFrame.size.height = summHeight + newY - style.timelineStyle.offsetEvent
                            } else {
                                newFrame.size.height = summHeight - style.timelineStyle.offsetEvent
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
                                for page in pagesCached {
                                    if page.frame.origin.x.rounded() <= newPointX.rounded()
                                        && newPointX.rounded() <= (page.frame.origin.x + page.frame.width).rounded()
                                        && page.frame.origin.y.rounded() <= newFrame.origin.y.rounded()
                                        && newFrame.origin.y <= (page.frame.origin.y + page.frame.height).rounded() {
                                        newPointX = page.frame.origin.x.rounded() + newWidth
                                    }
                                }
                                stop -= 1
                            }
                        }
                    }
                    newFrame.origin.x = newPointX
                    newFrame.size.width = newWidth - style.timelineStyle.offsetEvent
                    
                    let page = EventPageView(event: event, style: style.timelineStyle, frame: newFrame)
                    page.tag = "\(event.id)".hashValue
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
                    page.addGestureRecognizer(tap)
                    
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
        delegate?.didSelectEventInTimeline(event, frame: frame)
    }
}

private struct CrossPageTree: Hashable {
    let parent: Parent
    var children: [Child]
    var count: Int
    
    init(parent: Parent, children: [Child]) {
        self.parent = parent
        self.children = children
        self.count = children.count + 1
    }
    
    func equalToChildren(_ event: Event) -> Bool {
        return children.contains(where: { $0.start == event.start.timeIntervalSince1970 })
    }
    
    func excludeToChildren(_ event: Event) -> Bool {
        return children.contains(where: { $0.start..<$0.end ~= event.start.timeIntervalSince1970 })
    }
    
    static func == (lhs: CrossPageTree, rhs: CrossPageTree) -> Bool {
        return lhs.parent == rhs.parent
            && lhs.children == rhs.children
            && lhs.count == rhs.count
    }
}

private struct Parent: Equatable, Hashable {
    let start: TimeInterval
    let end: TimeInterval
}

private struct Child: Equatable, Hashable {
    let start: TimeInterval
    let end: TimeInterval
}
