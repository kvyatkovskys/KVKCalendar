//
//  AllDayEventCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.05.2021.
//

import UIKit

final class AllDayEventCell: UICollectionViewCell {
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    var value: (style: AllDayStyle, event: Event)? {
        didSet {
            guard let item = value else {
                textLabel.text = nil
                textLabel.backgroundColor = nil
                backgroundColor = nil
                return
            }
            
            backgroundColor = UIScreen.isDarkMode ? item.style.backgroundColor : UIColor.white
            textLabel.frame.size.width = frame.width
            textLabel.backgroundColor = item.event.backgroundColor
            textLabel.text = item.event.text
            textLabel.textColor = item.event.textColor
            textLabel.font = item.style.font
            textLabel.setRoundCorners(item.style.eventCorners, radius: item.style.eventCornersRadius)

        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(textLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
