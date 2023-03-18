//
//  AllDayEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.05.2021.
//

#if os(iOS)

import UIKit
import SwiftUI

@available(iOS 15.0, *)
struct AllDayEventNewView: View {
    
    let event: Event
    let style: AllDayStyle
    
    var body: some View {
        HStack {
            Text(event.title.timeline)
                .foregroundColor(Color(uiColor: event.textColor))
                .font(Font(style.fontTitle))
                .padding(5)
            Spacer()
        }
        .background(Color(uiColor: event.backgroundColor))
        .cornerRadius(style.eventCornersRadius.width)
        .hoverEffect(.automatic)
    }
    
}

@available(iOS 15.0, *)
struct AllDayEventNewView_Preview: PreviewProvider {
    static var previews: some View {
        AllDayEventNewView(event: Event.stub(),
                           style: AllDayStyle())
    }
}

final class AllDayEventView: UIView {
    
    weak var delegate: AllDayEventDelegate?
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let event: Event
    private var isSelected = false
    
    init(style: AllDayStyle, event: Event, frame: CGRect) {
        self.event = event
        super.init(frame: frame)
        
        let bgView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: frame.width, height: frame.height - 2)))
        bgView.backgroundColor = UIScreen.isDarkMode ? style.backgroundColor : UIColor.white
        bgView.setRoundCorners(style.eventCorners, radius: style.eventCornersRadius)
        addSubview(bgView)
        
        textLabel.frame = CGRect(origin: .zero, size: frame.size)
        textLabel.setRoundCorners(style.eventCorners, radius: style.eventCornersRadius)
        bgView.addSubview(textLabel)
        
        textLabel.backgroundColor = event.backgroundColor
        textLabel.text = event.title.timeline
        textLabel.textColor = event.textColor
        textLabel.font = style.fontTitle
        
        tag = event.hash
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnEvent))
        addGestureRecognizer(tap)
        
        if #available(iOS 13.4, *) {
            addPointInteraction()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func tapOnEvent(gesture: UITapGestureRecognizer) {
        delegate?.didSelectAllDayEvent(event, frame: gesture.view?.frame)
    }
    
    func selectEvent() {
        textLabel.backgroundColor = event.color?.value ?? event.backgroundColor
        isSelected = true
        textLabel.textColor = UIColor.white
    }
    
    func deselectEvent() {
        textLabel.backgroundColor = event.backgroundColor
        isSelected = false
        textLabel.textColor = event.textColor
    }
}

#endif
