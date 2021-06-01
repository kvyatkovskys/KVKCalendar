//
//  CurrentLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.08.2020.
//

import UIKit

final class CurrentLineView: UIView {
    
    private var style: Style

    private let timeLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.valueHash = Date().minute.hashValue
        return label
    }()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        return formatter
    }()
    
    private let lineView = UIView()
    private let dotView = UIView()
    
    var valueHash: Int?
    
    var time: String? {
        didSet {
            timeLabel.text = time
        }
    }
    
    var date: Date?
    
    init(style: Style, frame: CGRect) {
        self.style = style
        super.init(frame: frame)
        
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CurrentLineView: CalendarSettingProtocol {
    
    var currentStyle: Style {
        style
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        lineView.backgroundColor = style.timeline.currentLineHourColor
        dotView.backgroundColor = style.timeline.currentLineHourColor
        
        formatter.dateFormat = style.timeSystem.format
        formatter.timeZone = style.timezone
        formatter.locale = style.locale
        
        timeLabel.textColor = style.timeline.currentLineHourColor
        timeLabel.font = style.timeline.currentLineHourFont
        timeLabel.text = formatter.string(from: Date())
        timeLabel.valueHash = Date().minute.hashValue
        
        timeLabel.frame = CGRect(x: 2, y: 0, width: style.timeline.currentLineHourWidth - 5, height: frame.height)
        dotView.frame = CGRect(origin: CGPoint(x: style.timeline.currentLineHourWidth - (style.timeline.currentLineHourDotSize.width * 0.5), y: (frame.height * 0.5) - 2), size: style.timeline.currentLineHourDotSize)
        lineView.frame = CGRect(x: style.timeline.currentLineHourWidth, y: frame.height * 0.5, width: frame.width - style.timeline.currentLineHourWidth, height: style.timeline.currentLineHourHeight)
        [timeLabel, lineView, dotView].forEach({ addSubview($0) })
        dotView.setRoundCorners(radius: style.timeline.currentLineHourDotCornersRadius)
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        setUI()
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        lineView.frame.size.width = frame.width
    }
}
