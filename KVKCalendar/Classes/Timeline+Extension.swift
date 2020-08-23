//
//  TimelineView+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

import Foundation

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
    
    func didStartMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView) {
        let point = gesture.location(in: scrollView)
        
        shadowView.removeFromSuperview()
        if let frame = moveShadowView(pointX: point.x) {
            shadowView.frame = frame
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
            showChangeMinutes(pointY: point.y)
            UIView.animate(withDuration: 0.3) {
                self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            UIImpactFeedbackGenerator().impactOccurred()
        }
    }
    
    func didEndMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
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
            point.x -= eventPreviewXOffset
            delegate?.didChangeEvent(event, minute: minute, hour: hour, point: point)
        }
    }
    
    func didChangeMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer) {
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
    
    func calculateChangeTime(pointY: CGFloat) -> (hour: Int?, minute: Int?) {
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
        scrollView.contentSize.width = frame.width
        currentLineView.frame.size.width = frame.width
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
