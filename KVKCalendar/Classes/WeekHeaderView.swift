//
//  WeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekHeaderView: UIView {
    private var style: Style
    private let fromYear: Bool
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    var font: UIFont = .systemFont(ofSize: 17) {
        willSet {
            subviews.filter({ $0 is UILabel }).forEach { (label) in
                if let label = label as? UILabel {
                    label.font = newValue
                }
            }
        }
    }
    
    var backgroundColorWeekends: UIColor = .clear {
        willSet {
            subviews.filter({ $0 is UILabel }).forEach { (label) in
                if let label = label as? UILabel {
                    if label.tag == DayType.sunday.shiftDay || label.tag == DayType.saturday.shiftDay {
                        label.backgroundColor = newValue
                    } else {
                        label.backgroundColor = .clear
                    }
                }
            }
        }
    }
    
    var date: Date? {
        willSet {
            setDateToTitle(date: newValue, style: style)
        }
    }
    
    init(frame: CGRect, style: Style, fromYear: Bool = false) {
        self.style = style
        self.fromYear = fromYear
        super.init(frame: frame)
        addViews(frame: frame, fromYear: fromYear)
    }
    
    private func addViews(frame: CGRect, fromYear: Bool) {
        var days = DayType.allCases.filter({ $0 != .empty })
        
        if let idx = days.firstIndex(where: { $0 == .sunday }), style.startWeekDay == .sunday {
            let leftDays = days[..<idx]
            days[..<idx] = []
            days += leftDays
        }
        
        let width = frame.width / CGFloat(days.count)
        for (idx, value) in days.enumerated() {
            let label = UILabel(frame: CGRect(x: width * CGFloat(idx),
                                              y: 0,
                                              width: width,
                                              height: fromYear ? frame.height : style.monthStyle.heightHeaderWeek))
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.textColor = (value == .sunday || value == .saturday) ? style.weekStyle.colorWeekendDate : style.weekStyle.colorDate
            if !style.headerScrollStyle.titleDays.isEmpty, let title = style.headerScrollStyle.titleDays[safe: value.shiftDay] {
                label.text = title
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
    
    private func setDateToTitle(date: Date?, style: Style) {
        if let date = date, !style.monthStyle.isHiddenTitleDate {
            var monthStyle = style.monthStyle
            let formatter = monthStyle.formatter
            titleLabel.text = formatter.string(from: date)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WeekHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        titleLabel.removeFromSuperview()
        DayType.allCases.filter({ $0 != .empty }).forEach { (day) in
            subviews.filter({ $0.tag == day.shiftDay }).forEach({ $0.removeFromSuperview() })
        }
        addViews(frame: self.frame, fromYear: fromYear)
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
}
