//
//  YearCollectionViewCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let daysInWeek = 7

final class YearCollectionViewCell: UICollectionViewCell {
    static let cellIdentifier = #file
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var style: Style = Style() {
        didSet {
            titleLabel.font = style.yearStyle.fontTitle
            titleLabel.textColor = style.yearStyle.colorTitle
            
            subviews.filter({ $0 is WeekHeaderView }).forEach({ $0.removeFromSuperview() })
            let view = WeekHeaderView(frame: CGRect(x: 0, y: 40, width: frame.width, height: 30), style: style, fromYear: true)
            view.font = style.yearStyle.weekFont
            view.backgroundColorWeekends = style.weekStyle.colorBackgroundWeekendDate
            addSubview(view)
        }
    }
    
    var days: [Day] = [] {
        didSet {
            subviews.filter({ 1...2 ~= $0.tag }).forEach({ $0.removeFromSuperview() })
            var step = 0
            let weekCount = ceil((CGFloat(days.count) / CGFloat(daysInWeek)))
            for idx in 1...Int(weekCount) {
                if idx == Int(weekCount) {
                    let sliceDays = days[step...]
                    addDayToLabel(days: sliceDays, step: idx)
                } else {
                    let sliceDays = days[step..<step + daysInWeek]
                    addDayToLabel(days: sliceDays, step: idx)
                    step += daysInWeek
                }
            }
        }
    }
    
    var selectDate: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.frame = CGRect(x: 3, y: 3, width: frame.width, height: 30)
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addDayToLabel(days: ArraySlice<Day>, step: Int) {
        let width = frame.width / CGFloat(daysInWeek)
        let newY: CGFloat = 70
        let height: CGFloat = (frame.height - newY) / CGFloat(daysInWeek - 1)
        
        for (idx, day) in days.enumerated() {
            let frame = CGRect(x: width * CGFloat(idx),
                               y: newY + (CGFloat(step - 1) * height),
                               width: width,
                               height: height)
            let label = UILabel(frame: frame)
            label.tag = 1
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 15)
            
            if let day = day.date?.day {
                label.text = "\(day)"
            }
            
            var newFrame = frame
            newFrame.size.width = (frame.width + frame.height) / 2
            newFrame.size.height = newFrame.width
            
            let view = UIView(frame: newFrame)
            view.tag = 2
            view.center = label.center
            weekendsDays(day: day, label: label, view: view)
            addSubview(view)
            addSubview(label)
        }
    }
    
    fileprivate func weekendsDays(day: Day, label: UILabel, view: UIView) {
        guard day.type == .saturday || day.type == .sunday else {
            isNowDate(date: day.date, weekend: false, label: label, view: view)
            return
        }
        isNowDate(date: day.date, weekend: true, label: label, view: view)
    }
    
    fileprivate func isNowDate(date: Date?, weekend: Bool, label: UILabel, view: UIView) {
        let nowDate = Date()
        
        if weekend {
            label.textColor = style.yearStyle.colorWeekendDate
            label.backgroundColor = style.yearStyle.colorBackgroundWeekendDate
        } else {
            label.backgroundColor = .clear
        }
        
        if date?.year == nowDate.year && date?.month == nowDate.month {
            if date?.day == nowDate.day && selectDate.day == nowDate.day {
                label.textColor = style.yearStyle.colorCurrentDate
                view.backgroundColor = style.yearStyle.colorBackgroundCurrentDate
                view.layer.cornerRadius = view.frame.height / 2
                view.clipsToBounds = true
                label.backgroundColor = .clear
            } else if date?.day == nowDate.day {
                label.textColor = style.yearStyle.colorBackgroundCurrentDate
                view.backgroundColor = .clear
            } else if selectDate.day == date?.day && selectDate.month == date?.month {
                label.textColor = style.yearStyle.colorSelectDate
                view.backgroundColor = style.yearStyle.colorBackgroundSelectDate
                view.layer.cornerRadius = view.frame.height / 2
                view.clipsToBounds = true
                label.backgroundColor = .clear
            }
        } else {
            if date?.year == selectDate.year && date?.month == selectDate.month && date?.day == selectDate.day {
                label.textColor = style.yearStyle.colorSelectDate
                view.backgroundColor = style.yearStyle.colorBackgroundSelectDate
                view.layer.cornerRadius = view.frame.height / 2
                view.clipsToBounds = true
                label.backgroundColor = .clear
            }
        }
    }
}
