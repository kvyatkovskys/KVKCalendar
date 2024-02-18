//
//  DayPadCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01.10.2020.
//

#if os(iOS)

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
        dateLabel.textAlignment = .center
        
        var titleFrame = frame
        titleFrame.origin = .zero
        titleFrame.size.width = frame.width * 0.49
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

final class DayPadNewCell: DayCell {
    var padStyle: Style? {
        didSet {
            guard let newStyle = padStyle else { return }
            
            style = newStyle
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        titleLabel.textAlignment = .right
        dateLabel.textAlignment = !isSelected ? .center : .left
        contentView.addSubview(dotView)
        contentView.addSubview(titleLabel)
        dotView.addSubview(dateLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let topTitle = titleLabel.topAnchor.constraint(equalTo: topAnchor)
        let bottomTitle = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        let leftTitle = titleLabel.leftAnchor.constraint(equalTo: leftAnchor)
        let rightTitle = titleLabel.rightAnchor.constraint(equalTo: centerXAnchor, constant: !isSelected ? -2 : 0)
        NSLayoutConstraint.activate([topTitle, bottomTitle, leftTitle, rightTitle])
        
        dotView.translatesAutoresizingMaskIntoConstraints = false
        let centerYDot = dotView.centerYAnchor.constraint(equalTo: centerYAnchor)
        let leftDot = dotView.leftAnchor.constraint(equalTo: centerXAnchor, constant: !isSelected ? 2 : 0)
        let widthDot = dotView.widthAnchor.constraint(equalToConstant: 35)
        let heightDot = dotView.heightAnchor.constraint(equalToConstant: 35)
        NSLayoutConstraint.activate([centerYDot, leftDot, widthDot, heightDot])
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        let topDate = dateLabel.topAnchor.constraint(equalTo: dotView.topAnchor)
        let bottomDate = dateLabel.bottomAnchor.constraint(equalTo: dotView.bottomAnchor)
        let leftDate = dateLabel.leftAnchor.constraint(equalTo: dotView.leftAnchor)
        let rightDate = dateLabel.rightAnchor.constraint(equalTo: dotView.rightAnchor)
        NSLayoutConstraint.activate([topDate, bottomDate, leftDate, rightDate])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let radius = style.headerScroll.dotCornersRadius {
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: radius)
        } else {
            let value = dotView.frame.width / 2
            dotView.setRoundCorners(style.headerScroll.dotCorners, radius: CGSize(width: value, height: value))
        }
    }
}

#endif
