//
//  EventViewGeneral.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2020.
//

#if os(iOS)

import UIKit

open class EventViewGeneral: UIView, CalendarTimer {
    
    public enum EventViewState: Int {
        case resize, move, none
    }
    
    weak var delegate: EventDelegate?
    
    private var originalLocation: CGPoint = .zero
    private let states: Set<EventViewState>
    
    public var event: Event
    public var color: UIColor
    public var style: Style
    public var isSelected: Bool = false
    public var stateEvent: EventViewState = .none
    
    public lazy var longGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(editEvent))
        gesture.minimumPressDuration = style.event.minimumPressDuration
        return gesture
    }()
    
    public let optionButton: UIButton = {
        let button = UIButton(type: .infoLight)
        if #available(iOS 14.0, macCatalyst 14.0, *) {
            button.showsMenuAsPrimaryAction = true
        }
        return button
    }()
    
    public init(style: Style, event: Event, frame: CGRect) {
        self.style = style
        self.event = event
        self.color = event.color?.value ?? event.backgroundColor
        self.states = style.event.states
        super.init(frame: frame)
        
        stateEvent = isAvailableOnlyMove ? .move : .none
        setup()
    }
    
    required public init?(coder: NSCoder) {
        let event = Event(ID: "0")
        self.event = event
        self.style = Style()
        self.color = event.backgroundColor
        self.states = style.event.states
        super.init(coder: coder)
        
        stateEvent = isAvailableOnlyMove ? .move : .none
        setup()
    }
    
    public func setup() {
        setRoundCorners(style.event.eventCorners, radius: style.event.eventCornersRadius)
        backgroundColor = event.backgroundColor
        tag = event.hash
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
        addGestureRecognizer(tap)
        
        if isAvailableResize || isAvailableMove {
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
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            switch stateEvent {
            case .none:
                guard isAvailableResize else { return }
                
                originalLocation = location
                stateEvent = .resize
                
                if isAvailableMove {
                    startTimer(interval: 1.5) { [weak self] in
                        guard let self = self else { return }
                        
                        self.stateEvent = .move
                        self.delegate?.didEndResizeEvent(self.event, gesture: gesture)
                        self.alpha = self.style.event.alphaWhileMoving
                        self.delegate?.didStartMovingEvent(self.event, gesture: gesture, view: self)
                    }
                }
                
                delegate?.didStartResizeEvent(event, gesture: gesture, view: self)
            case .move:
                guard isAvailableMove else { return }
                
                stateEvent = .move
                alpha = style.event.alphaWhileMoving
                delegate?.didStartMovingEvent(event, gesture: gesture, view: self)
            case .resize:
                break
            }
        case .changed:
            guard isAvailableMove else { return }
            
            // set delay before start moving event
            let distance = hypotf(Float((originalLocation.x - location.x)), Float((originalLocation.y - location.y)))
            switch stateEvent {
            case .resize where distance > 15 && isAvailableResize:
                stopTimer()
                stateEvent = .move
                delegate?.didEndResizeEvent(event, gesture: gesture)                
                alpha = style.event.alphaWhileMoving
                delegate?.didStartMovingEvent(event, gesture: gesture, view: self)
            case .move:
                delegate?.didChangeMovingEvent(event, gesture: gesture)
            default:
                break
            }
        case .cancelled, .ended, .failed:
            if gesture.state == .failed {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
            switch stateEvent {
            case .move:
                alpha = 1.0
                delegate?.didEndMovingEvent(event, gesture: gesture)
            default:
                stopTimer()
            }
            stateEvent = .none
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

extension EventViewGeneral {
    var isAvailableResize: Bool {
        return states.contains(.resize)
    }
    
    var isAvailableMove: Bool {
        return states.contains(.move)
    }
    
    var isAvailableOnlyMove: Bool {
        return states.contains(.move) && states.count == 1
    }
}

protocol EventDelegate: AnyObject {
    
    func didStartResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView)
    func didEndResizeEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didStartMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer, view: UIView)
    func didEndMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didChangeMovingEvent(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer)
    func deselectEvent(_ event: Event)
    
}

#endif
