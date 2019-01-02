//
//  EventPageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class EventPageView: UIView {
    fileprivate let textView: UITextView = {
        let text = UITextView()
        text.backgroundColor = .clear
        text.isScrollEnabled = false
        text.isUserInteractionEnabled = false
        text.textContainer.lineBreakMode = .byTruncatingTail
        text.textContainer.lineFragmentPadding = 0
        return text
    }()
    
    fileprivate let iconFileImageView: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 2, width: 10, height: 10))
        image.image = UIImage(named: "clip")!.withRenderingMode(.alwaysTemplate)
        image.tintColor = .black
        return image
    }()
    
    init(event: Event, style: TimelineStyle, frame: CGRect) {
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
        textView.text = event.text
        tag = "\(event.id)".hashValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Event {
    var id: Any = 0
    var text: String = ""
    var start: Date = Date()
    var end: Date = Date()
    var color: UIColor = .clear
    var isAllDay: Bool = false
    var isContainsFile: Bool = false
    var textForMonth: String = ""
}
