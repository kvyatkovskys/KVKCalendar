//
//  EventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class EventView: EventViewGeneral {
    private let pointX: CGFloat = 5
        
    private(set) var textView: UITextView = {
        let text = UITextView()
        text.backgroundColor = .clear
        text.isScrollEnabled = false
        text.isUserInteractionEnabled = false
        text.textContainer.lineBreakMode = .byTruncatingTail
        text.textContainer.lineFragmentPadding = 0
        return text
    }()
    
    private lazy var iconFileImageView: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 2, width: 10, height: 10))
        image.image = style.event.iconFile?.withRenderingMode(.alwaysTemplate)
        image.tintColor = style.event.colorIconFile
        return image
    }()
    
    init(event: Event, style: Style, frame: CGRect) {
        super.init(style: style, event: event, frame: frame)
        
        var textFrame = frame
        textFrame.origin.x = pointX
        textFrame.origin.y = 0
        
        if event.isContainsFile && textFrame.width > 20 {
            textFrame.size.width = frame.width - iconFileImageView.frame.width - pointX
            iconFileImageView.frame.origin.x = frame.width - iconFileImageView.frame.width - 2
            addSubview(iconFileImageView)
        }
        
        textFrame.size.height = textFrame.height
        textFrame.size.width = textFrame.width - pointX
        textView.frame = textFrame
        textView.font = style.timeline.eventFont
        textView.text = event.text
        
        if isSelected {
            backgroundColor = color
            textView.textColor = UIColor.white
        } else {
            textView.textColor = event.textColor
        }
        
        textView.isHidden = textView.frame.width < 20
        addSubview(textView)
        
        if #available(iOS 13.4, *) {
            addPointInteraction(on: self, delegate: self)
        }
    }
    
    override func tapOnEvent(gesture: UITapGestureRecognizer) {
        guard !isSelected else {
            delegate?.deselectEvent(event)
            deselectEvent()
            return
        }
        
        delegate?.didSelectEvent(event, gesture: gesture)
        
        if style.event.isEnableVisualSelect {
            selectEvent()
        }
    }
    
    func selectEvent() {
        backgroundColor = color
        isSelected = true
        textView.textColor = UIColor.white
        iconFileImageView.tintColor = UIColor.white
    }
    
    func deselectEvent() {
        backgroundColor = event.backgroundColor
        isSelected = false
        textView.textColor = event.textColor
        iconFileImageView.tintColor = style.event.colorIconFile
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.4, *)
extension EventView: PointerInteractionProtocol {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .hover(targetedPreview))
        }
        return pointerStyle
    }
}
