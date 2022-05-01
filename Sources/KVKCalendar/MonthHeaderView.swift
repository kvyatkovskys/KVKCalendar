//
//  MonthHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 25.12.2021.
//

#if os(iOS)

import UIKit

final class MonthHeaderView: UICollectionReusableView {
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.minimumScaleFactor = 0.7
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var value: (style: Style, date: Date)? {
        didSet {
            dateLabel.removeFromSuperview()
            guard let date = value?.date, let style = value?.style else { return }
            
            dateLabel.font = style.month.fontTitleHeader
            dateLabel.text = date.titleForLocale(style.locale, formatter: style.month.shortInDayMonthFormatter).capitalized
            if Date().month == date.month {
                dateLabel.textColor = style.month.colorTitleCurrentDate
            } else {
                dateLabel.textColor = style.month.colorTitleHeader
            }
            
            let value: CGFloat
            switch style.startWeekDay {
            case .monday:
                if date.isSunday {
                    value = 6
                } else {
                    value = CGFloat(date.weekday - 2)
                }
            case .sunday:
                value = CGFloat(date.weekday - 1)
            }
            
            let offset: CGFloat
            if style.month.scrollDirection == .vertical {
                offset = ((superview?.bounds.width ?? UIScreen.main.bounds.width) / 7) * value + 5
            } else {
                offset = 0
            }

            addSubview(dateLabel)
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let top = dateLabel.topAnchor.constraint(equalTo: topAnchor)
            let bottom = dateLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            let right = dateLabel.rightAnchor.constraint(equalTo: rightAnchor)
            let left = dateLabel.leftAnchor.constraint(lessThanOrEqualTo: leftAnchor, constant: offset)
            NSLayoutConstraint.activate([top, left, right, bottom])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

#endif
