//
//  EventViewGeneral.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

import UIKit

open class EventViewGeneral: UIView, CalendarTimer {
    
    public enum EventViewMode: Int {
        case resize, move, none
    }
    
    weak var delegate: EventDelegate?
    weak var dataSource: EventDataSource?
    
    public var event: Event
    public var color: UIColor
    public var style: Style
    public var isSelected: Bool = false
    public var mode: EventViewMode = .none
    
    public lazy var longGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(editEvent))
        gesture.minimumPressDuration = style.event.minimumPressDuration
        return gesture
    }()
    
    public init(style: Style, event: Event, frame: CGRect) {
        self.style = style
        self.event = event
        self.color = EventColor(event.color?.value ?? event.backgroundColor).value
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        let event = Event(ID: "0")
        self.event = event
        self.style = Style()
        self.color = event.backgroundColor
        super.init(coder: coder)
    }
    
    public func setup() {
        setRoundCorners(style.event.eventCorners, radius: style.event.eventCornersRadius)
        backgroundColor = event.backgroundColor
        tag = event.hash
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
        addGestureRecognizer(tap)
        
        if style.event.isEnableMoveEvent {
            addGestureRecognizer(longGesture)
        }
    }
    
    @objc public func tapOnEvent(gesture: UITapGestureRecognizer) {
        delegate?.didSelectEvent(event, gesture: gesture)
    }
    
    @available(swift, deprecated: 0.3.8, obsoleted: 0.3.9, renamed: "editEvent")
    @objc public func activateMoveEvent(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            alpha = style.event.alphaWhileMoving
            delegate?.didStartMovingEvent(event, gesture: gesture, view: self)
        case .changed:
            delegate?.didChangeMovingEvent(event, gesture: gesture)
        case .cancelled, .ended, .failed:
            alpha = 1.0
            delegate?.didEndMovingEvent(event, gesture: gesture)
        default:
            break
        }
    }
    
    @objc public func editEvent(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            switch mode {
            case .none:
                mode = .resize
                
                startTimer(interval: 3) { [weak self] in
                    guard let self = self else { return }
                    
                    self.mode = .move
                    self.delegate?.didEndResizeEvent(self.event, gesture: gesture)
                    self.alpha = self.style.event.alphaWhileMoving
                    self.delegate?.didStartMovingEvent(self.event, gesture: gesture, view: self)
                }
                delegate?.didStartResizeEvent(event, gesture: gesture, view: self)
            case .resize, .move:
                alpha = style.event.alphaWhileMoving
                delegate?.didStartMovingEvent(event, gesture: gesture, view: self)
            }
        case .changed:
            stopTimer()

            switch mode {
            case .resize:
                mode = .move
                delegate?.didEndResizeEvent(event, gesture: gesture)
                alpha = style.event.alphaWhileMoving
                delegate?.didStartMovingEvent(event, gesture: gesture, view: self)
            default:
                break
            }

            delegate?.didChangeMovingEvent(event, gesture: gesture)
        case .cancelled, .ended, .failed:
            switch mode {
            case .move:
                alpha = 1.0
                delegate?.didEndMovingEvent(event, gesture: gesture)
            default:
                stopTimer()
            }
            mode = .none
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

@available(iOS 13, *)
extension EventViewGeneral: UIContextMenuInteractionDelegate {
    var interaction: UIContextMenuInteraction {
        return UIContextMenuInteraction(delegate: self)
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return dataSource?.willDisplayContextMenu(event, date: event.start)
    }
}

protocol EventDelegate: class {
    func didStartResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView)
    func didEndResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didStartMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView)
    func didEndMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didChangeMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer)
    func deselectEvent(_ event: Event)
}

protocol EventDataSource: class {
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration?
}

extension EventDataSource {
    @available(iOS 13.0, *)
    func willDisplayContextMenu(_ event: Event, date: Date?) -> UIContextMenuConfiguration? { return nil }
}
