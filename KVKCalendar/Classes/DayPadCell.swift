//
//  DayPadCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01.10.2020.
//

import UIKit

final class DayPadCell: DayCell {
    var padStyle: Style? {
        didSet {
            guard let newStyle = padStyle else { return }
            
            style = newStyle
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.frame.size.width = (frame.width * 0.5) - 5
            } else {
                titleLabel.frame.size.width = (frame.width * 0.5)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textAlignment = .right
        dateLabel.textAlignment = .center
        
        var titleFrame = frame
        titleFrame.origin.x = 0
        titleFrame.origin.y = 0
        titleFrame.size.width = (frame.width * 0.5)
        titleLabel.frame = titleFrame
        
        var dateFrame = frame
        dateFrame.size.width = heightDate
        dateFrame.size.height = frame.height > heightDate ? heightDate : frame.height / 2
        dateFrame.origin.y = titleLabel.center.y - (dateFrame.size.height * 0.5)
        dateFrame.origin.x = (frame.width * 0.5)
        dotView.frame = dateFrame
        dateLabel.frame = CGRect(origin: .zero, size: dateFrame.size)
        
        contentView.addSubview(dotView)
        contentView.addSubview(titleLabel)
        dotView.addSubview(dateLabel)
        
        if let radius = style.headerScroll.dotCornersRadius {
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: radius)
        } else {
            let value = dotView.frame.width / 2
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: CGSize(width: value, height: value))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
