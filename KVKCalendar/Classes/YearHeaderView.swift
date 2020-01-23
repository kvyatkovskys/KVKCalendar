//
//  YearHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 03/01/2019.
//

import UIKit

final class YearHeaderView: UIView {
    static let identifier = #file
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        return label
    }()
    
    var date: Date? {
        didSet {
            if let date = date {
                titleLabel.text = style.year.formatter.string(from: date)
            }
        }
    }
    
    var style: Style = Style() {
        didSet {
            titleLabel.textColor = style.year.colorTitleHeader
            titleLabel.font = style.year.fontTitleHeader
            titleLabel.textAlignment = style.year.aligmentTitleHeader
            
            backgroundColor = style.year.colorBackgroundHeader
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.frame = frame
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension YearHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width
        titleLabel.frame.size.width = frame.width
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
}
