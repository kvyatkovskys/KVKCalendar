//
//  TimelineView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

#if os(iOS)

import UIKit

extension TimelineView {
    
    var calculatedTimeY: CGFloat {
        style.timeline.offsetTimeY * paramaters.scale
    }
    
    var isDisplayedHorizontalLines: Bool {
        style.week.viewMode == .default || paramaters.type == .day
    }
    
    var isDisplayedTimes: Bool {
        isDisplayedHorizontalLines
    }
    
    var isDisplayedCurrentTime: Bool {
        isDisplayedHorizontalLines
    }
    
    var isDisplayedMovingTime: Bool {
        isDisplayedHorizontalLines
    }
    
}

extension TimelineView: UIScrollViewDelegate {
    
    var contentOffset: CGPoint {
        get {
            scrollView.contentOffset
        }
        set {
            scrollView.setContentOffset(newValue, animated: false)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        addStubForInvisibleEvents()
    }
    
    func addStubForInvisibleEvents() {
        guard !style.timeline.isHiddenStubEvent else { return }
        
        let events = scrollView.subviews.compactMap { (view) -> StubEvent? in
            guard let item = view as? EventViewGeneral else { return nil }
            
            return StubEvent(event: item.event, frame: item.frame)
        }
        
        var eventsAllDay: [StubEvent] = []
        if !style.allDay.isPinned && !style.allDay.isHiddenStubEvent {
            eventsAllDay = scrollView.subviews.compactMap { (view) -> [StubEvent]? in
                guard let allDayView = view as? AllDayView else { return nil }
                
                return allDayView.items.flatMap { $0.compactMap { item in StubEvent(event: item.event,
                                                                                    frame: view.frame)} }
            }.flatMap { $0 }
        }
        
        let stubEvents = events + eventsAllDay
        stubEvents.forEach { (eventView) in
            guard let stack = getStubStackView(day: eventView.event.start.kvkDay) else { return }
            
            stack.top.subviews.filter { ($0 as? StubEventView)?.valueHash == eventView.event.hash }.forEach { $0.removeFromSuperview() }
            stack.bottom.subviews.filter { ($0 as? StubEventView)?.valueHash == eventView.event.hash }.forEach { $0.removeFromSuperview() }
            
            // TODO: need fix
            // some recurring events are not displayed in top stack
            guard !visibleView(eventView.frame) else { return }
            
            let stubView = StubEventView(event: eventView.event,
                                         frame: CGRect(x: 0, y: 0,
                                                       width: stack.top.frame.width,
                                                       height: style.event.heightStubView))
            stubView.valueHash = eventView.event.hash
            
            if contentOffset.y > eventView.frame.origin.y {
                stack.top.addArrangedSubview(stubView)
                
                if stack.top.subviews.count >= 1 {
                    switch stack.top.axis {
                    case .vertical:
                        stack.top.frame.size.height = style.event.heightStubView * CGFloat(stack.top.subviews.count)
                    case .horizontal:
                        let newWidth = stack.top.frame.width / CGFloat(stack.top.subviews.count) - 3
                        stack.top.subviews.forEach { $0.frame.size.width = newWidth }
                    @unknown default:
                        fatalError()
                    }
                }
            } else {
                stack.bottom.addArrangedSubview(stubView)
                
                if stack.bottom.subviews.count >= 1 {
                    switch stack.bottom.axis {
                    case .horizontal:
                        let newWidth = stack.bottom.frame.width / CGFloat(stack.bottom.subviews.count) - 3
                        stack.bottom.subviews.forEach { $0.frame.size.width = newWidth }
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
        UIApplication.shared.isAvailableBottomHomeIndicator ? 30 : 5
    }
    
    func topStabStackOffsetY(allDayEventsIsPinned: Bool, height: CGFloat) -> CGFloat {
        allDayEventsIsPinned ? height + 5 : 5
    }
    
    var scrollableEventViews: [UIView] {
        getAllScrollableEvents()
    }
    
}

extension TimelineView {
    
    // to avoid auto scrolling to current time
    private func doNotScrollToCurrentTimeAndRunAction(_ action: @escaping () -> Void) {
        forceDisableScrollToCurrentTime = true
        action()
        forceDisableScrollToCurrentTime = false
    }
    
    private func removeEventResizeView() {
        if let value = eventResizePreview?.haveNewSize, value.needSave, let event = eventResizePreview?.event {
            var startTime: (hour: Int?, minute: Int?)
            var endTime: (hour: Int?, minute: Int?)
            
            if let time = eventResizePreview?.startTime {
                startTime = (time.hour, time.minute)
            } else {
                startTime = (eventResizePreview?.event.start.kvkHour, eventResizePreview?.event.start.kvkMinute)
            }
            
            if let time = eventResizePreview?.endTime {
                endTime = (time.hour, time.minute)
            } else {
                endTime = (eventResizePreview?.event.end.kvkHour, eventResizePreview?.event.end.kvkMinute)
            }
            
            if let startHour = startTime.hour,
               let endHour = endTime.hour,
               let startMinute = startTime.minute,
               let endMinute = endTime.minute
            {
                delegate?.didResizeEvent(event,
                                         startTime: ResizeTime(startHour, startMinute),
                                         endTime: ResizeTime(endHour, endMinute))
            }
        }
        
        eventResizePreview?.removeFromSuperview()
        eventResizePreview = nil
        isResizableEventEnable = false
        enableAllEvents(enable: true)
    }
    
    private func enableAllEvents(enable: Bool) {
        if style.allDay.isPinned {
            subviews.filter { $0.tag == tagAllDayEventView }.forEach { $0.isUserInteractionEnabled = enable }
        } else {
            scrollView.subviews.filter { $0.tag == tagAllDayEventView }.forEach { $0.isUserInteractionEnabled = enable }
        }
        
        scrollView.subviews.filter { $0 is EventViewGeneral }.forEach{ $0.isUserInteractionEnabled = enable }
    }
    
    @objc func pinchZooming(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .ended, .failed, .cancelled:
            gesture.scale = 1
            scrollView.isScrollEnabled = true
        case .changed, .began:
            paramaters.scale *= gesture.scale
            gesture.scale = 1
            scrollView.isScrollEnabled = false
        default:
            break
        }
        
        if let defaultScale = style.timeline.scale {
            if paramaters.scale < defaultScale.min {
                paramaters.scale = defaultScale.min
                return
            } else if paramaters.scale > defaultScale.max {
                paramaters.scale = defaultScale.max
                return
            }
        }
        
        let yPoint = gesture.location(in: scrollView).y
        if let label = potentiallyCenteredLabel, let updatedLabel = timeLabels.first(where: { $0.tag >= label.tag }) {
            potentiallyCenteredLabel = updatedLabel
        } else if let label = timeLabels.first(where: { $0.frame.origin.y >= (yPoint + calculatedTimeY) }) {
            potentiallyCenteredLabel = label
        }
        
        doNotScrollToCurrentTimeAndRunAction { [weak self] in
            self?.reloadTimeline()
        }
        
        let yPointGlobal = gesture.location(in: self).y
        if let y = potentiallyCenteredLabel?.frame.origin.y, gesture.state == .changed {
            let offset = y - yPointGlobal
            scrollView.setContentOffset(.init(x: 0, y: offset), animated: false)
        }
        
        switch gesture.state {
        case .ended, .failed, .cancelled:
            potentiallyCenteredLabel = nil
        default:
            break
        }
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
    
    func reloadTimeline() {
        create(dates: dates, events: events, recurringEvents: recurringEvents, selectedDate: selectedDate)
    }
    
    func deselectEvent(_ event: Event, animated: Bool) {
        guard let eventViewGeneral = scrollView.subviews.first(where: { ($0 as? EventViewGeneral)?.event.ID == event.ID }) as? EventViewGeneral else { return }
        
        guard let eventView = eventViewGeneral as? EventView else {
            deselectEvent?(eventViewGeneral.event)
            return
        }
        
        eventView.deselectEvent()
    }
    
    func createAllDayEvents(events: [AllDayView.PrepareEvents], maxEvents: Int) -> AllDayView? {
        guard !events.allSatisfy({ $0.events.isEmpty }) else { return nil }
        
        var allDayHeight = style.allDay.height
        if 3...4 ~= maxEvents {
            allDayHeight *= 2
        } else if maxEvents > 4 {
            allDayHeight = style.allDay.maxHeight
        } else if maxEvents == 2 && Platform.currentInterface == .phone && paramaters.type == .week {
            allDayHeight *= 2
        }
        let yPoint: CGFloat
        if style.allDay.isPinned {
            yPoint = 0
        } else {
            yPoint = -allDayHeight
        }
        
        let allDayView = AllDayView(parameters: .init(prepareEvents: events,
                                                      type: paramaters.type,
                                                      style: style,
                                                      delegate: delegate),
                                    frame: CGRect(x: 0, y: yPoint, width: bounds.width, height: allDayHeight),
                                    dataSource: dataSource)
        allDayView.tag = tagAllDayEventView
        return allDayView
    }
    
    func getTimelineLabel(hour: Int) -> TimelineLabel? {
        timeLabels.first(where: { $0.hashTime == hour })
    }
    
    func createTimesLabel(start: Int) -> (times: [TimelineLabel], items: [UILabel]) {
        var times = [TimelineLabel]()
        for (idx, txtHour) in timeSystem.hours.enumerated() where idx >= start {
            let yTime = (calculatedTimeY + style.timeline.heightTime) * CGFloat(idx - start)
            let time = TimelineLabel(frame: CGRect(x: style.timeline.offsetTimeX + style.timeline.offsetAdditionalTimeX,
                                                   y: yTime,
                                                   width: style.timeline.widthTime,
                                                   height: style.timeline.heightTime))
            time.font = style.timeline.timeFont
            time.textAlignment = style.timeline.timeAlignment
            time.textColor = style.timeline.timeColor
            time.text = txtHour
            let hourTmp = TimeHourSystem.twentyFour.hours[idx]
            let hour = timeLabelFormatter.date(from: hourTmp)?.kvkHour ?? 0
            time.hashTime = hour
            time.tag = idx - start
            time.isHidden = !isDisplayedTimes
            times.append(time)
            
            if let items = dataSource?.dequeueTimeLabel(hour: hour, frame: time.frame) {
                
            }
        }
        return (times, [])
    }
    
    func createHorizontalLines(times: [TimelineLabel]) -> [UIView] {
        times.enumerated().reduce([]) { acc, item -> [UIView] in
            let time = item.element
            let idx = item.offset
            
            let xLine = time.frame.width + style.timeline.offsetTimeX + style.timeline.offsetLineLeft + style.timeline.offsetAdditionalTimeX
            let lineFrame = CGRect(x: xLine,
                                   y: time.center.y,
                                   width: frame.width - xLine,
                                   height: style.timeline.heightLine)
            let line = UIView(frame: lineFrame)
            line.backgroundColor = style.timeline.separatorLineColor
            line.tag = idx
            line.isHidden = !isDisplayedHorizontalLines
            
            var lines = [line]
            if let dividerType = style.timeline.dividerType {
                let heightBlock = calculatedTimeY + style.timeline.heightTime
                lines += (1..<dividerType.rawValue).compactMap({ idxDivider in
                    let yOffset = heightBlock / CGFloat(dividerType.rawValue) * CGFloat(idxDivider)
                    let divider = DividerView(parameters: .init(style: style),
                                              frame: CGRect(x: 0,
                                                            y: line.frame.origin.y + yOffset - (style.timeline.heightTime / 2),
                                                            width: scrollView.bounds.width,
                                                            height: style.timeline.heightTime))
                    divider.txt = ":\(dividerType.minutes * idxDivider)"
                    return divider
                    
                })
            }
            
            return acc + lines
        }
    }
    
    func createVerticalLine(pointX: CGFloat, date: Date?) -> VerticalLineLayer {
        let frame = CGRect(x: pointX, y: 0, width: style.timeline.widthLine, height: scrollView.contentSize.height)
        
        let line = VerticalLineLayer(date: date,
                                     frame: frame,
                                     tag: tagVerticalLine,
                                     start: CGPoint(x: pointX, y: 0),
                                     end: CGPoint(x: pointX, y: scrollView.contentSize.height),
                                     color: style.timeline.separatorLineColor,
                                     width: style.timeline.widthLine)
        line.isHidden = !style.week.showVerticalDayDivider
        return line
    }
    
    func getEventView(style: Style, event: Event, frame: CGRect, date: Date? = nil) -> EventViewGeneral {
        if let eventView = dataSource?.willDisplayEventView(event, frame: frame, date: date) {
            return eventView
        } else {
            let eventView = EventView(event: event, style: style, frame: frame)
            if #available(iOS 14.0, *), let item = dataSource?.willDisplayEventOptionMenu(event, type: paramaters.type) {
                eventView.addOptionMenu(item.menu, customButton: item.customButton)
            }
            return eventView
        }
    }
    
    @objc func addNewEvent(gesture: UILongPressGestureRecognizer) {
        guard !isResizableEventEnable else { return }
        
        var point = gesture.location(in: scrollView)
        point.y = (point.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = movingMinuteLabel.time
        var newEvent = Event(ID: Event.idForNewEvent)
        newEvent.title = TextEvent(timeline: style.event.textForNewEvent)
        let newEventPreview = getEventView(style: style,
                                           event: newEvent,
                                           frame: CGRect(origin: point, size: eventPreviewSize))
        newEventPreview.stateEvent = .move
        newEventPreview.delegate = self
        newEventPreview.editEvent(gesture: gesture)
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .ended, .failed, .cancelled:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            switch paramaters.type {
            case .day:
                newEvent.start = selectedDate
            case .week:
                newEvent.start = shadowView.date ?? Date()
            default:
                break
            }
            
            newEvent.end = style.calendar.date(byAdding: .minute, value: 15, to: newEvent.start) ?? Date()
            delegate?.didAddNewEvent(newEvent,
                                     minute: time.minute,
                                     hour: time.hour,
                                     point: point)
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
    
    func identityViews(duration: TimeInterval = 0.3,
                       delay: TimeInterval = 0.1,
                       _ views: [UIView],
                       action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.8,
                       options: .curveLinear,
                       animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        })
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
        eventPreviewSize.width * 0.5
    }
    
    var eventPreviewYOffset: CGFloat {
        eventPreviewSize.height * 0.7
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
        isResizableEventEnable = true
        
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                                     frame: CGRect(origin: CGPoint(x: location.x - eventPreviewXOffset,
                                                                   y: location.y - eventPreviewYOffset),
                                                   size: eventPreviewSize))
        } else {
            eventPreview = event.isNew ? view : view.snapshotView(afterScreenUpdates: false)
            if let size = eventPreview?.frame.size {
                eventPreviewSize = size
            }
            eventPreview?.frame.origin = CGPoint(x: location.x - eventPreviewXOffset,
                                                 y: location.y - eventPreviewYOffset)
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
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func didEndMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        movingMinuteLabel.removeFromSuperview()
        
        var location = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft + style.timeline.offsetAdditionalTimeX
        guard scrollView.frame.width >= (location.x + 30), (location.x - 10) >= leftOffset else { return }
        
        location.y = (location.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let startTime = movingMinuteLabel.time
        if !event.isNew {
            var newDayEvent: Int?
            var updatedEvent = event
            
            if paramaters.type == .week, let newDate = shadowView.date {
                newDayEvent = newDate.kvkDay
                
                if event.recurringType != .none {
                    updatedEvent = event.updateDate(newDate: newDate, calendar: style.calendar) ?? event
                }
            }
            delegate?.didChangeEvent(updatedEvent,
                                     minute: startTime.minute,
                                     hour: startTime.hour,
                                     point: location,
                                     newDay: newDayEvent)
        }
        
        shadowView.removeFromSuperview()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func didChangeMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft + style.timeline.offsetAdditionalTimeX
        guard scrollView.frame.width >= (location.x + 20), (location.x - 20) >= leftOffset else { return }
        
        var offset = contentOffset
        if (location.y - 80) < scrollView.contentOffset.y, (location.y - eventPreviewSize.height) >= 0 {
            // scroll up
            offset.y -= 5
            contentOffset = offset
        } else if (location.y + 80) > (contentOffset.y + scrollView.bounds.height), location.y + eventPreviewSize.height <= scrollView.contentSize.height {
            // scroll down
            offset.y += 5
            contentOffset = offset
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
        
        if let minute = time.minute, 0...59 ~= minute {
            movingMinuteLabel.frame = CGRect(x: style.timeline.offsetTimeX + style.timeline.offsetAdditionalTimeX,
                                             y: (pointY - offset) - style.timeline.heightTime,
                                             width: style.timeline.widthTime, height: style.timeline.heightTime)
            scrollView.addSubview(movingMinuteLabel)
            let roundedMinute = minute.roundToNearest(style.timeline.minuteLabelRoundUpTime)
            movingMinuteLabel.time = TimeContainer(minute: roundedMinute, hour: time.hour ?? 0)
        } else {
            movingMinuteLabel.time.minute = 0
        }
    }
    
    private func calculateChangingTime(pointY: CGFloat) -> (hour: Int?, minute: Int?) {
        guard let time = timeLabels.first(where: { $0.frame.origin.y >= pointY }) else { return (nil, nil) }
        
        let firstY = time.frame.origin.y - (calculatedTimeY + style.timeline.heightTime)
        let percent = (pointY - firstY) / (calculatedTimeY + style.timeline.heightTime)
        let newMinute = Int(60.0 * percent)
        let newHour = time.tag - 1
        return (newHour, newMinute)
    }
    
    private func moveShadowView(pointX: CGFloat) -> (frame: CGRect, date: Date?)? {
        guard paramaters.type == .week else { return nil }
        
        let lines = layer.sublayers?.filter { $0.name == "\(tagVerticalLine)" } as? [VerticalLineLayer] ?? []
        var width: CGFloat = 200
        if let firstLine = lines[safe: 0], let secondLine = lines[safe: 1] {
            width = secondLine.lineFrame.origin.x - firstLine.lineFrame.origin.x
        }
        guard let line = lines.first(where: { $0.lineFrame.origin.x...($0.lineFrame.origin.x + width) ~= pointX }) else { return nil }
        
        return (CGRect(origin: line.lineFrame.origin,
                       size: CGSize(width: width, height: scrollView.contentSize.height)),
                line.date)
    }
}

extension TimelineView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            paramaters.style
        }
        set {
            paramaters.style = newValue
        }
    }
    
    func setUI(reload: Bool = false) {
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
        setupConstraints()
        currentLineView.reloadFrame(frame)
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        currentLineView.updateStyle(style, force: force)
        setUI(reload: force)
    }
    
    func removeConstraints() {
        NSLayoutConstraint.deactivate(scrollView.constraints)
    }
    
    func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let top = scrollView.topAnchor.constraint(equalTo: topAnchor)
        let left = scrollView.leftAnchor.constraint(equalTo: leftAnchor)
        let right = scrollView.rightAnchor.constraint(equalTo: rightAnchor)
        let bottom = scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([top, left, right, bottom])
    }
}

extension TimelineView: AllDayEventDelegate {
    
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, frame: frame)
    }
    
}

extension Int {
    /// SwifterSwift: Rounds to the closest multiple of n.
    func roundToNearest(_ number: Int) -> Int {
        number == 0 ? self : Int(round(Double(self) / Double(number))) * number
    }
}

#endif
