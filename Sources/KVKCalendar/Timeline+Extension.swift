//
//  TimelineView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

import UIKit

extension TimelineView: UIScrollViewDelegate {
    
    var contentOffset: CGPoint {
        get {
            return scrollView.contentOffset
        }
        set {
            scrollView.setContentOffset(newValue, animated: false)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        addStubInvisibleEvents()
    }
    
    func addStubInvisibleEvents() {
        guard !style.timeline.isHiddenStubEvent else { return }
        
        let events = scrollView.subviews.compactMap { (view) -> StubEvent? in
            guard let item = view as? EventViewGeneral else { return nil }
            
            return StubEvent(event: item.event, frame: item.frame)
        }
        
        var eventsAllDay: [StubEvent] = []
        if !style.allDay.isPinned && !style.allDay.isHiddenStubEvent {
            eventsAllDay = scrollView.subviews.compactMap { (view) -> [StubEvent]? in
                guard let item = view as? AllDayView else { return nil }
                
                return item.items.flatMap({ $0.compactMap({ item in StubEvent(event: item.event, frame: view.frame)}) })
            }.flatMap({ $0 })
        }
        
        let stubEvents = events + eventsAllDay
        stubEvents.forEach { (eventView) in
            guard let stack = getStubStackView(day: eventView.event.start.day) else { return }
            
            stack.top.subviews.filter({ ($0 as? StubEventView)?.valueHash == eventView.event.hash }).forEach({ $0.removeFromSuperview() })
            stack.bottom.subviews.filter({ ($0 as? StubEventView)?.valueHash == eventView.event.hash }).forEach({ $0.removeFromSuperview() })

            guard !visibleView(eventView.frame) else { return }
            
            let stubView = StubEventView(event: eventView.event, frame: CGRect(x: 0, y: 0, width: stack.top.frame.width, height: style.event.heightStubView))
            stubView.valueHash = eventView.event.hash
            
            if scrollView.contentOffset.y > eventView.frame.origin.y {
                stack.top.addArrangedSubview(stubView)
                
                if stack.top.subviews.count >= 1 {
                    switch stack.top.axis {
                    case .vertical:
                        stack.top.frame.size.height = style.event.heightStubView * CGFloat(stack.top.subviews.count)
                    case .horizontal:
                        let newWidth = stack.top.frame.width / CGFloat(stack.top.subviews.count) - 3
                        stack.top.subviews.forEach({ $0.frame.size.width = newWidth })
                    @unknown default:
                        fatalError()
                    }
                }
            } else {
                stack.bottom.insertArrangedSubview(stubView, at: 0)
                
                if stack.bottom.subviews.count >= 1 {
                    switch stack.bottom.axis {
                    case .horizontal:
                        let newWidth = stack.bottom.frame.width / CGFloat(stack.bottom.subviews.count) - 3
                        stack.bottom.subviews.forEach({ $0.frame.size.width = newWidth })
                    case .vertical:
                        stack.bottom.frame.size.height = style.event.heightStubView * CGFloat(stack.bottom.subviews.count)
                        stack.bottom.frame.origin.y = (frame.height - stack.bottom.frame.height) - bottomStabStackOffsetY
                    @unknown default:
                        fatalError()
                    }
                }
            }
            
            stubView.setRoundCorners(style.event.eventCorners, radius: style.event.eventCornersRadius)
        }
    }
    
    private func getDayEvent(_ event: Event, scrollDirection: ScrollDirectionType) -> Int {
        if event.start.day == event.end.day {
            return event.start.day
        } else {
            switch scrollDirection {
            case .up:
                return event.start.day
            case .down:
                return event.start.day
            }
        }
    }
    
    private func visibleView(_ frame: CGRect) -> Bool {
        let container = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        return frame.intersects(container)
    }
    
    func getStubStackView(day: Int) -> (top: StubStackView, bottom: StubStackView)? {
        let filtered = subviews.filter({ $0.tag == tagStubEvent }).compactMap({ $0 as? StubStackView })
        guard let topStack = filtered.first(where: { $0.type == .top && $0.day == day }),
              let bottomStack = filtered.first(where: { $0.type == .bottom && $0.day == day }) else { return nil }
        
        return (topStack, bottomStack)
    }
    
    func createStackView(day: Int, type: StubStackView.PositionType, frame: CGRect) -> StubStackView {
        let view = StubStackView(type: type, frame: frame, day: day)
        view.distribution = .fillEqually
        view.axis = style.event.alignmentStubView
        view.alignment = .fill
        view.spacing = style.event.spacingStubView
        view.tag = tagStubEvent
        return view
    }
}

extension TimelineView {
    var bottomStabStackOffsetY: CGFloat {
        return UIApplication.shared.isAvailableBottomHomeIndicator ? 30 : 5
    }
    
    func topStabStackOffsetY(allDayEventsIsPinned: Bool, eventsCount: Int, height: CGFloat) -> CGFloat {
        return allDayEventsIsPinned ? (CGFloat(eventsCount) * height) + 5 : 5
    }
    
    var scrollableEventViews: [UIView] {
        return getAllScrollableEvents()
    }
}

extension TimelineView {
    private func removeEventResizeView() {
        if let value = eventResizePreview?.haveNewSize, value.needSave, let event = eventResizePreview?.event {
            var startTime: (hour: Int?, minute: Int?)
            var endTime: (hour: Int?, minute: Int?)
            
            if let time = eventResizePreview?.startTime {
                startTime = (time.hour, time.minute)
            } else {
                startTime = (eventResizePreview?.event.start.hour, eventResizePreview?.event.start.minute)
            }
            
            if let time = eventResizePreview?.endTime {
                endTime = (time.hour, time.minute)
            } else {
                endTime = (eventResizePreview?.event.end.hour, eventResizePreview?.event.end.minute)
            }
            
            if let startHour = startTime.hour, let endHour = endTime.hour, let startMinute = startTime.minute, let endMinute = endTime.minute {
                delegate?.didResizeEvent(event, startTime: ResizeTime(startHour, startMinute), endTime: ResizeTime(endHour, endMinute))
            }
        }
        
        eventResizePreview?.frame = .zero
        eventResizePreview?.removeFromSuperview()
        eventResizePreview = nil
        isResizeEnableMode = false
        enableAllEvents(enable: true)
    }
    
    private func enableAllEvents(enable: Bool) {
        if style.allDay.isPinned {
            subviews.filter({ $0.tag == tagAllDayEventView }).forEach({ $0.isUserInteractionEnabled = enable })
        } else {
            scrollView.subviews.filter({ $0.tag == tagAllDayEventView }).forEach({ $0.isUserInteractionEnabled = enable })
        }
        
        scrollView.subviews.filter({ $0 is EventViewGeneral }).forEach({ $0.isUserInteractionEnabled = enable })
    }
    
    @objc func forceDeselectEvent() {
        removeEventResizeView()
        
        guard let eventViewGeneral = scrollView.subviews.first(where: { ($0 as? EventViewGeneral)?.isSelected == true }) as? EventViewGeneral else { return }
        
        guard let eventView = eventViewGeneral as? EventView else {
            deselectEvent?(eventViewGeneral.event)
            return
        }
        
        eventView.deselectEvent()
    }
    
    func reloadData() {
        create(dates: dates, events: events, selectedDate: selectedDate)
    }
    
    func deselectEvent(_ event: Event, animated: Bool) {
        guard let eventViewGeneral = scrollView.subviews.first(where: { ($0 as? EventViewGeneral)?.event.ID == event.ID }) as? EventViewGeneral else { return }
        
        guard let eventView = eventViewGeneral as? EventView else {
            deselectEvent?(eventViewGeneral.event)
            return
        }
        
        eventView.deselectEvent()
    }
    
    func createAllDayEvents(events: [AllDayView.PrepareEvents], maxEvents: Int) {
        guard !events.isEmpty else { return }
        
        var allDayHeight = style.allDay.height
        if 3...4 ~= maxEvents {
            allDayHeight *= 2
        } else if maxEvents > 4 {
            allDayHeight = style.allDay.maxHeight
        }
        let y: CGFloat
        if style.allDay.isPinned {
            y = 0
        } else {
            y = -allDayHeight
        }
        
        let newAllDayView = AllDayView(parameters: .init(prepareEvents: events, type: type, style: style, delegate: delegate),
                                       frame: CGRect(x: 0, y: y, width: bounds.width, height: allDayHeight))
        newAllDayView.tag = tagAllDayEventView
        if style.allDay.isPinned {
            addSubview(newAllDayView)
        } else {
            scrollView.addSubview(newAllDayView)
        }
    }
    
    func createTimesLabel(start: Int) -> [TimelineLabel] {
        var times = [TimelineLabel]()
        for (idx, hour) in availabilityHours.enumerated() where idx >= start {
            let yTime = (style.timeline.offsetTimeY + style.timeline.heightTime) * CGFloat(idx - start)
            
            let time = TimelineLabel(frame: CGRect(x: style.timeline.offsetTimeX,
                                                   y: yTime,
                                                   width: style.timeline.widthTime,
                                                   height: style.timeline.heightTime))
            time.font = style.timeline.timeFont
            time.textAlignment = .center
            time.textColor = style.timeline.timeColor
            time.text = hour
            let hourTmp = TimeHourSystem.twentyFour.hours[idx]
            time.valueHash = timeLabelFormatter.date(from: hourTmp)?.hour.hashValue
            time.tag = idx - start
            times.append(time)
        }
        return times
    }
    
    func createLines(times: [TimelineLabel]) -> [UIView] {
        var lines = [UIView]()
        for (idx, time) in times.enumerated() {
            let xLine = time.frame.width + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
            let lineFrame = CGRect(x: xLine,
                                   y: time.center.y,
                                   width: frame.width - xLine,
                                   height: style.timeline.heightLine)
            let line = UIView(frame: lineFrame)
            line.backgroundColor = style.timeline.separatorLineColor
            line.tag = idx
            lines.append(line)
        }
        return lines
    }
    
    func createVerticalLine(pointX: CGFloat, date: Date?) -> VerticalLineView {
        let frame = CGRect(x: pointX, y: 0, width: style.timeline.widthLine, height: scrollView.contentSize.height)
        let line = VerticalLineView(frame: frame)
        line.tag = tagVerticalLine
        line.backgroundColor = style.timeline.separatorLineColor
        line.isHidden = !style.week.showVerticalDayDivider
        line.date = date
        return line
    }
    
    func getEventView(style: Style, event: Event, frame: CGRect, date: Date? = nil) -> EventViewGeneral {
        if let pageView = dataSource?.willDisplayEventView(event, frame: frame, date: date) {
            return pageView
        } else {
            return EventView(event: event, style: style, frame: frame)
        }
    }
    
    @objc func addNewEvent(gesture: UILongPressGestureRecognizer) {
        guard !isResizeEnableMode else { return }
        
        var point = gesture.location(in: scrollView)
        point.y = (point.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangingTime(pointY: point.y)
        var newEvent = Event(ID: Event.idForNewEvent)
        newEvent.text = style.event.textForNewEvent
        let newEventPreview = getEventView(style: style, event: newEvent, frame: CGRect(origin: point, size: eventPreviewSize))
        newEventPreview.stateEvent = .move
        newEventPreview.delegate = self
        newEventPreview.editEvent(gesture: gesture)
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator().impactOccurred()
        case .ended, .failed, .cancelled:
            guard let minute = time.minute, let hour = time.hour else { return }
            
            switch type {
            case .day:
                newEvent.start = selectedDate ?? Date()
            case .week:
                newEvent.start = shadowView.date ?? Date()
            default:
                break
            }
            
            newEvent.end = style.calendar.date(byAdding: .minute, value: 15, to: newEvent.start) ?? Date()
            delegate?.didAddNewEvent(newEvent, minute: minute, hour: hour, point: point)
        default:
            break
        }
    }
    
    func moveEvents(offset: CGFloat?, stop: Bool = false) {
        if stop {
            identityViews(scrollableEventViews)
            return
        }
        
        guard let offsetEvents = offset else { return }
        
        scrollableEventViews.forEach { (view) in
            view.transform = CGAffineTransform(translationX: offsetEvents, y: 0)
        }
    }
    
    private func getAllScrollableEvents() -> [UIView] {
        let events = scrollView.subviews.filter({ $0 is EventViewGeneral })
        
        let eventsAllDay: [UIView]
        if style.allDay.isPinned {
            eventsAllDay = subviews.filter({ $0.tag == tagAllDayEventView })
        } else {
            eventsAllDay = scrollView.subviews.filter({ $0.tag == tagAllDayEventView })
        }
        
        let stackViews = subviews.filter({ $0 is StubStackView })
        
        let eventViews = events + eventsAllDay + stackViews
        return eventViews
    }
    
    func identityViews(duration: TimeInterval = 0.3, delay: TimeInterval = 0.1, _ views: [UIView], action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        })
    }
}

extension TimelineView: EventDataSource {
    @available(iOS 13, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? {
        return nil
    }
}

// MARK: ResizeEventViewDelegate
extension TimelineView: ResizeEventViewDelegate {
    func didStart(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType) {
        let location = gesture.location(in: scrollView)
        switch type {
        case .top:
            let offset = location.y + (eventResizePreview?.mainYOffset ?? 0) + style.timeline.offsetEvent
            let offsetY = (eventResizePreview?.frame.origin.y ?? 0) - location.y
            let endY = (eventResizePreview?.originalFrameEventView.height ?? 0) + (eventResizePreview?.originalFrameEventView.origin.y ?? 0)
            guard endY - location.y > 70 else { return }
            
            showChangingMinute(pointY: offset)
            eventResizePreview?.frame.origin.y = location.y
            eventResizePreview?.frame.size.height += offsetY
            eventResizePreview?.startTime = movingMinuteLabel.time
        case .bottom:
            let offset = location.y - (eventResizePreview?.mainYOffset ?? 0) + style.timeline.offsetEvent
            guard (location.y - (eventResizePreview?.frame.origin.y ?? 0)) > 80 else { return }
            
            showChangingMinute(pointY: offset)
            eventResizePreview?.frame.size.height = location.y - (eventResizePreview?.frame.origin.y ?? 0)
            eventResizePreview?.endTime = movingMinuteLabel.time
        }
        
        eventResizePreview?.updateHeight()
    }
    
    func didEnd(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType) {
        movingMinuteLabel.removeFromSuperview()
    }
    
    func didStartMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer, view: UIView) {
        
    }
    
    func didChangeMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer) {
        
    }
    
    func didEndMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer) {
        
    }
}

// MARK: EventDelegate
extension TimelineView: EventDelegate {
    var eventPreviewXOffset: CGFloat {
        return eventPreviewSize.width * 0.5
    }
    
    var eventPreviewYOffset: CGFloat {
        return eventPreviewSize.height * 0.7
    }
    
    func deselectEvent(_ event: Event) {
        deselectEvent?(event)
    }
    
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer) {
        forceDeselectEvent()
        delegate?.didSelectEvent(event, frame: gesture.view?.frame)
    }
    
    func didStartResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView) {
        forceDeselectEvent()
        isResizeEnableMode = true
        
        var viewFrame = view.frame
        if viewFrame.width < 50 {
            viewFrame.size.width = 50
        }
        if viewFrame.height < 60 {
            viewFrame.size.height = 60
        }
        
        let viewTmp: UIView
        if view is EventView {
            let eventView = EventView(event: event, style: style, frame: viewFrame)
            eventView.textView.isHidden = false
            eventView.selectEvent()
            eventView.isUserInteractionEnabled = false
            viewTmp = eventView
            viewTmp.frame = viewFrame
        } else {
            viewTmp = view.snapshotView(afterScreenUpdates: false) ?? view
            viewTmp.frame = viewFrame
        }
        
        eventResizePreview = ResizeEventView(view: viewTmp, event: event, frame: viewTmp.frame, style: style)
        eventResizePreview?.delegate = self
        if let resizeView = eventResizePreview {
            scrollView.addSubview(resizeView)
        }
        enableAllEvents(enable: false)
    }
    
    func didEndResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        removeEventResizeView()
    }
    
    func didStartMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView) {
        removeEventResizeView()
        let location = gesture.location(in: scrollView)
        
        shadowView.removeFromSuperview()
        if let value = moveShadowView(pointX: location.x) {
            shadowView.frame = value.frame
            shadowView.date = value.date
            scrollView.addSubview(shadowView)
        }
    
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        
        if view is EventView {
            eventPreviewSize = CGSize(width: 150, height: 150)
            eventPreview = EventView(event: event,
                                     style: style,
                                     frame: CGRect(origin: CGPoint(x: location.x - eventPreviewXOffset, y: location.y - eventPreviewYOffset),
                                                   size: eventPreviewSize))
        } else {
            eventPreview = event.isNew ? view : view.snapshotView(afterScreenUpdates: false)
            if let size = eventPreview?.frame.size {
                eventPreviewSize = size
            }
            eventPreview?.frame.origin = CGPoint(x: location.x - eventPreviewXOffset, y: location.y - eventPreviewYOffset)
        }
        
        eventPreview?.alpha = 0.9
        eventPreview?.tag = tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if let eventTemp = eventPreview {
            scrollView.addSubview(eventTemp)
            let offset = eventPreviewYOffset - style.timeline.offsetEvent - 6
            showChangingMinute(pointY: location.y, offset: offset)
            UIView.animate(withDuration: 0.3) {
                self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
    }
    
    func didEndMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        movingMinuteLabel.removeFromSuperview()
        
        var location = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        guard scrollView.frame.width >= (location.x + 30), (location.x - 10) >= leftOffset else { return }
        
        location.y = (location.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let startTime = calculateChangingTime(pointY: location.y)
        if let minute = startTime.minute, let hour = startTime.hour, !event.isNew {
            var newDayEvent: Int?
            var updatedEvent = event
            
            if type == .week, let newDate = shadowView.date {
                newDayEvent = newDate.day
                
                if event.recurringType != .none {
                    updatedEvent = event.updateDate(newDate: newDate, calendar: style.calendar) ?? event
                }
            }
            delegate?.didChangeEvent(updatedEvent, minute: minute, hour: hour, point: location, newDay: newDayEvent)
        }
        
        shadowView.removeFromSuperview()
    }
    
    func didChangeMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        guard scrollView.frame.width >= (location.x + 20), (location.x - 20) >= leftOffset else { return }
        
        var offset = scrollView.contentOffset
        if (location.y - 80) < scrollView.contentOffset.y, (location.y - eventPreviewSize.height) >= 0 {
            // scroll up
            offset.y -= 5
            scrollView.setContentOffset(offset, animated: false)
        } else if (location.y + 80) > (scrollView.contentOffset.y + scrollView.bounds.height), location.y + eventPreviewSize.height <= scrollView.contentSize.height {
            // scroll down
            offset.y += 5
            scrollView.setContentOffset(offset, animated: false)
        }
        
        eventPreview?.frame.origin = CGPoint(x: location.x - eventPreviewXOffset, y: location.y - eventPreviewYOffset)
        let offsetMinutes = eventPreviewYOffset - style.timeline.offsetEvent - 6
        showChangingMinute(pointY: location.y, offset: offsetMinutes)
        
        if let value = moveShadowView(pointX: location.x) {
            shadowView.frame = value.frame
            shadowView.date = value.date
        }
    }
    
    private func showChangingMinute(pointY: CGFloat, offset: CGFloat = 0) {
        movingMinuteLabel.removeFromSuperview()
        
        var pointTempY = pointY - style.timeline.offsetEvent - 6
        if eventResizePreview == nil {
            pointTempY -= eventPreviewYOffset
        }
        let time = calculateChangingTime(pointY: pointTempY)
        movingMinuteLabel.time = TimeContainer(minute: 0, hour: time.hour ?? 0)
        
        if let minute = time.minute, 0...59 ~= minute {
            movingMinuteLabel.frame = CGRect(x: style.timeline.offsetTimeX, y: (pointY - offset) - style.timeline.heightTime,
                                             width: style.timeline.widthTime, height: style.timeline.heightTime)
            scrollView.addSubview(movingMinuteLabel)
            movingMinuteLabel.text = ":\(minute)"
            movingMinuteLabel.time?.minute = minute
        } else {
            movingMinuteLabel.text = ":0"
            movingMinuteLabel.time?.minute = 0
        }
    }
    
    func calculateChangingTime(pointY: CGFloat) -> (hour: Int?, minute: Int?) {
        guard let time = timeLabels.first(where: { $0.frame.origin.y >= pointY }) else { return (nil, nil) }

        let firstY = time.frame.origin.y - (style.timeline.offsetTimeY + style.timeline.heightTime)
        let percent = (pointY - firstY) / (style.timeline.offsetTimeY + style.timeline.heightTime)
        let newMinute = Int(60.0 * percent)
        let newHour = time.tag - 1
        return (newHour, newMinute)
    }
    
    private func moveShadowView(pointX: CGFloat) -> (frame: CGRect, date: Date?)? {
        guard type == .week else { return nil }
        
        let lines = subviews.filter({ $0.tag == tagVerticalLine })
        var width: CGFloat = 200
        if let firstLine = lines[safe: 0], let secondLine = lines[safe: 1] {
            width = secondLine.frame.origin.x - firstLine.frame.origin.x
        }
        guard let line = lines.first(where: { $0.frame.origin.x...($0.frame.origin.x + width) ~= pointX }) as? VerticalLineView else { return nil }
        
        return (CGRect(origin: line.frame.origin, size: CGSize(width: width, height: line.bounds.height)), line.date)
    }
}

extension TimelineView: CalendarSettingProtocol {
    
    var currentStyle: Style {
        style
    }
    
    func setUI() {
        scrollView.backgroundColor = style.timeline.backgroundColor
        scrollView.isScrollEnabled = style.timeline.scrollDirections.contains(.vertical)
        gestureRecognizers?.forEach({ $0.removeTarget(self, action: #selector(addNewEvent)) })
        
        if style.timeline.isEnabledCreateNewEvent {
            // long tap to create a new event preview
            let longTap = UILongPressGestureRecognizer(target: self, action: #selector(addNewEvent))
            longTap.minimumPressDuration = style.timeline.minimumPressDuration
            addGestureRecognizer(longTap)
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size = frame.size
        scrollView.frame.size = frame.size
        currentLineView.reloadFrame(frame)
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        currentLineView.updateStyle(style)
        setUI()
    }
}

extension TimelineView: AllDayEventDelegate {
    
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, frame: frame)
    }
    
}
