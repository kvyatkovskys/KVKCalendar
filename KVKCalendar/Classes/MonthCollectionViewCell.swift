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
        label.font = monthStyle.fontNameDate
        label.textColor = monthStyle.colorNameDay
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    private var monthStyle = MonthStyle()
    var style = Style() {
        didSet {
            monthStyle = style.month
        }
    }
    weak var delegate: MonthCellDelegate?
    
    var events: [Event] = [] {
        didSet {
            subviews.filter({ $0.tag != -1 }).forEach({ $0.removeFromSuperview() })
            guard bounds.height > dateLabel.bounds.height + 10 else { return }
            
            if UIDevice.current.userInterfaceIdiom == .phone, UIDevice.current.orientation.isLandscape {
                return
            }
            
            let height = (frame.height - dateLabel.bounds.height - offset) / countInCell
            for (idx, event) in events.enumerated() {
                let count = idx + 1
                let label = UILabel(frame: CGRect(x: 5,
                                                  y: offset + dateLabel.bounds.height + height * CGFloat(idx),
                                                  width: frame.width - 10,
                                                  height: height))
                label.isUserInteractionEnabled = true
                label.font = monthStyle.fontEventTitle
                label.textColor = monthStyle.colorEventTitle
                label.lineBreakMode = .byTruncatingMiddle
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.8
                
                if count > MonthCollectionViewCell.titlesCount {
                    label.textAlignment = .center
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnMore))
                    label.tag = event.start.day
                    label.addGestureRecognizer(tap)
                    label.textColor = monthStyle.colorMoreTitle
                    if !monthStyle.isHiddenMoreTitle {
                        let text: String
                        if monthStyle.moreTitle.isEmpty {
                            text = "\(events.count - MonthCollectionViewCell.titlesCount)"
                        } else {
                            text = "\(monthStyle.moreTitle) \(events.count - MonthCollectionViewCell.titlesCount)"
                        }
                        label.text = text
                    }
                    addSubview(label)
                    return
                } else {
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOneEvent))
                    label.addGestureRecognizer(tap)
                    label.tag = "\(event.id)".hashValue
                    label.attributedText = addIconBeforeLabel(stringList: [event.textForMonth],
                                                              font: UIDevice.current.userInterfaceIdiom == .pad ? monthStyle.fontEventTitle : monthStyle.fontEventBullet,
                                                              bullet: "•",
                                                              textColor: monthStyle.colorEventTitle,
                                                              bulletColor: event.color?.value ?? .systemGray)
                }
                addSubview(label)
            }
        }
    }
    
    var day: Day = .empty() {
        didSet {
            if let tempDay = day.date?.day {
                dateLabel.text = "\(tempDay)"
            } else {
                dateLabel.text = nil
            }
            if !monthStyle.isHiddenSeporator {
                layer.borderWidth = day.type != .empty ? monthStyle.widthSeporator : 0
                layer.borderColor = day.type != .empty ? monthStyle.colorSeporator.cgColor : UIColor.clear.cgColor
            }
            weekendsDays(day: day, label: dateLabel, view: self)
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            dateFrame.size = CGSize(width: 35, height: 35)
        } else {
            dateFrame.size = CGSize(width: frame.width, height: frame.width)
        }
        dateFrame.origin.y = offset
        if UIDevice.current.userInterfaceIdiom == .pad {
            dateFrame.origin.x = (frame.width - dateFrame.width) - offset
        } else {
            dateFrame.origin.x = (frame.width / 2) - (dateFrame.width / 2)
        }
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
            label.textColor = monthStyle.colorWeekendDate
            view.backgroundColor = monthStyle.colorBackgroundWeekendDate
        } else {
            view.backgroundColor = monthStyle.colorBackgroundDate
            label.textColor = monthStyle.colorDate
        }
        
        guard date?.year == nowDate.year else {
            if date?.year == selectDate.year && date?.month == selectDate.month && date?.day == selectDate.day {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard date?.month == nowDate.month else {
            if selectDate.day == date?.day && selectDate.month == date?.month {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard date?.day == nowDate.day else {
            if selectDate.day == date?.day && date?.month == selectDate.month {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }

        guard selectDate.day == date?.day && selectDate.month == date?.month else {
            if date?.day == nowDate.day {
                label.textColor = monthStyle.colorDate
                label.backgroundColor = .clear
            }
            return
        }

        label.textColor = monthStyle.colorCurrentDate
        label.backgroundColor = monthStyle.colorBackgroundCurrentDate
        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true
    }
    
    private func addIconBeforeLabel(stringList: [String], font: UIFont, bullet: String = "\u{2022}", indentation: CGFloat = 10, lineSpacing: CGFloat = 2, paragraphSpacing: CGFloat = 10, textColor: UIColor, bulletColor: UIColor) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: bulletColor]
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.alignment = UIDevice.current.userInterfaceIdiom == .pad ? .left : .center
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: [:])]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        
        return stringList.reduce(NSMutableAttributedString()) { _, string -> NSMutableAttributedString in
            let formattedString = UIDevice.current.userInterfaceIdiom == .pad ? "\(bullet)\t\(string)\n" : bullet
            let attributedString = NSMutableAttributedString(string: formattedString)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attributedString.length))
            attributedString.addAttributes(textAttributes, range: NSMakeRange(0, attributedString.length))
            let string: NSString = NSString(string: formattedString)
            let rangeForBullet: NSRange = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            return attributedString
        }
    }
}
