//
//  MonthCollectionViewCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let countInCell: CGFloat = 4
private let offset: CGFloat = 5

protocol MonthCellDelegate: AnyObject {
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
}

final class MonthCollectionViewCell: UICollectionViewCell {
    static let cellIdentifier = #file
    static let titlesCount = 3
    
    fileprivate lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.tag = -1
        label.font = style.fontNameDate
        label.textColor = style.colorNameDay
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    var style = MonthStyle()
    weak var delegate: MonthCellDelegate?
    
    var events: [Event] = [] {
        didSet {
            subviews.filter({ $0.tag != -1 }).forEach({ $0.removeFromSuperview() })
            let height = (frame.height - dateLabel.bounds.height - offset) / countInCell
            for (idx, event) in events.enumerated() {
                let count = idx + 1
                let label = UILabel(frame: CGRect(x: 5,
                                                  y: offset + dateLabel.bounds.height + height * CGFloat(idx),
                                                  width: frame.width - 10,
                                                  height: height))
                label.isUserInteractionEnabled = true
                label.tag = "\(event.id)".hashValue
                let tap = UITapGestureRecognizer(target: self, action: #selector(tapOneEvent))
                label.addGestureRecognizer(tap)
                label.font = style.fontEventTitle
                label.textColor = style.colorEventTitle
                label.lineBreakMode = .byTruncatingMiddle
                label.textAlignment = .center
                if count > MonthCollectionViewCell.titlesCount {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnMore))
                    label.tag = event.start.day
                    label.addGestureRecognizer(tap)
                    label.textColor = style.colorMoreTitle
                    label.text = "\(style.moreTitle) \(events.count - MonthCollectionViewCell.titlesCount)"
                    addSubview(label)
                    return
                } else {
                    label.text = event.textForMonth
                }
                addSubview(label)
            }
        }
    }
    
    var day: Day = Day.empty() {
        didSet {
            dateLabel.text = day.day
            if !style.isHiddenSeporator {
                layer.borderWidth = day.type != .empty ? style.widthSeporator : 0
                layer.borderColor = day.type != .empty ? style.colorSeporator.cgColor : UIColor.clear.cgColor
            }
            weekendsDays(day: day)
        }
    }
    
    var selectDate: Date = Date() {
        didSet {
            let nowDate = Date()
            guard nowDate.month != day.date?.month else {
                // remove the selection if the current date (for the day) does not match the selected one
                if selectDate.day != nowDate.day && day.date?.day == nowDate.day {
                    dateLabel.textColor = style.colorBackgroundCurrentDate
                    dateLabel.backgroundColor = .clear
                }
                // mark the selected date, which is not the same as the current one
                if day.date?.month == selectDate.month && day.date?.day == selectDate.day && selectDate.day != nowDate.day {
                    dateLabel.textColor = style.colorSelectDate
                    dateLabel.backgroundColor = style.colorBackgroundSelectDate
                    dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
                }
                return
            }
            
            // select date not in the current month
            guard day.date?.month == selectDate.month && day.date?.day == selectDate.day else {
                weekendsDays(day: day)
                return
            }
            dateLabel.textColor = style.colorSelectDate
            dateLabel.backgroundColor = style.colorBackgroundSelectDate
            dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
        }
    }
    
    @objc fileprivate func tapOneEvent(gesture: UITapGestureRecognizer) {
        if let idx = events.index(where: { "\($0.id)".hashValue == gesture.view?.tag }) {
            delegate?.didSelectEvent(events[idx], frame: gesture.view?.frame)
        }
    }
    
    @objc fileprivate func tapOnMore(gesture: UITapGestureRecognizer) {
        if let idx = events.index(where: { $0.start.day == gesture.view?.tag }) {
            delegate?.didSelectMore(events[idx].start, frame: gesture.view?.frame)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var dateFrame = frame
        dateFrame.size = CGSize(width: 35, height: 35)
        dateFrame.origin.y = offset
        dateFrame.origin.x = frame.width - dateFrame.width - dateFrame.origin.y
        dateLabel.frame = dateFrame
        addSubview(dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func weekendsDays(day: Day) {
        guard day.type == .saturday || day.type == .sunday else {
            backgroundColor = style.colorBackgroundDate
            isNowDate(date: day.date, colorText: style.colorDate)
            return
        }
        isNowDate(date: day.date, colorText: style.colorWeekendDate)
        backgroundColor = style.colorBackgroundWeekendDate
    }
    
    fileprivate func isNowDate(date: Date?, colorText: UIColor) {
        let nowDate = Date()
        if date?.month == nowDate.month && date?.day == nowDate.day {
            dateLabel.textColor = style.colorCurrentDate
            dateLabel.backgroundColor = style.colorBackgroundCurrentDate
            dateLabel.layer.cornerRadius = dateLabel.frame.width / 2
        } else {
            dateLabel.textColor = colorText
            dateLabel.backgroundColor = .clear
        }
    }
}
