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
        label.minimumScaleFactor = 0.6
        label.hashTime = Date().minute
        return label
    }()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
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
            timeLabel.hashTime = date.minute
        }
    }
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CurrentLineView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            parameters.style
        }
        set {
            parameters.style = newValue
        }
    }
    
    func setUI(reload: Bool = false) {
        subviews.forEach({ $0.removeFromSuperview() })
        
        lineView.backgroundColor = style.timeline.currentLineHourColor
        dotView.backgroundColor = style.timeline.currentLineHourColor
        
        formatter.dateFormat = style.timeSystem.format
        formatter.timeZone = style.timezone
        formatter.locale = style.locale
        
        timeLabel.textColor = style.timeline.currentLineHourColor
        timeLabel.font = style.timeline.currentLineHourFont
                
        timeLabel.frame = CGRect(x: 2, y: 0, width: style.timeline.currentLineHourWidth - 5, height: frame.height)
        dotView.frame = CGRect(origin: CGPoint(x: style.timeline.currentLineHourWidth - (style.timeline.currentLineHourDotSize.width * 0.5),
                                               y: (frame.height * 0.5) - 2),
                               size: style.timeline.currentLineHourDotSize)
        lineView.frame = CGRect(x: style.timeline.currentLineHourWidth,
                                y: frame.height * 0.5,
                                width: frame.width - style.timeline.currentLineHourWidth,
                                height: style.timeline.currentLineHourHeight)
        [timeLabel, lineView, dotView].forEach({ addSubview($0) })
        dotView.setRoundCorners(radius: style.timeline.currentLineHourDotCornersRadius)
        isHidden = true
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
        date = Date()
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        lineView.frame.origin.x = style.timeline.currentLineHourWidth
        lineView.frame.size.width = frame.width - style.timeline.currentLineHourWidth
    }
}

#endif
