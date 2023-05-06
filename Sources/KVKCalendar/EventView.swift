//
//  EventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct EventNewView: View {
    
    var isSelected: Bool
    var event: Event
    var style: Style
    var didSelect: (() -> Void)?
    
    private var bgColor: Color {
        Color(uiColor: isSelected ? (event.color?.value ?? .blue) : event.backgroundColor)
    }
    private var tintColor: Color {
        Color(uiColor: isSelected ? .white : event.textColor)
    }
    
    var body: some View {
        Button {
            didSelect?()
        } label: {
            HStack(spacing: 3) {
                Rectangle()
                    .fill(Color(uiColor: event.color?.value ?? .blue))
                    .frame(minWidth: 3, maxWidth: 3, maxHeight: .infinity)
                VStack {
                    Text(event.title.timeline)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.7)
                    Spacer()
                }
                .tint(tintColor)
                .padding(.vertical, 5)
                Spacer()
            }
            .background(bgColor)
            .cornerRadius(style.event.eventCornersRadius.width)
        }
    }
    
}

@available(iOS 16.0, *)
struct EventNewView_Previews: PreviewProvider {
    
    static var previews: some View {
        EventNewView(isSelected: false, event: .stub(), style: Style())
            .padding()
    }
    
}

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
        textView.textContainerInset = style.event.textContainerInset
        textView.frame = textFrame
        textView.font = style.timeline.eventFont
        textView.text = event.title.timeline
        
        if isSelected {
            backgroundColor = color
            textView.textColor = UIColor.white
        } else {
            textView.textColor = event.textColor
        }
        
        textView.isHidden = textView.frame.width < 20
        addSubview(textView)
        
        if #available(iOS 13.4, *) {
            addPointInteraction()
        }
    }
    
    @available(iOS 14.0, macCatalyst 14.0, *)
    func addOptionMenu(_ menu: UIMenu, customButton: UIButton?) {
        let button: UIButton
        if let item = customButton {
            button = item
        } else {
            button = optionButton
            button.frame = CGRect(x: frame.width - 27, y: 2, width: 23, height: 23)
        }
        
        guard bounds.height > button.bounds.height && bounds.width > button.bounds.width else { return }
        
        textView.frame.size.width -= button.bounds.width + 5
    
        if iconFileImageView.superview != nil {
            if bounds.height > (button.bounds.height + iconFileImageView.bounds.height + 5) {
                iconFileImageView.frame.origin.y += button.bounds.height + 5
                iconFileImageView.isHidden = false
            } else {
                iconFileImageView.isHidden = true
            }
        }
        
        button.menu = menu
        addPointInteraction()
        addSubview(button)
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

#endif
