//
//  WeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class WeekHeaderView: UIView {
    private var style: Style
    private let isFromYear: Bool
    private var days = [Date]()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = style.month.titleDateAligment
        label.font = style.month.fontTitleDate
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
        self.isFromYear = fromYear
        super.init(frame: frame)
        addViews(frame: frame, isFromYear: fromYear)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getOffsetDate(offset: Int, to date: Date?) -> Date? {
        guard let dateTemp = date else { return nil }
        
        return style.calendar.date(byAdding: .day, value: offset, to: dateTemp)
    }
    
    private func addViews(frame: CGRect, isFromYear: Bool) {
        let startWeekDate = style.startWeekDay == .sunday ? Date().startSundayOfWeek : Date().startMondayOfWeek
        if days.isEmpty {
            days = Array(0..<7).compactMap({ getOffsetDate(offset: $0, to: startWeekDate) })
        }
        
        if !style.month.isHiddenTitleDate && !isFromYear {
            titleLabel.frame = CGRect(x: 10,
                                      y: 5,
                                      width: frame.width - 20,
                                      height: style.month.heightTitleDate)
            addSubview(titleLabel)
        }
        
        let y = isFromYear ? 0 : (style.month.heightTitleDate + 5)
        let xOffset: CGFloat = isFromYear ? 0 : 10
        let width = frame.width / CGFloat(days.count)
        for (idx, value) in days.enumerated() {
            let label = UILabel(frame: CGRect(x: (width * CGFloat(idx)) + xOffset,
                                              y: y,
                                              width: width - (xOffset * 2),
                                              height: isFromYear ? frame.height : style.month.heightHeaderWeek))
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textAlignment = isFromYear ? style.year.weekDayAligment : style.month.weekDayAligment
            label.font = isFromYear ? style.year.weekFont : style.month.weekFont
            
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

            if !style.headerScroll.titleDays.isEmpty, let title = style.headerScroll.titleDays[safe: value.weekday - 1] {
                label.text = title
            } else {
                let weekdayFormatter = isFromYear ? style.year.weekdayFormatter : style.month.weekdayFormatter
                label.text = value.titleForLocale(style.locale, formatter: weekdayFormatter).capitalized
            }
            label.tag = value.weekday
            addSubview(label)
        }
    }
    
    private func setDateToTitle(date: Date?, style: Style) {
        if let date = date, !style.month.isHiddenTitleDate, !isFromYear {
            titleLabel.text = date.titleForLocale(style.locale, formatter: style.month.titleFormatter)
            
            if Date().year == date.year && Date().month == date.month {
                titleLabel.textColor = .systemRed
            } else {
                titleLabel.textColor = style.month.colorTitleDate
            }
        }
    }
}

extension WeekHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        
        titleLabel.removeFromSuperview()
        days.forEach { (day) in
            subviews.filter({ $0.tag == day.weekday }).forEach({ $0.removeFromSuperview() })
        }
        addViews(frame: self.frame, isFromYear: isFromYear)
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
}
