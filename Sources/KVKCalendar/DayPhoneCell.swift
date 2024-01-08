//
//  DayPhoneCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01.10.2020.
//

#if os(iOS)

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

final class DayPhoneNewCell: DayCell {
    
    var phoneStyle: Style? {
        didSet {
            guard let newStyle = phoneStyle else { return }
            
            style = newStyle
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        dotView.addSubview(dateLabel)
        contentView.addSubview(dotView)
        
        dotView.translatesAutoresizingMaskIntoConstraints = false
        let centerYDot = dotView.centerYAnchor.constraint(equalTo: centerYAnchor)
        let centerXDot = dotView.centerXAnchor.constraint(equalTo: centerXAnchor)
        let widthDot = dotView.widthAnchor.constraint(equalToConstant: 35)
        let heightDot = dotView.heightAnchor.constraint(equalToConstant: 35)
        NSLayoutConstraint.activate([centerYDot, centerXDot, widthDot, heightDot])
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        let topDate = dateLabel.topAnchor.constraint(equalTo: dotView.topAnchor)
        let bottomDate = dateLabel.bottomAnchor.constraint(equalTo: dotView.bottomAnchor)
        let leftDate = dateLabel.leftAnchor.constraint(equalTo: dotView.leftAnchor)
        let rightDate = dateLabel.rightAnchor.constraint(equalTo: dotView.rightAnchor)
        NSLayoutConstraint.activate([topDate, bottomDate, leftDate, rightDate])
        
        if let radius = style.headerScroll.dotCornersRadius {
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: radius)
        } else {
            let value = 35 / 2
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: CGSize(width: value, height: value))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
