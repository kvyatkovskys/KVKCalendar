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
    
    private let formatter: DateFormatter = {
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
        
        lineView.backgroundColor = style.timeline.currentLineHourStyle.style.currentLineColor
        timeLabel.font = style.timeline.currentLineHourStyle.style.currentLineTimeFont
        
        timeLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: style.timeline.currentLineHourStyle.style.currentLineTimeWidth,
            height: frame.height
        )
        switch style.timeline.currentLineHourStyle {
        case .old(let item):
            formatter.dateFormat = style.timeSystem.format
            dotView.backgroundColor = lineView.backgroundColor
            timeLabel.textColor = dotView.backgroundColor
            
            dotView.frame = CGRect(
                x: leftOffsetWithAdditionalTime - (item.currentLineDotCornersRadius.width * 0.5),
                y: (frame.height * 0.5) - 2,
                width: item.currentLineTimeDotSize.width,
                height: item.currentLineTimeDotSize.height
            )
            lineView.frame = CGRect(
                x: dotView.frame.origin.x,
                y: frame.height * 0.5,
                width: frame.width - frame.origin.x,
                height: style.timeline.currentLineHourStyle.style.currentLineHeight
            )
            
            [timeLabel, lineView, dotView].forEach({ addSubview($0) })
            dotView.setRoundCorners(radius: item.currentLineDotCornersRadius)
        case .custom(let item):
            formatter.dateFormat = style.timeSystem.formatWithoutSymbols
            formatter.amSymbol = nil
            formatter.pmSymbol = nil
            timeLabel.backgroundColor = lineView.backgroundColor
            timeLabel.textColor = item.currentLineTimeColor
            
            lineView.frame = CGRect(
                x: timeLabel.frame.origin.x + timeLabel.frame.width,
                y: frame.height * 0.5,
                width: frame.width - frame.origin.x,
                height: style.timeline.currentLineHourStyle.style.currentLineHeight
            )
            
            [timeLabel, lineView].forEach({ addSubview($0) })
            timeLabel.setRoundCorners(radius: item.currentLineTimeCornersRadius)
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
    }
}

#endif
