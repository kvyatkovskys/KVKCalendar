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
    
    init(parameters: Parameters, frame: CGRect = .zero) {
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
        timeLabel.textColor = style.timeline.currentLineHourColor
        timeLabel.font = style.timeline.currentLineHourFont

//        timeLabel.frame = CGRect(x: 0, y: 0,
//                                 width: style.timeline.currentLineHourWidth,
//                                 height: frame.height)
//        dotView.frame = CGRect(x: leftOffsetWithAdditionalTime - (style.timeline.currentLineHourDotSize.width * 0.5),
//                               y: (frame.height * 0.5) - 2,
//                               width: style.timeline.currentLineHourDotSize.width,
//                               height: style.timeline.currentLineHourDotSize.height)
//        lineView.frame = CGRect(x: dotView.frame.origin.x,
//                                y: frame.height * 0.5,
//                                width: frame.width - frame.origin.x,
//                                height: style.timeline.currentLineHourHeight)
        [timeLabel, lineView, dotView].forEach { addSubview($0) }
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        dotView.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingTime = timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        let topTime = timeLabel.topAnchor.constraint(equalTo: topAnchor)
        let bottomTime = timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        let widthTime = timeLabel.widthAnchor.constraint(equalToConstant: style.timeline.currentLineHourWidth)
        NSLayoutConstraint.activate([leadingTime, topTime, bottomTime, widthTime])
        
        let dotWidth = dotView.widthAnchor.constraint(equalToConstant: style.timeline.currentLineHourDotSize.width)
        let dotHeight = dotView.heightAnchor.constraint(equalToConstant: style.timeline.currentLineHourDotSize.height)
        let dotCenterY = dotView.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor)
        let dotLeading = dotView.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 1)
        NSLayoutConstraint.activate([dotWidth, dotHeight, dotCenterY, dotLeading])
        
        let heightLine = lineView.heightAnchor.constraint(equalToConstant: style.timeline.currentLineHourHeight)
        let leadingLine = lineView.leadingAnchor.constraint(equalTo: dotView.trailingAnchor)
        let trailingLine = lineView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let centerYLine = lineView.centerYAnchor.constraint(equalTo: dotView.centerYAnchor)
        NSLayoutConstraint.activate([heightLine, leadingLine, trailingLine, centerYLine])
        
        isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dotView.setRoundCorners(radius: style.timeline.currentLineHourDotCornersRadius)
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
