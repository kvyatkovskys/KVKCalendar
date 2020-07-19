//
//  ScrollHeaderDayCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class ScrollHeaderDayCell: UICollectionViewCell {
    
    private let heightDate: CGFloat = 35
    private let heightTitle: CGFloat = 25
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 11)
        label.textColor = headerStyle.colorNameDay
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        label.textColor = headerStyle.colorDate
        label.clipsToBounds = true
        return label
    }()
    
    private var headerStyle = HeaderScrollStyle()
    
    var style = Style() {
        didSet {
            headerStyle = style.headerScroll
        }
    }
    
    var item: DayStyle = DayStyle(.empty(), nil) {
        didSet {
            guard let tempDay = item.day.date?.day else {
                titleLabel.text = nil
                dateLabel.text = nil
                return
            }
            
            if !headerStyle.titleDays.isEmpty, let title = headerStyle.titleDays[safe: item.day.type.shiftDay] {
                titleLabel.text = title
            } else {
                titleLabel.text = item.day.type.rawValue
            }
            dateLabel.text = "\(tempDay)"
            populateCell(item)
        }
    }
    
    var selectDate: Date = Date() {
        didSet {
            let nowDate = Date()
            guard nowDate.month != item.day.date?.month else {
                // remove the selection if the current date (for the day) does not match the selected one
                if selectDate.day != nowDate.day, item.day.date?.day == nowDate.day, item.day.date?.year == nowDate.year {
                    dateLabel.textColor = item.style?.textColor ?? headerStyle.colorBackgroundCurrentDate
                    dateLabel.backgroundColor = item.style?.backgroundColor ?? .clear
                }
                // mark the selected date, which is not the same as the current one
                if item.day.date?.month == selectDate.month, item.day.date?.day == selectDate.day, selectDate.day != nowDate.day {
                    dateLabel.textColor = item.style?.textColor ?? headerStyle.colorSelectDate
                    dateLabel.backgroundColor = item.style?.dotBackgroundColor ?? headerStyle.colorBackgroundSelectDate
                }
                return
            }
            
            // select date not in the current month
            guard item.day.date?.month == selectDate.month, item.day.date?.day == selectDate.day else {
                populateCell(item)
                return
            }
            dateLabel.textColor = item.style?.textColor ?? headerStyle.colorSelectDate
            dateLabel.backgroundColor = item.style?.dotBackgroundColor ?? headerStyle.colorBackgroundSelectDate
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var titleFrame = frame
        titleFrame.origin.x = 0
        titleFrame.origin.y = 0
        titleFrame.size.height = titleFrame.height > heightTitle ? heightTitle : titleFrame.height / 2 - 10
        titleLabel.frame = titleFrame
        
        var dateFrame = frame
        dateFrame.size.height = frame.height > heightDate ? heightDate : frame.height / 2
        dateFrame.size.width = heightDate
        dateFrame.origin.y = titleFrame.height
        dateFrame.origin.x = (frame.width / 2) - (dateFrame.width / 2)
        dateLabel.frame = dateFrame
        
        addSubview(titleLabel)
        addSubview(dateLabel)
        
        dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func populateCell(_ item: DayStyle) {
        guard item.day.type == .saturday || item.day.type == .sunday else {
            populateDay(date: item.day.date, colorText: item.style?.textColor ?? headerStyle.colorDate, style: item.style)
            titleLabel.textColor = headerStyle.colorDate
            backgroundColor = item.style?.backgroundColor ?? headerStyle.colorWeekdayBackground
            return
        }
        
        populateDay(date: item.day.date, colorText: item.style?.textColor ?? headerStyle.colorWeekendDate, style: item.style)
        titleLabel.textColor = headerStyle.colorWeekendDate
        backgroundColor = item.style?.backgroundColor ?? headerStyle.colorWeekendBackground
    }
    
    private func populateDay(date: Date?, colorText: UIColor, style: DateStyle?) {
        let nowDate = Date()
        if date?.month == nowDate.month, date?.day == nowDate.day, date?.year == nowDate.year {
            dateLabel.textColor = item.style?.textColor ?? headerStyle.colorCurrentDate
            dateLabel.backgroundColor = style?.dotBackgroundColor ?? headerStyle.colorBackgroundCurrentDate
        } else {
            dateLabel.textColor = colorText
            dateLabel.backgroundColor = style?.backgroundColor ?? .clear
        }
    }
}
