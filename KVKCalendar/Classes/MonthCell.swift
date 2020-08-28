//
//  MonthCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

protocol MonthCellDelegate: class {
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func didStartMoveEventPage(_ event: Event, snapshot: UIView?, gesture: UILongPressGestureRecognizer)
    func didEndMoveEventPage(_ event: Event, gesture: UILongPressGestureRecognizer)
    func didChangeMoveEventPage(_ event: Event, gesture: UILongPressGestureRecognizer)
}

final class MonthCell: UICollectionViewCell {
    private let titlesCount = 3
    
    private let countInCell: CGFloat = 4
    private let offset: CGFloat = 3
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.tag = -1
        label.font = monthStyle.fontNameDate
        label.textColor = monthStyle.colorNameDay
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    private func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.timeHourSystem.format
        return formatter.string(from: date)
    }
    
    private var monthStyle = MonthStyle()
    private var allDayStyle = AllDayStyle()
    var style = Style() {
        didSet {
            monthStyle = style.month
            allDayStyle = style.allDay
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
            
            let height = (frame.height - dateLabel.bounds.height - 5) / countInCell
            
            for (idx, event) in events.enumerated() {
                let width = frame.width - 10
                let count = idx + 1
                let label = UILabel(frame: CGRect(x: 5, y: 5 + dateLabel.bounds.height + height * CGFloat(idx), width: width, height: height))
                label.isUserInteractionEnabled = true
                
                if count > titlesCount {
                    label.font = monthStyle.fontEventTitle
                    label.lineBreakMode = .byTruncatingMiddle
                    label.adjustsFontSizeToFitWidth = true
                    label.minimumScaleFactor = 0.95
                    label.textAlignment = .center
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnMore))
                    label.tag = event.start.day
                    label.addGestureRecognizer(tap)
                    label.textColor = monthStyle.colorMoreTitle
                    if !monthStyle.isHiddenMoreTitle {
                        let text: String
                        if monthStyle.moreTitle.isEmpty {
                            text = "\(events.count - titlesCount)"
                        } else if frame.height > 80 {
                            text = "\(monthStyle.moreTitle) \(events.count - titlesCount)"
                        } else {
                            text = ""
                        }
                        label.text = text
                    }
                    addSubview(label)
                    return
                } else {
                    if !event.isAllDay || UIDevice.current.userInterfaceIdiom == .phone {
                        label.attributedText = addIconBeforeLabel(eventList: [event],
                                                                  textAttributes: [.font: monthStyle.fontEventTitle, .foregroundColor: monthStyle.colorEventTitle],
                                                                  bulletAttributes: [.font: monthStyle.fontEventBullet, .foregroundColor: event.color?.value ?? .systemGray],
                                                                  timeAttributes: [.font: monthStyle.fontEventTime, .foregroundColor: UIColor.systemGray],
                                                                  indentation: 0,
                                                                  lineSpacing: 0,
                                                                  paragraphSpacing: 0)
                    } else {
                        label.font = monthStyle.fontEventTitle
                        label.lineBreakMode = .byTruncatingMiddle
                        label.adjustsFontSizeToFitWidth = true
                        label.minimumScaleFactor = 0.95
                        label.textAlignment = .left
                        label.backgroundColor = event.color?.value ?? .systemGray
                        label.textColor = allDayStyle.textColor
                        label.text = " \(event.text) "
                        label.setRoundCorners(monthStyle.eventCorners, radius: monthStyle.eventCornersRadius)
                    }
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOneEvent))
                    label.addGestureRecognizer(tap)
                    label.tag = event.hash
                    if style.event.isEnableMoveEvent, UIDevice.current.userInterfaceIdiom != .phone, !event.isAllDay {
                        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateMovingEvent))
                        longGesture.minimumPressDuration = style.event.minimumPressDuration
                        label.addGestureRecognizer(longGesture)
                    }
                    addSubview(label)
                }
            }
        }
    }
    
    var item: DayStyle? = nil {
        didSet {
            guard let value = item else { return }
            
            if let tempDay = value.day.date?.day {
                dateLabel.text = "\(tempDay)"
            } else {
                dateLabel.text = nil
            }
            if !monthStyle.isHiddenSeporator {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    let topLineLayer = CALayer()
                    topLineLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: monthStyle.widthSeporator)
                    topLineLayer.backgroundColor = monthStyle.colorSeporator.cgColor
                    layer.addSublayer(topLineLayer)
                } else {
                    if value.day.type != .empty {
                        layer.borderWidth = monthStyle.isHiddenSeporatorOnEmptyDate ? 0 : monthStyle.widthSeporator
                        layer.borderColor = monthStyle.isHiddenSeporatorOnEmptyDate ? UIColor.clear.cgColor : monthStyle.colorSeporator.cgColor
                    } else {
                        layer.borderWidth = monthStyle.widthSeporator
                        layer.borderColor = monthStyle.colorSeporator.cgColor
                    }
                }
            }
            populateCell(cellStyle: value, label: dateLabel, view: self)
        }
    }
    
    var selectDate: Date = Date()
    
    @objc private func tapOneEvent(gesture: UITapGestureRecognizer) {
        if let idx = events.firstIndex(where: { $0.hash == gesture.view?.tag }) {
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
            dateFrame.size = CGSize(width: 30, height: 30)
            dateFrame.origin.x = (frame.width - dateFrame.width) - offset
        } else {
            let newWidth = frame.width > 30 ? 30 : frame.width
            dateFrame.size = CGSize(width: newWidth, height: newWidth)
            dateFrame.origin.x = (frame.width / 2) - (dateFrame.width / 2)
        }
        dateFrame.origin.y = offset
        dateLabel.frame = dateFrame
        addSubview(dateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func activateMovingEvent(gesture: UILongPressGestureRecognizer) {
        guard let idx = events.firstIndex(where: { $0.hash == gesture.view?.tag }), let view = gesture.view else { return }
        
        let event = events[idx]
        let snapshotLabel = UILabel(frame: view.frame)
        snapshotLabel.setRoundCorners(monthStyle.eventCorners, radius: monthStyle.eventCornersRadius)
        snapshotLabel.backgroundColor = event.color?.value ?? .systemGray
        snapshotLabel.attributedText = addIconBeforeLabel(eventList: [event],
                                                          textAttributes: [.font: monthStyle.fontEventTitle, .foregroundColor: UIColor.white],
                                                          bulletAttributes: [.font: monthStyle.fontEventBullet, .foregroundColor: UIColor.white],
                                                          timeAttributes: [.font: monthStyle.fontEventTime, .foregroundColor: UIColor.white],
                                                          indentation: 0,
                                                          lineSpacing: 0,
                                                          paragraphSpacing: 0)
        let snpashot = event.isAllDay ? view.snapshotView(afterScreenUpdates: false) : snapshotLabel
        switch gesture.state {
        case .began:
            delegate?.didStartMoveEventPage(event, snapshot: snpashot, gesture: gesture)
        case .changed:
            delegate?.didChangeMoveEventPage(event, gesture: gesture)
        case .cancelled, .ended, .failed:
            delegate?.didEndMoveEventPage(event, gesture: gesture)
        default:
            break
        }
    }
    
    private func populateCell(cellStyle: DayStyle, label: UILabel, view: UIView) {
        let date = cellStyle.day.date
        let weekend = cellStyle.day.type == .saturday || cellStyle.day.type == .sunday
        
        let nowDate = Date()
        label.backgroundColor = .clear
        
        if weekend {
            label.textColor = cellStyle.style?.textColor ?? monthStyle.colorWeekendDate
            view.backgroundColor = cellStyle.style?.backgroundColor ?? monthStyle.colorBackgroundWeekendDate
        } else {
            view.backgroundColor = cellStyle.style?.backgroundColor ?? monthStyle.colorBackgroundDate
            label.textColor = cellStyle.style?.textColor ?? monthStyle.colorDate
        }
        
        guard date?.year == nowDate.year else {
            if date?.year == selectDate.year && date?.month == selectDate.month && date?.day == selectDate.day {
                label.textColor = cellStyle.style?.textColor ?? monthStyle.colorSelectDate
                label.backgroundColor = cellStyle.style?.dotBackgroundColor ?? monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.month == nowDate.month else {
            if selectDate.day == date?.day && selectDate.month == date?.month {
                label.textColor = cellStyle.style?.textColor ?? monthStyle.colorSelectDate
                label.backgroundColor = cellStyle.style?.dotBackgroundColor ?? monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.day == nowDate.day else {
            if selectDate.day == date?.day && date?.month == selectDate.month {
                label.textColor = cellStyle.style?.textColor ?? monthStyle.colorSelectDate
                label.backgroundColor = cellStyle.style?.dotBackgroundColor ?? monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard selectDate.day == date?.day && selectDate.month == date?.month else {
            if date?.day == nowDate.day, cellStyle.style == nil {
                label.textColor = monthStyle.colorDate
                label.backgroundColor = .clear
            }
            return
        }
        
        label.textColor = cellStyle.style?.textColor ?? monthStyle.colorCurrentDate
        label.backgroundColor = cellStyle.style?.dotBackgroundColor ?? monthStyle.colorBackgroundCurrentDate
        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true
    }
    
    private func addIconBeforeLabel(eventList: [Event], textAttributes: [NSAttributedString.Key: Any], bulletAttributes: [NSAttributedString.Key: Any], timeAttributes: [NSAttributedString.Key: Any], bullet: String = "\u{2022}", indentation: CGFloat = 10, lineSpacing: CGFloat = 2, paragraphSpacing: CGFloat = 10) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = UIDevice.current.userInterfaceIdiom == .pad ? .left : .center
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: [:])]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        
        return eventList.reduce(NSMutableAttributedString()) { _, event -> NSMutableAttributedString in
            let formattedString: String
            let time = timeFormatter(date: event.start)
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                formattedString = "\(bullet) \(event.textForMonth)  \(time)\n"
            default:
                formattedString = bullet
            }
            let attributedString = NSMutableAttributedString(string: formattedString)
            let string: NSString = NSString(string: formattedString)
            
            let rangeForText = NSMakeRange(0, attributedString.length)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: rangeForText)
            attributedString.addAttributes(textAttributes, range: rangeForText)
            
            let rangeForBullet = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            
            let rangeForTime = string.range(of: time)
            attributedString.addAttributes(timeAttributes, range: rangeForTime)
            return attributedString
        }
    }
}
