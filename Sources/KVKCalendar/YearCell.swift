//
//  YearCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class YearCell: UICollectionViewCell {
    private let daysInWeek = 7
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.3
        return label
    }()
    
    private var topHeight: CGFloat {
        switch Platform.currentInterface {
        case .phone:
            return 15
        default:
            return 30
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard style.year.isAnimateSelection else { return }
            
            setTappedState(isHighlighted)
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var style = Style() {
        didSet {
            titleLabel.font = style.year.fontTitle
            titleLabel.textColor = style.year.colorTitle
            
            subviews.filter({ $0 is WeekHeaderView }).forEach({ $0.removeFromSuperview() })
            let view = WeekHeaderView(parameters: .init(style: style, isFromYear: true),
                                      frame: CGRect(x: 0, y: topHeight + 5,
                                                    width: frame.width, height: topHeight))
            addSubview(view)
        }
    }
    
    var date: Date? {
        didSet {
            guard Date().month == date?.month && Date().year == date?.year else {
                titleLabel.textColor = style.year.colorTitle
                return
            }
            
            titleLabel.textColor = .systemRed
        }
    }
    
    var days: [Day] = [] {
        didSet {
            subviews.filter({ $0.tag == 1 }).forEach({ $0.removeFromSuperview() })
            var step = 0
            let weekCount = ceil((CGFloat(days.count) / CGFloat(daysInWeek)))
            Array(1...Int(weekCount)).forEach { idx in
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
        titleLabel.frame = CGRect(x: 3, y: 0, width: frame.width - 6, height: topHeight)
        addSubview(titleLabel)
        
        if #available(iOS 13.4, *) {
            addPointInteraction(on: self, delegate: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addDayToLabel(days: ArraySlice<Day>, step: Int) {
        let width = frame.width / CGFloat(daysInWeek)
        let newY: CGFloat = (topHeight * 2) + 10
        let height: CGFloat = (frame.height - newY) / CGFloat(daysInWeek - 1)
        
        for (idx, day) in days.enumerated() where day.type != .empty {
            let frame = CGRect(x: width * CGFloat(idx),
                               y: newY + (CGFloat(step - 1) * height),
                               width: width,
                               height: height)
            
            let view = UIView(frame: frame)
            let size: CGFloat
            let pointX: CGFloat
            if frame.height > frame.width {
                size = frame.width
                pointX = 0
            } else {
                pointX = (frame.width - frame.height) / 2
                size = frame.height
            }
            let label = UILabel(frame: CGRect(x: pointX,
                                              y: 0,
                                              width: size,
                                              height: size))
            label.textAlignment = .center
            label.font = style.year.fontDayTitle
            label.textColor = style.year.colorDayTitle
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            if let tempDay = day.date?.day {
                label.text = "\(tempDay)"
            } else {
                label.text = nil
            }
            
            view.tag = 1
            weekendsDays(day: day, label: label, view: view)
            addSubview(view)
            view.addSubview(label)
        }
    }
    
    private func weekendsDays(day: Day, label: UILabel, view: UIView) {
        guard day.type == .saturday || day.type == .sunday else {
            isNowDate(date: day.date, weekend: false, label: label, view: view)
            return
        }
        isNowDate(date: day.date, weekend: true, label: label, view: view)
    }
    
    private func isNowDate(date: Date?, weekend: Bool, label: UILabel, view: UIView) {
        let nowDate = Date()
        
        if weekend {
            label.textColor = style.year.colorWeekendDate
            view.backgroundColor = style.year.colorBackgroundWeekendDate
        }
        
        guard date?.year == nowDate.year else {
            if date?.year == selectDate.year && date?.month == selectDate.month && date?.day == selectDate.day {
                label.textColor = style.year.colorSelectDate
                label.backgroundColor = style.year.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.month == nowDate.month else {
            if selectDate.day == date?.day && selectDate.month == date?.month {
                label.textColor = style.year.colorSelectDate
                label.backgroundColor = style.year.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        
        guard date?.day == nowDate.day else {
            if selectDate.day == date?.day && date?.month == selectDate.month {
                label.textColor = style.year.colorSelectDate
                label.backgroundColor = style.year.colorBackgroundSelectDate
                label.layer.cornerRadius = label.frame.height / 2
                label.clipsToBounds = true
            }
            return
        }
        guard selectDate.day == date?.day && selectDate.month == date?.month else {
            if date?.day == nowDate.day {
                label.textColor = style.year.colorBackgroundCurrentDate
                label.backgroundColor = .clear
            }
            return
        }
        label.textColor = style.year.colorCurrentDate
        label.backgroundColor = style.year.colorBackgroundCurrentDate
        label.layer.cornerRadius = label.frame.height / 2
        label.clipsToBounds = true
    }
}

@available(iOS 13.4, *)
extension YearCell: PointerInteractionProtocol {
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .hover(targetedPreview))
        }
        return pointerStyle
    }
    
}

#endif
