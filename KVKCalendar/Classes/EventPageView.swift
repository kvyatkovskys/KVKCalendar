//
//  EventPageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

fileprivate let pointX: CGFloat = 5

final class EventPageView: UIView {
    fileprivate let style: TimelineStyle
    fileprivate let color: UIColor
    
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
        self.color = event.color ?? event.backgroundColor
        super.init(frame: frame)
        backgroundColor = event.backgroundColor
        
        var textFrame = frame
        textFrame.origin.x = pointX
        textFrame.origin.y = 0
        
        if event.isContainsFile {
            textFrame.size.width = frame.width - iconFileImageView.frame.width - pointX
            iconFileImageView.frame.origin.x = frame.width - iconFileImageView.frame.width - pointX
            addSubview(iconFileImageView)
        }
        
        textFrame.size.height = textFrame.height
        textFrame.size.width = textFrame.width - pointX
        textView.frame = textFrame
        addSubview(textView)
        textView.font = style.eventFont
        textView.textColor = event.colorText
        textView.text = event.text
        tag = "\(event.id)".hashValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
