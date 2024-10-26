//
//  CurrentLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.08.2020.
//

#if os(iOS)

import UIKit

final class CurrentLineView: UIView {
    
    struct Parameters {
        var style: Style
        var type: KVKCalendar.CalendarType
    }
    
    private var parameters: Parameters

    private let timeLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.4
        label.hashTime = Date().kvkMinute
        return label
    }()
    
    private var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    private let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let lineView = UIView()
    private let boldLineView = UIView()
    private let dotView = UIView()
    
    var valueHash: Int?
        
    var date: Date = Date() {
        didSet {
            if isHidden {
                isHidden = false
            }
            timeLabel.text = formatter.string(from: date)
            timeLabel.hashTime = date.kvkMinute
        }
    }
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        super.init(frame: frame)
        isUserInteractionEnabled = false
        formatter.locale = style.locale
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CurrentLineView: CalendarSettingProtocol {
    
    var style: Style {
        get { parameters.style }
        set { parameters.style = newValue }
    }
    
    func setUI(reload: Bool = false) {
        subviews.forEach({ $0.removeFromSuperview() })
        
        timeLabel.font = style.timeline.currentLineHourStyle.style.timeFont
        timeLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: style.timeline.currentLineHourStyle.style.timeWidth,
            height: frame.height
        )
        switch style.timeline.currentLineHourStyle {
        case .old(let item):
            lineView.backgroundColor = item.lineColor
            if let timeFormatter = item.dateFormatter {
                formatter = timeFormatter
            } else {
                formatter.dateFormat = style.timeSystem.format
            }
            dotView.backgroundColor = lineView.backgroundColor
            timeLabel.textColor = dotView.backgroundColor
            
            dotView.frame = CGRect(
                x: leftOffsetWithAdditionalTime - (item.dotCornersRadius.width * 0.5),
                y: (frame.height * 0.5) - 2,
                width: item.timeDotSize.width,
                height: item.timeDotSize.height
            )
            lineView.frame = CGRect(
                x: dotView.frame.origin.x,
                y: frame.height * 0.5,
                width: frame.width - frame.origin.x,
                height: style.timeline.currentLineHourStyle.style.lineHeight
            )
            
            [timeLabel, lineView, dotView].forEach({ addSubview($0) })
            dotView.setRoundCorners(radius: item.dotCornersRadius)
        case .custom(let item):
            if let timeFormatter = item.dateFormatter {
                formatter = timeFormatter
            } else {
                formatter.dateFormat = style.timeSystem.formatWithoutSymbols
            }
            timeLabel.backgroundColor = item.lineColor
            timeLabel.textColor = item.timeColor
            
            let lineHeight: CGFloat
            if parameters.type == .week {
                lineHeight = style.timeline.currentLineHourStyle.style.lineHeight * 0.5
            } else {
                lineHeight = style.timeline.currentLineHourStyle.style.lineHeight
            }
            setLineViewColor()
            lineView.frame = CGRect(
                x: timeLabel.frame.width,
                y: frame.height * 0.5,
                width: frame.width - frame.origin.x,
                height: lineHeight
            )
            
            [timeLabel, lineView].forEach({ addSubview($0) })
            timeLabel.setRoundCorners(radius: item.timeCornersRadius)
        }
        
        switch style.timeline.currentLineHourStyle.style.lineHourStyle {
        case .withTime:
            timeLabel.isHidden = false
        case .onlyLine:
            timeLabel.isHidden = true
        }
        isHidden = true
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
        date = Date()
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        self.frame.origin.x = frame.origin.x
    }
    
    func setOffsetForTime(_ offset: CGFloat) {
        timeLabel.frame.origin.x = offset
        lineView.frame.origin.x = offset + timeLabel.frame.width
    }
    
    func setLineWidth(_ width: CGFloat, offset: CGFloat?) {
        guard let offset, parameters.type == .week else { return }
        
        dotView.frame = CGRect(
            x: offset - style.timeline.currentLineHourStyle.style.dotCornersRadius.width,
            y: (frame.height * 0.5) - 2,
            width: style.timeline.currentLineHourStyle.style.timeDotSize.width,
            height: style.timeline.currentLineHourStyle.style.timeDotSize.height
        )
        boldLineView.frame = CGRect(
            x: offset,
            y: lineView.frame.origin.y,
            width: width,
            height: style.timeline.currentLineHourStyle.style.lineHeight
        )
        dotView.backgroundColor = style.timeline.currentLineHourStyle.style.lineColor
        boldLineView.backgroundColor = dotView.backgroundColor
        [boldLineView, dotView].forEach(addSubview(_:))
        dotView.setRoundCorners(radius: style.timeline.currentLineHourStyle.style.dotCornersRadius)
    }
    
    // MARK: Private-
    private func setLineViewColor() {
        let lineColor = style.timeline.currentLineHourStyle.style.lineColor
        if date.kvkIsEqual(Date()) && parameters.type == .day {
            lineView.backgroundColor = lineColor
        } else {
            lineView.backgroundColor = lineColor.withAlphaComponent(0.2)
        }
    }
}

#endif
