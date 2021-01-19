//
//  CurrentLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 22.08.2020.
//

import UIKit

final class CurrentLineView: UIView {
    
    private let style: Style
    private let timeHourSystem: TimeHourSystem

    private lazy var timeLabel: TimelineLabel = {
        let label = TimelineLabel()
        label.textColor = style.timeline.currentLineHourColor
        label.textAlignment = .center
        label.font = style.timeline.currentLineHourFont
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        
        let formatter = DateFormatter()
        formatter.dateFormat = timeHourSystem.format
        formatter.timeZone = style.timezone
        label.text = formatter.string(from: Date())
        label.valueHash = Date().minute.hashValue
        return label
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = style.timeline.currentLineHourColor
        return view
    }()
    
    private lazy var dotView: UIView = {
        let view = UIView()
        view.backgroundColor = style.timeline.currentLineHourColor
        return view
    }()
    
    var valueHash: Int?
    
    var time: String? {
        didSet {
            timeLabel.text = time
        }
    }
    
    var date: Date?
    
    init(style: Style, frame: CGRect, timeHourSystem: TimeHourSystem) {
        self.style = style
        self.timeHourSystem = timeHourSystem
        super.init(frame: frame)
        
        timeLabel.frame = CGRect(x: 2, y: 0, width: style.timeline.currentLineHourWidth - 5, height: frame.height)
        dotView.frame = CGRect(origin: CGPoint(x: style.timeline.currentLineHourWidth - (style.timeline.currentLineHourDotSize.width * 0.5), y: (frame.height * 0.5) - 2), size: style.timeline.currentLineHourDotSize)
        lineView.frame = CGRect(x: style.timeline.currentLineHourWidth, y: frame.height * 0.5, width: frame.width - style.timeline.currentLineHourWidth, height: style.timeline.currentLineHourHeight)
        [timeLabel, lineView, dotView].forEach({ addSubview($0) })
        dotView.setRoundCorners(radius: style.timeline.currentLineHourDotCornersRadius)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CurrentLineView: CalendarSettingProtocol {
    func updateStyle(_ style: Style) {
        
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        lineView.frame.size.width = frame.width
    }
}
