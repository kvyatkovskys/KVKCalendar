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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textAlignment = .right
        dateLabel.textAlignment = .left
        
        var titleFrame = frame
        titleFrame.origin.x = 0
        titleFrame.origin.y = 0
        titleFrame.size.width = (frame.width * 0.5) - 5
        titleLabel.frame = titleFrame
        
        var dateFrame = frame
        dateFrame.size.width = frame.width * 0.5
        dateFrame.origin.y = 0
        dateFrame.origin.x = (frame.width * 0.5)
        dotView.frame = CGRect(origin: CGPoint(x: dateFrame.origin.x, y: 0), size: CGSize(width: 30, height: 30))
        dateLabel.frame = dateFrame
        
        dotView.center.y = dateLabel.center.y
        
        addSubview(titleLabel)
        addSubview(dotView)
        addSubview(dateLabel)
        
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
