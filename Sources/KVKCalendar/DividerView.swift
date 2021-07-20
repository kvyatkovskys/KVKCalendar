//
//  DividerView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 18.07.2021.
//

import UIKit

final class DividerView: UIView {
    
    private var style: Style
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = style.timeline.timeDividerColor
        label.font = style.timeline.timeDividerFont
        label.textAlignment = .right
        return label
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = style.timeline.timeDividerColor
        return view
    }()
    
    var txt: String? {
        didSet {
            timeLabel.text = txt
        }
    }
    
    init(style: Style, frame: CGRect) {
        self.style = style
        super.init(frame: frame)

        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension DividerView: CalendarSettingProtocol {
    
    var currentStyle: Style {
        style
    }
    
    func reloadFrame(_ frame: CGRect) {
        subviews.forEach({ $0.removeFromSuperview() })
        self.frame = frame
        setUI()
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
    
    func setUI() {
        timeLabel.frame = CGRect(x: style.timeline.offsetTimeX,
                                 y: 0,
                                 width: style.timeline.widthTime,
                                 height: style.timeline.heightTime)
        
        let xLine = timeLabel.bounds.width + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        lineView.frame = CGRect(x: xLine,
                                y: timeLabel.center.y,
                                width: bounds.width - xLine,
                                height: style.timeline.heightLine)
        
        [timeLabel, lineView].forEach({ addSubview($0) })
    }

}
