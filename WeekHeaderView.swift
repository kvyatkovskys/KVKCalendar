//
//  WeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekHeaderView: UIView {
    var font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            subviews.filter({ $0 is UILabel }).forEach { (label) in
                if let label = label as? UILabel {
                    label.font = font
                }
            }
        }
    }
    
    var backgroundColorWeekends: UIColor = .clear {
        didSet {
            subviews.filter({ $0 is UILabel }).forEach { (label) in
                if let label = label as? UILabel {
                    if label.tag == DayType.sunday.shiftDay || label.tag == DayType.saturday.shiftDay {
                        label.backgroundColor = backgroundColorWeekends
                    } else {
                        label.backgroundColor = .clear
                    }
                }
            }
        }
    }
    
    init(frame: CGRect, style: Style) {
        super.init(frame: frame)
        
        let days = DayType.allCases.filter({ $0 != .empty })
        let width = frame.width / CGFloat(days.count)
        for (idx, value) in days.enumerated() {
            let label = UILabel(frame: CGRect(x: width * CGFloat(idx), y: 0, width: width, height: frame.height))
            label.textAlignment = .center
            label.textColor = (value == .sunday || value == .saturday) ? .gray : .black
            if !style.headerScrollStyle.titleDays.isEmpty {
                label.text = style.headerScrollStyle.titleDays[value.shiftDay]
            } else {
                label.text = value.rawValue.capitalized
            }
            label.tag = value.shiftDay
            addSubview(label)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
