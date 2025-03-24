//
//  AllDayEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.05.2021.
//

#if os(iOS)

import UIKit

final class AllDayEventView: UIView {
    
    weak var delegate: AllDayEventDelegate?
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let event: Event
    private var isSelected = false
    // Date the event is positioned at in superview
    var date: Date?

    init(style: AllDayStyle, event: Event, frame: CGRect, date: Date?) {
        self.event = event
        self.date = date
        super.init(frame: frame)
        
        let bgView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: frame.width, height: frame.height - 2)))
        bgView.backgroundColor = UIScreen.isDarkMode ? style.backgroundColor : UIColor.white
        bgView.setRoundCorners(style.eventCorners, radius: style.eventCornersRadius)
        addSubview(bgView)
        
        textLabel.frame = CGRect(origin: .zero, size: frame.size)
        textLabel.setRoundCorners(style.eventCorners, radius: style.eventCornersRadius)
        bgView.addSubview(textLabel)
        
        textLabel.backgroundColor = event.backgroundColor
        textLabel.text = event.title.week
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
        delegate?.didSelectAllDayEvent(event, frame: gesture.view?.frame, date: date)
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

@available(iOS 13.4, *)
extension AllDayEventView: UIPointerInteractionDelegate {
    func addPointInteraction() {
        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .highlight(targetedPreview))
        }
        return pointerStyle
    }
}

#endif
