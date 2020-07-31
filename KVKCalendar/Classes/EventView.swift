//
//  EventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class EventView: EventViewGeneral {
    private let pointX: CGFloat = 5
        
    private let textView: UITextView = {
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
        image.image = style.timeline.iconFile?.withRenderingMode(.alwaysTemplate)
        image.tintColor = style.timeline.colorIconFile
        return image
    }()
    
    init(event: Event, style: Style, frame: CGRect) {
        super.init(style: style, event: event, frame: frame)
        
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
        textView.textColor = event.textColor
        textView.text = event.text
        
        if textView.frame.width > 20 {
            addSubview(textView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
