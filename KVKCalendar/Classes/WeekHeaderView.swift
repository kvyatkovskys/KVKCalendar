//
//  WeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekHeaderView: UIView {
    fileprivate let style: Style
    fileprivate let fromYear: Bool
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
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
    
    var date: Date? {
        didSet {
            setDateToTitle(date: date, style: style)
        }
    }
    
    init(frame: CGRect, style: Style, fromYear: Bool = false) {
        self.style = style
        self.fromYear = fromYear
        super.init(frame: frame)
        addViews(frame: frame, fromYear: fromYear)
    }
    
    fileprivate func addViews(frame: CGRect, fromYear: Bool) {
        let days = DayType.allCases.filter({ $0 != .empty })
        let width = frame.width / CGFloat(days.count)
        for (idx, value) in days.enumerated() {
            let label = UILabel(frame: CGRect(x: width * CGFloat(idx),
                                              y: 0,
                                              width: width,
                                              height: fromYear ? frame.height : style.monthStyle.heightHeaderWeek))
            label.adjustsFontSizeToFitWidth = true
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
        if !style.monthStyle.isHiddenTitleDate && !fromYear {
            titleLabel.frame = CGRect(x: 0,
                                      y: style.monthStyle.heightHeaderWeek,
                                      width: frame.width,
                                      height: style.monthStyle.heightTitleDate - 10)
            addSubview(titleLabel)
        }
    }
    
    fileprivate func setDateToTitle(date: Date?, style: Style) {
        var styleMonth = style
        if let date = date, !styleMonth.monthStyle.isHiddenTitleDate {
            titleLabel.text = styleMonth.monthStyle.formatter.string(from: date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WeekHeaderView: CalendarFrameDelegate {
    func reloadFrame(frame: CGRect) {
        self.frame.size.width = frame.width
        titleLabel.removeFromSuperview()
        DayType.allCases.filter({ $0 != .empty }).forEach { (day) in
            subviews.filter({ $0.tag == day.shiftDay }).forEach({ $0.removeFromSuperview() })
        }
        addViews(frame: self.frame, fromYear: fromYear)
    }
}
