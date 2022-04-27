//
//  WeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class WeekHeaderView: UIView {
    
    struct Parameters {
        var style: Style
        var isFromYear: Bool = false
    }
    
    private var parameters: Parameters
    private var days = [Date]()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.tag = -999
        return label
    }()
    
    var date: Date? {
        didSet {
            setDateToTitle(date: date, style: style)
        }
    }
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        super.init(frame: frame)
        setUI()
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
        
        if !style.month.isHiddenTitleHeader && !isFromYear {
            titleLabel.frame = CGRect(x: 10,
                                      y: 5,
                                      width: frame.width - 20,
                                      height: style.month.heightTitleHeader)
            addSubview(titleLabel)
        }
        
        let y: CGFloat
        if isFromYear {
            y = 0
        } else if !style.month.isHiddenTitleHeader {
            y = style.month.heightTitleHeader + 5
        } else {
            y = 0
        }
        let xOffset: CGFloat = isFromYear ? 0 : 10
        let width = frame.width / CGFloat(days.count)
        for (idx, value) in days.enumerated() {
            let label = UILabel(frame: CGRect(x: (width * CGFloat(idx)) + xOffset,
                                              y: y,
                                              width: width - (xOffset * 2),
                                              height: isFromYear ? frame.height : style.month.heightHeaderWeek))
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textAlignment = isFromYear ? style.year.weekDayAlignment : style.month.weekDayAlignment
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
        if let date = date, !style.month.isHiddenTitleHeader, !isFromYear {
            titleLabel.text = date.titleForLocale(style.locale, formatter: style.month.titleFormatter)
            
            if Date().year == date.year && Date().month == date.month {
                titleLabel.textColor = style.month.colorTitleCurrentDate
            } else {
                titleLabel.textColor = style.month.colorTitleHeader
            }
        }
    }
}

extension WeekHeaderView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            parameters.style
        }
        set {
            parameters.style = newValue
        }
    }
    
    var isFromYear: Bool {
        parameters.isFromYear
    }
    
    func setDate(_ date: Date, animated: Bool) {
        self.date = date
    }
    
    func setUI(reload: Bool = false) {
        subviews.forEach { $0.removeFromSuperview() }
        addViews(frame: frame, isFromYear: isFromYear)

        if !style.month.isHiddenTitleHeader && !isFromYear {
            titleLabel.textAlignment = style.month.titleHeaderAlignment
            titleLabel.font = style.month.fontTitleHeader
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        
        subviews.forEach { $0.removeFromSuperview() }
        addViews(frame: self.frame, isFromYear: isFromYear)
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
    }
}

#endif
