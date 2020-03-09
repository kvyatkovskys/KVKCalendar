//
//  AllDayEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class AllDayTitleView: UIView {
    init(frame: CGRect, style: AllDayStyle) {
        super.init(frame: frame)
        backgroundColor = style.backgroundColor
        
        let label = UILabel(frame: frame)
        label.frame.size.width = frame.width - 4
        label.frame.origin.x = 2
        label.frame.origin.y = 0
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = style.fontTitle
        label.textColor = style.titleColor
        label.text = style.titleText
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol AllDayEventDelegate: AnyObject {
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?)
}

final class AllDayEventView: UIView {
    private let events: [Event]
    weak var delegate: AllDayEventDelegate?
    
    init(events: [Event], frame: CGRect, style: AllDayStyle, date: Date?) {
        self.events = events
        super.init(frame: frame)
        backgroundColor = style.backgroundColor
        
        let startEvents = events.map({ AllDayEvent(id: $0.id, text: $0.text, date: $0.start, color: EventColor($0.color?.value ?? $0.backgroundColor).value) })
        let endEvents = events.map({ AllDayEvent(id: $0.id, text: $0.text, date: $0.end, color: EventColor($0.color?.value ?? $0.backgroundColor).value) })
        let result = startEvents + endEvents
        let distinct = result.reduce([]) { (acc, event) -> [AllDayEvent] in
            guard acc.contains(where: { $0.date.day == event.date.day && "\($0.id)".hashValue == "\(event.id)".hashValue }) else {
                return acc + [event]
            }
            return acc
        }
        let filtered = distinct.filter({ $0.date.day == date?.day })
        
        let eventWidth = frame.width / CGFloat(filtered.count)
        for (idx, event) in filtered.enumerated() {
            let label = UILabel(frame: CGRect(x: (CGFloat(idx) * eventWidth) + style.offset,
                                              y: style.offset,
                                              width: eventWidth - (style.offset * 2),
                                              height: frame.height - (style.offset * 2)))
            label.textColor = style.textColor
            label.isUserInteractionEnabled = true
            label.font = style.font
            label.text = " \(event.text)"
            label.backgroundColor = event.color.withAlphaComponent(0.8)
            label.tag = "\(event.id)".hashValue
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
            label.addGestureRecognizer(tap)
            addSubview(label)
        }
    }
    
    @objc private func tapOnEvent(gesture: UITapGestureRecognizer) {
        guard let hashValue = gesture.view?.tag else { return }
        if let idx = events.firstIndex(where: { "\($0.id)".hashValue == hashValue }) {
            let event = events[idx]
            delegate?.didSelectAllDayEvent(event, frame: gesture.view?.frame)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct AllDayEvent {
    let id: Any
    let text: String
    let date: Date
    let color: UIColor
}

extension AllDayEvent: EventProtocol {
    func compare(_ event: Event) -> Bool {
        return "\(id)".hashValue == "\(event)".hashValue
    }
}
