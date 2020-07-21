//
//  EventViewGeneral.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

import UIKit

open class EventViewGeneral: UIView {
    weak var delegate: EventDelegate?
    
    private let event: Event
    private let color: UIColor
    private let style: Style
    
    public init(style: Style, event: Event, frame: CGRect) {
        self.style = style
        self.event = event
        self.color = EventColor(event.color?.value ?? event.backgroundColor).value
        super.init(frame: frame)
        
        setRoundCorners(style.timeline.eventCorners, radius: style.timeline.eventCornersRadius)
        backgroundColor = event.backgroundColor
        tag = event.hash
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
        addGestureRecognizer(tap)
        
        if style.event.isEnableMoveEvent {
            let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateMoveEvent))
            longGesture.minimumPressDuration = style.event.minimumPressDuration
            addGestureRecognizer(longGesture)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func tapOnEvent(gesture: UITapGestureRecognizer) {
        delegate?.didSelectEvent(event, gesture: gesture)
    }
    
    @objc public func activateMoveEvent(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            alpha = style.event.alphaWhileMoving
            delegate?.didStartMoveEvent(event, gesture: gesture)
        case .changed:
            delegate?.didChangeMoveEvent(event, gesture: gesture)
        case .cancelled, .ended, .failed:
            alpha = 1.0
            delegate?.didEndMoveEvent(event, gesture: gesture)
        default:
            break
        }
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.interpolationQuality = .none
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2)
        let x: CGFloat = 1
        let y: CGFloat = 0
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: bounds.height))
        context.strokePath()
        context.restoreGState()
    }
}

protocol EventDelegate: class {
    func didStartMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didEndMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didChangeMoveEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer)
}
