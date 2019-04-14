//
//  YearHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 03/01/2019.
//

import UIKit

final class YearHeaderView: UIView {
    static let identifier = #file
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        return label
    }()
    
    var date: Date? {
        didSet {
            if let date = date {
                titleLabel.text = style.yearStyle.formatter.string(from: date)
            }
        }
    }
    
    var style: Style = Style() {
        didSet {
            titleLabel.textColor = style.yearStyle.colorTitleHeader
            titleLabel.font = style.yearStyle.fontTitleHeader
            titleLabel.textAlignment = style.yearStyle.aligmentTitleHeader
            
            backgroundColor = style.yearStyle.colorBackgroundHeader
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

extension YearHeaderView: CalendarFrameDelegate {
    func reloadFrame(frame: CGRect) {
        self.frame.size.width = frame.width
        titleLabel.frame.size.width = frame.width
    }
    
}
