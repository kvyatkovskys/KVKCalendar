//
//  ScrollHeaderDayCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let heightDate: CGFloat = 35
private let heightTitle: CGFloat = 25

final class ScrollHeaderDayCell: UICollectionViewCell {
    static let cellIdentifier = #file
    
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
        return label
    }()
    
    private var headerStyle = HeaderScrollStyle()
    
    var style = Style() {
        didSet {
            headerStyle = style.headerScroll
        }
    }
    
    var day: Day = .empty() {
        didSet {
            guard let tempDay = day.date?.day else {
                titleLabel.text = nil
                dateLabel.text = nil
                return
            }
            
            if !headerStyle.titleDays.isEmpty, let title = headerStyle.titleDays[safe: day.type.shiftDay] {
                titleLabel.text = title
            } else {
                titleLabel.text = day.type.rawValue
            }
            dateLabel.text = "\(tempDay)"
            weekendDays(day: day)
        }
    }
    
    var selectDate: Date = Date() {
        didSet {
            let nowDate = Date()
            guard nowDate.month != day.date?.month else {
                // remove the selection if the current date (for the day) does not match the selected one
                if selectDate.day != nowDate.day, day.date?.day == nowDate.day, day.date?.year == nowDate.year {
                    dateLabel.textColor = headerStyle.colorBackgroundCurrentDate
                    dateLabel.backgroundColor = .clear
                }
                // mark the selected date, which is not the same as the current one
                if day.date?.month == selectDate.month, day.date?.day == selectDate.day, selectDate.day != nowDate.day {
                    dateLabel.textColor = headerStyle.colorSelectDate
                    dateLabel.backgroundColor = headerStyle.colorBackgroundSelectDate
                    dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
                    dateLabel.clipsToBounds = true
                }
                return
            }
            
            // select date not in the current month
            guard day.date?.month == selectDate.month, day.date?.day == selectDate.day else {
                weekendDays(day: day)
                return
            }
            dateLabel.textColor = headerStyle.colorSelectDate
            dateLabel.backgroundColor = headerStyle.colorBackgroundSelectDate
            dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
            dateLabel.clipsToBounds = true
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func weekendDays(day: Day) {
        guard day.type == .saturday || day.type == .sunday else {
            isNowDate(date: day.date, colorText: headerStyle.colorDate)
            titleLabel.textColor = headerStyle.colorDate
            return
        }
        isNowDate(date: day.date, colorText: headerStyle.colorWeekendDate)
        titleLabel.textColor = headerStyle.colorWeekendDate
    }
    
    private func isNowDate(date: Date?, colorText: UIColor) {
        let nowDate = Date()
        if date?.month == nowDate.month, date?.day == nowDate.day, date?.year == nowDate.year {
            dateLabel.textColor = headerStyle.colorCurrentDate
            dateLabel.backgroundColor = headerStyle.colorBackgroundCurrentDate
            dateLabel.layer.cornerRadius = dateLabel.frame.height / 2
            dateLabel.clipsToBounds = true
        } else {
            dateLabel.textColor = colorText
            dateLabel.backgroundColor = .clear
        }
    }
}
