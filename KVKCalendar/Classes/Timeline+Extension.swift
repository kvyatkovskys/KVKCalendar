//
//  TimelineView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

import Foundation

extension TimelineView {
    func createAllDayEvents(events: [Event], date: Date?, width: CGFloat, originX: CGFloat) {
        guard !events.isEmpty else { return }
        let pointY = style.allDay.isPinned ? 0 : -style.allDay.height
        let allDayEvent = AllDayEventView(events: events,
                                          frame: CGRect(x: originX, y: pointY, width: width, height: style.allDay.height),
                                          style: style.allDay,
                                          date: date)
        allDayEvent.tag = tagAllDayEvent
        allDayEvent.delegate = self
        if style.allDay.isPinned {
            addSubview(allDayEvent)
        } else {
            scrollView.addSubview(allDayEvent)
        }
        
        let allDayPlaceholder = AllDayTitleView(frame: CGRect(x: 0,
                                                              y: pointY,
                                                              width: style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft,
                                                              height: style.allDay.height),
                                                style: style.allDay)
        allDayPlaceholder.tag = tagAllDayPlaceholder
        if style.allDay.isPinned {
            addSubview(allDayPlaceholder)
        } else {
            scrollView.addSubview(allDayPlaceholder)
        }
    }
    
    func createTimesLabel(start: Int) -> [TimelineLabel] {
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
    
    func createLines(times: [TimelineLabel]) -> [UIView] {
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
    
    func createVerticalLine(pointX: CGFloat, date: Date?) -> VerticalLineView {
        let frame = CGRect(x: pointX, y: 0, width: style.timeline.widthLine, height: (CGFloat(25) * (style.timeline.heightTime + style.timeline.offsetTimeY)) - 75)
        let line = VerticalLineView(frame: frame)
        line.tag = tagVerticalLine
        line.backgroundColor = .systemGray
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
        var point = gesture.location(in: scrollView)
        point.y = (point.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangingTime(pointY: point.y)
        var newEvent = Event(ID: Event.idForNewEvent, text: style.event.textForNewEvent)
        let newEventPreview = getEventView(style: style, event: newEvent, frame: CGRect(origin: point, size: .zero))
        newEventPreview.delegate = self
        newEventPreview.activateMoveEvent(gesture: gesture)
        
        switch gesture.state {
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
    
    @objc func swipeEvent(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let endGesure = abs(translation.x) > (frame.width / 3.5)
        let events = scrollView.subviews.filter({ $0 is EventViewGeneral })
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
    
    func identityViews(duration: TimeInterval = 0.4, delay: TimeInterval = 0.07, _ views: [UIView], action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        }, completion: nil)
    }
}

extension TimelineView: EventDataSource {
    @available(iOS 13, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? {
        return dataSource?.willDisplayContextMenu(event, date: date)
    }
}

extension TimelineView: EventDelegate {
    var eventPreviewXOffset: CGFloat {
        return eventPreviewSize.width * 0.5
    }
    
    var eventPreviewYOffset: CGFloat {
        return eventPreviewSize.height * 0.7
    }
    
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer) {
        delegate?.didSelectEvent(event, frame: gesture.view?.frame)
    }
    
    func didStartMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView) {
        let point = gesture.location(in: scrollView)
        
        shadowView.removeFromSuperview()
        if let value = moveShadowView(pointX: point.x) {
            shadowView.frame = value.frame
            shadowView.date = value.date
            scrollView.addSubview(shadowView)
        }
    
        eventPreview = nil
        
        if view is EventView {
            eventPreviewSize = CGSize(width: 100, height: 100)
            eventPreview = EventView(event: event,
                                     style: style,
                                     frame: CGRect(origin: CGPoint(x: point.x - eventPreviewXOffset, y: point.y - eventPreviewYOffset),
                                                   size: eventPreviewSize))
        } else {
            eventPreview = view.snapshotView(afterScreenUpdates: false)
            if let size = eventPreview?.frame.size {
                eventPreviewSize = size
            }
            eventPreview?.frame.origin = CGPoint(x: point.x - eventPreviewXOffset, y: point.y - eventPreviewYOffset)
        }
        
        eventPreview?.alpha = 0.9
        eventPreview?.tag = tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if let eventTemp = eventPreview {
            scrollView.addSubview(eventTemp)
            showChangingMinutes(pointY: point.y)
            UIView.animate(withDuration: 0.3) {
                self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            UIImpactFeedbackGenerator().impactOccurred()
        }
    }
    
    func didEndMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        movingMinutesLabel.removeFromSuperview()
        
        var point = gesture.location(in: scrollView)
        let leftOffset = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        guard scrollView.frame.width >= (point.x + 30), (point.x - 10) >= leftOffset else { return }
        
        point.y = (point.y - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangingTime(pointY: point.y)
        if let minute = time.minute, let hour = time.hour, !event.isNew {
            var newDayEvent: Int?
            if type == .week, let newDay = shadowView.date?.day {
                newDayEvent = newDay
            }
            delegate?.didChangeEvent(event, minute: minute, hour: hour, point: point, newDay: newDayEvent)
        }
        
        shadowView.removeFromSuperview()
    }
    
    func didChangeMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
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
        showChangingMinutes(pointY: point.y)
        
        if let value = moveShadowView(pointX: point.x) {
            shadowView.frame = value.frame
            shadowView.date = value.date
        }
    }
    
    private func showChangingMinutes(pointY: CGFloat) {
        movingMinutesLabel.removeFromSuperview()
        
        let pointTempY = (pointY - eventPreviewYOffset) - style.timeline.offsetEvent - 6
        let time = calculateChangingTime(pointY: pointTempY)
        if style.timeline.offsetTimeY > 50, let minute = time.minute, 0...59 ~= minute {
            let offset = eventPreviewYOffset - style.timeline.offsetEvent - 6
            movingMinutesLabel.frame =  CGRect(x: style.timeline.offsetTimeX, y: (pointY - offset) - style.timeline.heightTime,
                                               width: style.timeline.widthTime, height: style.timeline.heightTime)
            scrollView.addSubview(movingMinutesLabel)
            movingMinutesLabel.text = ":\(minute)"
        }
    }
    
    func calculateChangingTime(pointY: CGFloat) -> (hour: Int?, minute: Int?) {
        let times = scrollView.subviews.filter({ ($0 is TimelineLabel) }).compactMap({ $0 as? TimelineLabel })
        guard let time = times.first( where: { $0.frame.origin.y >= pointY }) else { return (nil, nil) }

        let firstY = time.frame.origin.y - (style.timeline.offsetTimeY + style.timeline.heightTime)
        let percent = (pointY - firstY) / (style.timeline.offsetTimeY + style.timeline.heightTime)
        let newMinute = Int(60.0 * percent)
        return (time.tag - 1, newMinute)
    }
    
    private func moveShadowView(pointX: CGFloat) -> (frame: CGRect, date: Date?)? {
        guard type == .week else { return nil }
        
        let lines = scrollView.subviews.filter({ $0.tag == tagVerticalLine })
        var width: CGFloat = 200
        if let firstLine = lines[safe: 0], let secondLine = lines[safe: 1] {
            width = secondLine.frame.origin.x - firstLine.frame.origin.x
        }
        guard let line = lines.first(where: { $0.frame.origin.x...($0.frame.origin.x + width) ~= pointX }) as? VerticalLineView else { return nil }
        
        return (CGRect(origin: line.frame.origin, size: CGSize(width: width, height: line.bounds.height)), line.date)
    }
}

extension TimelineView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size = frame.size
        scrollView.frame.size = frame.size
        scrollView.contentSize.width = frame.width
        currentLineView.reloadFrame(frame)
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
