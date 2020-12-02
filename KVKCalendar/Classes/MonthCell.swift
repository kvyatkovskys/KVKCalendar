//
//  MonthCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthCell: UICollectionViewCell {
    private let titlesCount = 3
    private let countInCell: CGFloat = 4
    private let offset: CGFloat = 3
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.tag = -1
        label.font = monthStyle.fontNameDate
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    private func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.timeSystem.format
        return formatter.string(from: date)
    }
    
    private var monthStyle = MonthStyle()
    private var allDayStyle = AllDayStyle()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(processMovingEvent))
        panGesture.delegate = self
        return panGesture
    }()
    
    private lazy var longGesture: UILongPressGestureRecognizer = {
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(activateMovingEvent))
        longGesture.delegate = self
        longGesture.minimumPressDuration = style.event.minimumPressDuration
        return longGesture
    }()
    
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
            guard bounds.height > (dateLabel.bounds.height + 10) && day.type != .empty else {
                let monthLabel = UILabel(frame: CGRect(x: dateLabel.frame.origin.x - 50, y: dateLabel.frame.origin.y, width: 50, height: dateLabel.bounds.height))
                if let date = day.date, date.day == 1, UIDevice.current.userInterfaceIdiom != .phone {
                    monthLabel.textAlignment = .right
                    monthLabel.textColor = monthStyle.colorNameEmptyDay
                    monthLabel.text = "\(date.titleForLocale(style.locale, formatter: monthStyle.shortInDayMonthFormatter))".capitalized
                    addSubview(monthLabel)
                } else {
                    monthLabel.removeFromSuperview()
                }
                return
            }
            
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
                                                                  textAttributes: [.font: monthStyle.fontEventTitle,
                                                                                   .foregroundColor: monthStyle.colorEventTitle],
                                                                  bulletAttributes: [.font: monthStyle.fontEventBullet,
                                                                                     .foregroundColor: event.color?.value ?? .systemGray],
                                                                  timeAttributes: [.font: monthStyle.fontEventTime,
                                                                                   .foregroundColor: UIColor.systemGray],
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
                    
                    if style.event.states.contains(.move), UIDevice.current.userInterfaceIdiom != .phone, !event.isAllDay {
                        label.addGestureRecognizer(longGesture)
                        label.addGestureRecognizer(panGesture)
                    }
                    addSubview(label)
                }
            }
        }
    }
    
    var day: Day = .empty() {
        didSet {
            isUserInteractionEnabled = day.type != .empty
            
            switch day.type {
            case .empty:
                if let tempDate = day.date, monthStyle.showDatesForOtherMonths {
                    dateLabel.text = "\(tempDate.day)"
                    dateLabel.textColor = monthStyle.colorNameEmptyDay
                } else {
                    dateLabel.text = nil
                }
            default:
                subviews.filter({ $0.tag == -2 }).forEach({ $0.removeFromSuperview() })
                
                if let tempDay = day.date?.day {
                    dateLabel.text = "\(tempDay)"
                } else {
                    dateLabel.text = nil
                }
            }

            if !monthStyle.isHiddenSeporator {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    let topLineLayer = CALayer()
                    topLineLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: monthStyle.widthSeporator)
                    topLineLayer.backgroundColor = monthStyle.colorSeporator.cgColor
                    layer.addSublayer(topLineLayer)
                } else {
                    if day.type != .empty {
                        layer.borderWidth = monthStyle.isHiddenSeporatorOnEmptyDate ? 0 : monthStyle.widthSeporator
                        layer.borderColor = monthStyle.isHiddenSeporatorOnEmptyDate ? UIColor.clear.cgColor : monthStyle.colorSeporator.cgColor
                    } else {
                        layer.borderWidth = monthStyle.widthSeporator
                        layer.borderColor = monthStyle.colorSeporator.cgColor
                    }
                }
            }
            populateCell(day: day, label: dateLabel, view: self)
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
        
        if #available(iOS 13.4, *) {
            addPointInteraction(on: self, delegate: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func processMovingEvent(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            delegate?.didChangeMoveEvent(gesture: gesture)
        default:
            break
        }
    }
    
    @objc private func activateMovingEvent(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let idx = events.firstIndex(where: { $0.hash == gesture.view?.tag }), let view = gesture.view else {
                return
            }
            
            let event = events[idx]
            let snapshotLabel = UILabel(frame: view.frame)
            snapshotLabel.setRoundCorners(monthStyle.eventCorners, radius: monthStyle.eventCornersRadius)
            snapshotLabel.backgroundColor = event.color?.value ?? .systemGray
            snapshotLabel.attributedText = addIconBeforeLabel(eventList: [event],
                                                              textAttributes: [.font: monthStyle.fontEventTitle,
                                                                               .foregroundColor: UIColor.white],
                                                              bulletAttributes: [.font: monthStyle.fontEventBullet,
                                                                                 .foregroundColor: UIColor.white],
                                                              timeAttributes: [.font: monthStyle.fontEventTime,
                                                                               .foregroundColor: UIColor.white],
                                                              indentation: 0,
                                                              lineSpacing: 0,
                                                              paragraphSpacing: 0)
            let snpashot = event.isAllDay ? view.snapshotView(afterScreenUpdates: false) : snapshotLabel
            let eventView = EventViewGeneral(style: style, event: event, frame: view.frame)
            delegate?.didStartMoveEvent(eventView, snapshot: snpashot, gesture: gesture)
        case .cancelled, .ended, .failed:
            delegate?.didEndMoveEvent(gesture: gesture)
        default:
            break
        }
    }
    
    private func populateCell(day: Day, label: UILabel, view: UIView) {
        let date = day.date
        let weekend = day.type == .saturday || day.type == .sunday
        
        let nowDate = Date()
        label.backgroundColor = .clear
        
        var textColorForEmptyDay: UIColor?
        if day.type == .empty {
            textColorForEmptyDay = monthStyle.colorNameEmptyDay
        }
        
        if weekend {
            label.textColor = textColorForEmptyDay ?? monthStyle.colorWeekendDate
            view.backgroundColor = monthStyle.colorBackgroundWeekendDate
        } else {
            view.backgroundColor = monthStyle.colorBackgroundDate
            label.textColor = textColorForEmptyDay ?? monthStyle.colorDate
        }
        
        guard day.type != .empty else { return }
        
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
    
    private func addIconBeforeLabel(eventList: [Event], textAttributes: [NSAttributedString.Key: Any], bulletAttributes: [NSAttributedString.Key: Any], timeAttributes: [NSAttributedString.Key: Any], bullet: String = "\u{2022}", indentation: CGFloat = 10, lineSpacing: CGFloat = 2, paragraphSpacing: CGFloat = 10) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = UIDevice.current.userInterfaceIdiom == .pad ? .left : .center
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: [:])]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        
        return eventList.reduce(NSMutableAttributedString()) { (_, event) -> NSMutableAttributedString in
            let text: String
            if monthStyle.isHiddenTitle {
                text = ""
            } else {
                text = event.textForMonth
            }
            
            let formattedString: String
            if !monthStyle.isHiddenDotInTitle {
                formattedString = "\(bullet) \(text)\n"
            } else {
                formattedString = "\(text)\n"
            }
            let attributedString = NSMutableAttributedString(string: formattedString)
            let string: NSString = NSString(string: formattedString)
            
            let rangeForText = NSMakeRange(0, attributedString.length)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: rangeForText)
            attributedString.addAttributes(textAttributes, range: rangeForText)
            
            if !monthStyle.isHiddenDotInTitle {
                let rangeForBullet = string.range(of: bullet)
                attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            }
            
            return attributedString
        }
    }
}

extension MonthCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

@available(iOS 13.4, *)
extension MonthCell: PointerInteractionProtocol {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .hover(targetedPreview))
        }
        return pointerStyle
    }
}

protocol MonthCellDelegate: class {
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func didStartMoveEvent(_ event: EventViewGeneral, snapshot: UIView?, gesture: UILongPressGestureRecognizer)
    func didEndMoveEvent(gesture: UILongPressGestureRecognizer)
    func didChangeMoveEvent(gesture: UIPanGestureRecognizer)
}
