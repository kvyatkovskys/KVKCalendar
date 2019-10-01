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
    
    private lazy var dateLabel: UILabel = {
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
        willSet {
            subviews.filter({ $0.tag != -1 }).forEach({ $0.removeFromSuperview() })
            
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation.isLandscape {
                return
            }
            
            let height = (frame.height - dateLabel.bounds.height - offset) / countInCell
            for (idx, event) in newValue.enumerated() {
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
                    label.text = "\(style.moreTitle) \(newValue.count - MonthCollectionViewCell.titlesCount)"
                    addSubview(label)
                    return
                } else {
                    label.attributedText = addIconBeforeLabel(stringList: [event.textForMonth],
                                                              font: style.fontEventTitle,
                                                              bullet: "•",
                                                              textColor: style.colorEventTitle,
                                                              bulletColor: event.color?.value ?? .systemGray)
                }
                addSubview(label)
            }
        }
    }
    
    var day: Day = Day.empty() {
        willSet {
            dateLabel.text = newValue.day
            if !style.isHiddenSeporator {
                layer.borderWidth = newValue.type != .empty ? style.widthSeporator : 0
                layer.borderColor = newValue.type != .empty ? style.colorSeporator.cgColor : UIColor.clear.cgColor
            }
            weekendsDays(day: newValue, label: dateLabel, view: self)
        }
    }
    
    var selectDate: Date = Date()
    
    @objc private func tapOneEvent(gesture: UITapGestureRecognizer) {
        if let idx = events.firstIndex(where: { "\($0.id)".hashValue == gesture.view?.tag }) {
            let location = gesture.location(in: superview)
            let newFrame = CGRect(x: location.x, y: location.y, width: gesture.view?.frame.width ?? 0, height: gesture.view?.frame.size.height ?? 0)
            delegate?.didSelectEvent(events[idx], frame: newFrame)
        }
    }
    
    @objc private func tapOnMore(gesture: UITapGestureRecognizer) {
        if let idx = events.firstIndex(where: { $0.start.day == gesture.view?.tag }) {
            let location = gesture.location(in: superview)
            let newFrame = CGRect(x: location.x, y: location.y, width: gesture.view?.frame.width ?? 0, height: gesture.view?.frame.size.height ?? 0)
            delegate?.didSelectMore(events[idx].start, frame: newFrame)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var dateFrame = frame
        dateFrame.size = CGSize(width: 35, height: 35)
        dateFrame.origin.y = offset
        dateFrame.origin.x = (frame.width - dateFrame.width)
        dateLabel.frame = dateFrame
        addSubview(dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func weekendsDays(day: Day, label: UILabel, view: UIView) {
        isNowDate(date: day.date, weekend: day.type == .saturday || day.type == .sunday, label: label, view: view)
    }
    
    private func isNowDate(date: Date?, weekend: Bool, label: UILabel, view: UIView) {
        let nowDate = Date()
        label.backgroundColor = .clear
        
        if weekend {
            label.textColor = style.colorWeekendDate
            view.backgroundColor = style.colorBackgroundWeekendDate
        } else {
            view.backgroundColor = style.colorBackgroundDate
            label.textColor = style.colorDate
        }
        
        guard date?.year == nowDate.year else {
            if date?.year == selectDate.year && date?.month == selectDate.month && date?.day == selectDate.day {
                label.textColor = style.colorSelectDate
                label.backgroundColor = style.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard date?.month == nowDate.month else {
            if selectDate.day == date?.day && selectDate.month == date?.month {
                label.textColor = style.colorSelectDate
                label.backgroundColor = style.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard date?.day == nowDate.day else {
            if selectDate.day == date?.day && date?.month == selectDate.month {
                label.textColor = style.colorSelectDate
                label.backgroundColor = style.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard selectDate.day == date?.day && selectDate.month == date?.month else {
            if date?.day == nowDate.day {
                label.textColor = style.colorDate
                label.backgroundColor = .clear
            }
            return
        }

        label.textColor = style.colorCurrentDate
        label.backgroundColor = style.colorBackgroundCurrentDate
        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true
    }
    
    private func addIconBeforeLabel(stringList: [String], font: UIFont, bullet: String = "\u{2022}", indentation: CGFloat = 10, lineSpacing: CGFloat = 2, paragraphSpacing: CGFloat = 10, textColor: UIColor, bulletColor: UIColor) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: bulletColor]
        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        let bulletList = NSMutableAttributedString()
        for string in stringList {
            let formattedString = "\(bullet)\t\(string)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attributedString.length))
            attributedString.addAttributes(textAttributes, range: NSMakeRange(0, attributedString.length))
            let string: NSString = NSString(string: formattedString)
            let rangeForBullet: NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletList.append(attributedString)
        }
        return bulletList
    }
}
