//
//  MonthCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class MonthCell: KVKCollectionViewCell {
    
    var customViewFrame: CGRect {
        let customY = dateLabel.frame.origin.y + dateLabel.frame.height + 3
        return CGRect(x: 0, y: customY, width: frame.width, height: frame.height - customY)
    }
    
    private let titlesCount = 3
    private let countInCell: CGFloat = 4
    private let offset: CGFloat = 3
    private let defaultTagView = -1
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.clipsToBounds = true
        return label
    }()
    
    private func timeFormatter(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.timeSystem.format
        return formatter.string(from: date)
    }
    
    private var monthStyle = MonthStyle() {
        didSet {
            dateLabel.font = monthStyle.fontNameDate
        }
    }
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
    
    override var isHighlighted: Bool {
        didSet {
            guard style.month.isAnimateSelection else { return }
            
            setTappedState(isHighlighted)
        }
    }
    
    var style = Style() {
        didSet {
            monthStyle = style.month
            allDayStyle = style.allDay
        }
    }
    
    weak var delegate: MonthCellDelegate?
        
    var events: [Event] = [] {
        didSet {
            contentView.subviews.filter { $0.tag != defaultTagView }.forEach { $0.removeFromSuperview() }
            
            guard bounds.height > (dateLabel.bounds.height + 10) && day.type != .empty else {
                if monthStyle.showDatesForOtherMonths {
                    showMonthName(day: day)
                }
                return
            }
            
            if Platform.currentInterface == .phone && UIApplication.shared.orientation.isLandscape { return }
            
            if monthStyle.showMonthNameInFirstDay {
                showMonthName(day: day)
            }
            
            // using a custom view below the date label
            if let date = day.date, let customView = delegate?.dequeueViewEvents(events, date: date, frame: customViewFrame) {
                contentView.addSubview(customView)
                return
            }
            
            let height: CGFloat
            let items: [Event]
            
            if frame.height > 70 {
                items = events
                height = (frame.height - dateLabel.bounds.height - 5) / countInCell
            } else if let event = events.first {
                items = [event]
                height = (frame.height - dateLabel.bounds.height - 5)
            } else {
                items = []
                height = (frame.height - dateLabel.bounds.height - 5)
            }
            
            for (idx, event) in items.enumerated() {
                let width = frame.width - 10
                let count = idx + 1
                let label = UILabel(frame: CGRect(x: 5,
                                                  y: 5 + dateLabel.bounds.height + height * CGFloat(idx),
                                                  width: width,
                                                  height: height))
                label.isUserInteractionEnabled = true
                
                if count > titlesCount {
                    label.font = monthStyle.fontEventTitle
                    label.lineBreakMode = .byTruncatingMiddle
                    label.adjustsFontSizeToFitWidth = true
                    label.minimumScaleFactor = 0.95
                    label.textAlignment = .center
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnMore))
                    label.tag = event.start.kvkDay
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
                        
                        if !text.isEmpty {
                            label.text = text
                            contentView.addSubview(label)
                        }
                    }
                    return
                } else {
                    if !event.isAllDay || Platform.currentInterface == .phone {
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
                        label.text = " \(event.title.timeline) "
                        label.setRoundCorners(monthStyle.eventCorners, radius: monthStyle.eventCornersRadius)
                    }
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(tapOneEvent))
                    label.addGestureRecognizer(tap)
                    label.tag = event.hash
                    
                    if style.event.states.contains(.move) && Platform.currentInterface != .phone && !event.isAllDay {
                        label.addGestureRecognizer(longGesture)
                        label.addGestureRecognizer(panGesture)
                    }
                    contentView.addSubview(label)
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
                    dateLabel.text = "\(tempDate.kvkDay)"
                    dateLabel.textColor = monthStyle.colorNameEmptyDay
                } else {
                    dateLabel.text = nil
                }
            default:
                if let tempDay = day.date?.kvkDay {
                    dateLabel.text = "\(tempDay)"
                } else {
                    dateLabel.text = nil
                }
            }

            if !monthStyle.isHiddenSeparator {
                switch Platform.currentInterface {
                case .phone:
                    let topLineLayer = CALayer()
                    topLineLayer.name = "line_layer"
                    
                    if monthStyle.isHiddenSeparatorOnEmptyDate && day.type == .empty {
                        layer.sublayers?.removeAll(where: { $0.name == "line_layer" })
                    } else {
                        topLineLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: monthStyle.widthSeparator)
                        topLineLayer.backgroundColor = monthStyle.colorSeparator.cgColor
                        layer.addSublayer(topLineLayer)
                    }
                default:
                    if day.type != .empty {
                        layer.borderWidth = monthStyle.isHiddenSeparatorOnEmptyDate ? 0 : monthStyle.widthSeparator
                        layer.borderColor = monthStyle.isHiddenSeparatorOnEmptyDate ? UIColor.clear.cgColor : monthStyle.colorSeparator.cgColor
                    } else {
                        layer.borderWidth = monthStyle.widthSeparator
                        layer.borderColor = monthStyle.colorSeparator.cgColor
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
            let newFrame = CGRect(x: location.x, y: location.y,
                                  width: gesture.view?.frame.width ?? 0,
                                  height: gesture.view?.frame.size.height ?? 0)
            delegate?.didSelectEvent(events[idx], frame: newFrame)
        }
    }
    
    @objc private func tapOnMore(gesture: UITapGestureRecognizer) {
        if let idx = events.firstIndex(where: { $0.start.kvkDay == gesture.view?.tag }) {
            let location = gesture.location(in: superview)
            let newFrame = CGRect(x: location.x, y: location.y,
                                  width: gesture.view?.frame.width ?? 0,
                                  height: gesture.view?.frame.size.height ?? 0)
            delegate?.didSelectMore(events[idx].start, frame: newFrame)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var dateFrame = frame
        if Platform.currentInterface != .phone {
            dateFrame.size = CGSize(width: 30, height: 30)
            dateFrame.origin.x = (frame.width - dateFrame.width) - offset
        } else {
            let newWidth = frame.width > 30 ? 30 : frame.width
            dateFrame.size = CGSize(width: newWidth, height: newWidth)
            dateFrame.origin.x = (frame.width / 2) - (dateFrame.width / 2)
        }
        dateFrame.origin.y = offset
        dateLabel.frame = dateFrame
        dateLabel.tag = defaultTagView
        contentView.addSubview(dateLabel)
                
        if #available(iOS 13.4, *) {
            contentView.addPointInteraction()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func showMonthName(day: Day) {
        let monthLabel = UILabel(frame: CGRect(x: dateLabel.frame.origin.x - 50,
                                               y: dateLabel.frame.origin.y,
                                               width: 50,
                                               height: dateLabel.bounds.height))
        if let date = day.date, date.kvkDay == 1, Platform.currentInterface != .phone {
            monthLabel.textAlignment = .right
            monthLabel.textColor = dateLabel.textColor
            monthLabel.text = "\(date.titleForLocale(style.locale, formatter: monthStyle.shortInDayMonthFormatter))".capitalized
            contentView.addSubview(monthLabel)
        } else {
            monthLabel.removeFromSuperview()
        }
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
            guard let idx = events.firstIndex(where: { $0.hash == gesture.view?.tag }),
                  let view = gesture.view else { return }
            
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
            let snapshot = event.isAllDay ? view.snapshotView(afterScreenUpdates: false) : snapshotLabel
            let eventView = EventViewGeneral(style: style, event: event, frame: view.frame)
            delegate?.didStartMoveEvent(eventView, snapshot: snapshot, gesture: gesture)
        case .cancelled, .ended, .failed:
            delegate?.didEndMoveEvent(gesture: gesture)
        default:
            break
        }
    }
    
    private func populateCell(day: Day, label: UILabel, view: UIView) {
        let date = day.date
        let weekend = day.type == .saturday || day.type == .sunday || (date?.isWeekend == true)
        
        let nowDate = Date()
        label.backgroundColor = .clear
        
        var textColorForEmptyDay: UIColor?
        if day.type == .empty {
            textColorForEmptyDay = monthStyle.colorNameEmptyDay
        }
        
        if weekend {
            switch Platform.currentInterface {
            case .phone where day.type == .empty:
                view.backgroundColor = UIColor.clear
            default:
                view.backgroundColor = monthStyle.colorBackgroundWeekendDate
            }
            
            label.textColor = textColorForEmptyDay ?? monthStyle.colorWeekendDate
        } else {
            view.backgroundColor = monthStyle.colorBackgroundDate
            label.textColor = textColorForEmptyDay ?? monthStyle.colorDate
        }
        
        guard day.type != .empty else { return }
        
        guard date?.kvkYear == nowDate.kvkYear else {
            if date?.kvkIsEqual(selectDate) == true {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.kvkMonth == nowDate.kvkMonth else {
            if selectDate.kvkDay == date?.kvkDay && selectDate.kvkMonth == date?.kvkMonth {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.kvkDay == nowDate.kvkDay else {
            if selectDate.kvkDay == date?.kvkDay && date?.kvkMonth == selectDate.kvkMonth {
                label.textColor = monthStyle.colorSelectDate
                label.backgroundColor = monthStyle.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard selectDate.kvkDay == date?.kvkDay && selectDate.kvkMonth == date?.kvkMonth else {
            if date?.kvkDay == nowDate.kvkDay {
                label.textColor = monthStyle.colorTitleCurrentDate
                label.backgroundColor = .clear
            }
            return
        }
        
        label.textColor = monthStyle.colorCurrentDate
        label.backgroundColor = monthStyle.colorBackgroundCurrentDate
        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true
    }
    
    private func addIconBeforeLabel(eventList: [Event],
                                    textAttributes: [NSAttributedString.Key: Any],
                                    bulletAttributes: [NSAttributedString.Key: Any],
                                    timeAttributes: [NSAttributedString.Key: Any],
                                    bullet: String = "\u{2022}",
                                    indentation: CGFloat = 10,
                                    lineSpacing: CGFloat = 2,
                                    paragraphSpacing: CGFloat = 10) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = Platform.currentInterface != .phone ? .left : .center
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: [:])]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        
        return eventList.reduce(NSMutableAttributedString()) { (_, event) -> NSMutableAttributedString in
            let text: String
            if monthStyle.isHiddenEventTitle {
                text = ""
            } else {
                text = event.title.month ?? ""
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
            attributedString.addAttributes([.paragraphStyle: paragraphStyle], range: rangeForText)
            attributedString.addAttributes(textAttributes, range: rangeForText)
            
            if !monthStyle.isHiddenDotInTitle {
                let rangeForBullet = string.range(of: bullet)
                attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            }
            
            return attributedString
        }
    }
    
    override func setSkeletons(_ skeletons: Bool,
                               insets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4),
                               cornerRadius: CGFloat = 2) {
        dateLabel.isHidden = skeletons
        
        let stubView = UIView(frame: bounds)
        if skeletons {
            contentView.subviews.filter { $0.tag != defaultTagView }.forEach { $0.removeFromSuperview() }
            contentView.addSubview(stubView)
            stubView.setAsSkeleton(skeletons, cornerRadius: cornerRadius, insets: insets)
        } else {
            stubView.removeFromSuperview()
        }
    }
    
}

extension MonthCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

protocol MonthCellDelegate: AnyObject {
    
    func didSelectEvent(_ event: Event, frame: CGRect?)
    func didSelectMore(_ date: Date, frame: CGRect?)
    func didStartMoveEvent(_ event: EventViewGeneral, snapshot: UIView?, gesture: UILongPressGestureRecognizer)
    func didEndMoveEvent(gesture: UILongPressGestureRecognizer)
    func didChangeMoveEvent(gesture: UIPanGestureRecognizer)
    func dequeueViewEvents(_ events: [Event], date: Date, frame: CGRect) -> UIView?
    
}

#endif
