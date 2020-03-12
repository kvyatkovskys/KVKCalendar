//
//  EventPageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let pointX: CGFloat = 5

final class EventPageView: UIView {
    weak var delegate: EventPageDelegate?
    let event: Event
    private let timelineStyle: TimelineStyle
    private let color: UIColor
    
    private let textView: UITextView = {
        let text = UITextView()
        text.backgroundColor = .clear
        text.isScrollEnabled = false
        text.isUserInteractionEnabled = false
        text.textContainer.lineBreakMode = .byTruncatingTail
        text.textContainer.lineFragmentPadding = 0
        text.layoutManager.allowsNonContiguousLayout = true
        return text
    }()
    
    private lazy var iconFileImageView: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 2, width: 10, height: 10))
        image.image = timelineStyle.iconFile?.withRenderingMode(.alwaysTemplate)
        image.tintColor = timelineStyle.colorIconFile
        return image
    }()
    
    init(event: Event, style: Style, frame: CGRect) {
        self.event = event
        self.timelineStyle = style.timeline
        self.color = EventColor(event.color?.value ?? event.backgroundColor).value
        super.init(frame: frame)
        backgroundColor = event.backgroundColor
        
        var textFrame = frame
        textFrame.origin.x = pointX
        textFrame.origin.y = 0
        
        if event.isContainsFile {
            textFrame.size.width = frame.width - iconFileImageView.frame.width - pointX
            iconFileImageView.frame.origin.x = frame.width - iconFileImageView.frame.width - 2
            addSubview(iconFileImageView)
        }
        
        textFrame.size.height = textFrame.height
        textFrame.size.width = textFrame.width - pointX
        textView.frame = textFrame
        textView.font = style.timeline.eventFont
        textView.textColor = event.colorText
        textView.text = event.text
        
        if textView.frame.width > 20 {
            addSubview(textView)
        }
        tag = "\(event.id)".hashValue
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
        addGestureRecognizer(tap)
        
        if style.event.isEnableMoveEvent {
            let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateMoveEvent))
            longGesture.minimumPressDuration = style.event.minimumPressDuration
            addGestureRecognizer(longGesture)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapOnEvent(gesture: UITapGestureRecognizer) {
        delegate?.didSelectEvent(event, gesture: gesture)
    }
    
    @objc private func activateMoveEvent(gesture: UILongPressGestureRecognizer) {        
        switch gesture.state {
        case .began:
            delegate?.didStartMoveEventPage(self, gesture: gesture)
        case .changed:
            delegate?.didChangeMoveEventPage(self, gesture: gesture)
        case .cancelled, .ended, .failed:
            delegate?.didEndMoveEventPage(self, gesture: gesture)
        default:
            break
        }
    }
    
    override func draw(_ rect: CGRect) {
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

protocol EventPageDelegate: class {
    func didStartMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer)
    func didEndMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer)
    func didChangeMoveEventPage(_ eventPage: EventPageView, gesture: UILongPressGestureRecognizer)
    func didSelectEvent(_ event: Event, gesture: UITapGestureRecognizer)
}
