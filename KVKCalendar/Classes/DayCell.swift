//
//  DayCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01.10.2020.
//

import UIKit

class DayCell: UICollectionViewCell {
    
    private(set) var heightDate: CGFloat = 35
    private(set) var heightTitle: CGFloat = 25
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    var dotView: UIView = {
        let view = UIView()
        return view
    }()
    
    var style = Style() {
        didSet {
            titleLabel.font = style.headerScroll.fontNameDay
            titleLabel.textColor = style.headerScroll.colorNameDay
            
            dateLabel.font = style.headerScroll.fontDate
            dateLabel.textColor = style.headerScroll.colorDate
        }
    }
        
    var day: Day = .empty() {
        didSet {
            guard let tempDay = day.date?.day else {
                titleLabel.text = nil
                dateLabel.text = nil
                return
            }
            
            if !style.headerScroll.titleDays.isEmpty, let title = style.headerScroll.titleDays[safe: day.type.shiftDay] {
                titleLabel.text = title
            } else {
                titleLabel.text = day.type.rawValue.capitalized
            }
            dateLabel.text = "\(tempDay)"
            populateCell(day)
        }
    }
    
    var selectDate: Date = Date() {
        didSet {
            let nowDate = Date()
            guard nowDate.month != day.date?.month else {
                // remove the selection if the current date (for the day) does not match the selected one
                if selectDate.day != nowDate.day, day.date?.day == nowDate.day, day.date?.year == nowDate.year {
                    dateLabel.textColor = style.headerScroll.colorBackgroundCurrentDate
                    dotView.backgroundColor = .clear
                    isSelected = false
                }
                // mark the selected date, which is not the same as the current one
                if day.date?.month == selectDate.month, day.date?.day == selectDate.day, selectDate.day != nowDate.day {
                    dateLabel.textColor = style.headerScroll.colorSelectDate
                    dotView.backgroundColor = style.headerScroll.colorBackgroundSelectDate
                    isSelected = true
                }
                return
            }
            
            guard day.date?.month == selectDate.month, day.date?.day == selectDate.day else {
                populateCell(day)
                return
            }
            dateLabel.textColor = style.headerScroll.colorSelectDate
            dotView.backgroundColor = style.headerScroll.colorBackgroundSelectDate
            isSelected = true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func populateCell(_ day: Day) {
        guard day.type == .saturday || day.type == .sunday else {
            populateDay(date: day.date, colorText: style.headerScroll.colorDate)
            titleLabel.textColor = style.headerScroll.colorDate
            backgroundColor = style.headerScroll.colorWeekdayBackground
            return
        }
        
        populateDay(date: day.date, colorText: style.headerScroll.colorWeekendDate)
        titleLabel.textColor = style.headerScroll.colorWeekendDate
        backgroundColor = style.headerScroll.colorWeekendBackground
    }
    
    private func populateDay(date: Date?, colorText: UIColor) {
        let nowDate = Date()
        if date?.month == nowDate.month, date?.day == nowDate.day, date?.year == nowDate.year {
            dateLabel.textColor = UIScreen.isDarkMode ? style.headerScroll.colorCurrentSelectDateForDarkStyle : style.headerScroll.colorCurrentDate
            dotView.backgroundColor = style.headerScroll.colorBackgroundCurrentDate
        } else {
            dateLabel.textColor = colorText
            dotView.backgroundColor = .clear
        }
        isSelected = false
    }
}
