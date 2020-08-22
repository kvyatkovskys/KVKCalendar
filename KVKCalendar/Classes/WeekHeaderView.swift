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
        label.tag = -999
        return label
    }()
    
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
                                              height: fromYear ? frame.height : style.month.heightHeaderWeek))
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textAlignment = .center
            label.font = fromYear ? style.year.weekFont : style.month.weekFont
            
            if value.isWeekend {
                label.textColor = style.week.colorWeekendDate
                label.backgroundColor = style.week.colorWeekendBackground
            } else if value.isWeekday {
                label.textColor = style.week.colorDate
                label.backgroundColor = style.week.colorWeekdayBackground
            } else {
                label.textColor = .clear
                label.backgroundColor = .clear
            }

            if !style.headerScroll.titleDays.isEmpty, let title = style.headerScroll.titleDays[safe: value.shiftDay] {
                label.text = title
            } else {
                label.text = value.rawValue.capitalized
            }
            label.tag = value.shiftDay
            addSubview(label)
        }
        if !style.month.isHiddenTitleDate && !fromYear {
            titleLabel.frame = CGRect(x: 0,
                                      y: style.month.heightHeaderWeek,
                                      width: frame.width,
                                      height: style.month.heightTitleDate - 10)
            addSubview(titleLabel)
        }
    }
    
    private func setDateToTitle(date: Date?, style: Style) {
        if let date = date, !style.month.isHiddenTitleDate {
            var monthStyle = style.month
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
