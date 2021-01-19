//
//  DayPhoneCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01.10.2020.
//

import UIKit

final class DayPhoneCell: DayCell {
    
    var phoneStyle: Style? {
        didSet {
            guard let newStyle = phoneStyle else { return }
            
            style = newStyle
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var titleFrame = frame
        titleFrame.origin.x = 0
        titleFrame.origin.y = 0
        titleFrame.size.height = titleFrame.height > heightTitle ? heightTitle : titleFrame.height / 2 - 10
        titleLabel.frame = titleFrame

        var dateFrame = frame
        dateFrame.size.height = frame.height > heightDate ? heightDate : frame.height / 2
        dateFrame.size.width = heightDate
        dateFrame.origin.y = titleFrame.height
        dateFrame.origin.x = (frame.width / 2) - (dateFrame.width / 2)
        dotView.frame = dateFrame
        dateLabel.frame = CGRect(origin: .zero, size: dateFrame.size)

        dotView.addSubview(dateLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dotView)

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
