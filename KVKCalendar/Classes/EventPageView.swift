//
//  EventPageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class EventPageView: UIView {
    fileprivate let style: TimelineStyle
    
    fileprivate let textView: UITextView = {
        let text = UITextView()
        text.backgroundColor = .clear
        text.isScrollEnabled = false
        text.isUserInteractionEnabled = false
        text.textContainer.lineBreakMode = .byTruncatingTail
        text.textContainer.lineFragmentPadding = 0
        return text
    }()
    
    fileprivate lazy var iconFileImageView: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 2, width: 10, height: 10))
        image.image = style.iconFile.withRenderingMode(.alwaysTemplate)
        image.tintColor = style.colorIconFile
        return image
    }()
    
    init(event: Event, style: TimelineStyle, frame: CGRect) {
        self.style = style
        super.init(frame: frame)
        backgroundColor = event.color
        
        var textFrame = frame
        textFrame.origin.x = 2
        textFrame.origin.y = 0
        
        if event.isContainsFile {
            textFrame.size.width = frame.width - iconFileImageView.frame.width - 2
            iconFileImageView.frame.origin.x = frame.width - iconFileImageView.frame.width - 2
            addSubview(iconFileImageView)
        }
        
        textFrame.size.height = textFrame.height
        textFrame.size.width = textFrame.width - 2
        textView.frame = textFrame
        addSubview(textView)
        textView.textColor = event.colorText
        textView.text = event.text
        tag = "\(event.id)".hashValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
