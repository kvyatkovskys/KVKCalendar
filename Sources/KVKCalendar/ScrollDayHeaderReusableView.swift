//
//  ScrollDayHeaderReusableView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 3/27/22.
//

import UIKit

final class ScrollDayHeaderReusableView: UIView {
        
    var style: Style? {
        didSet {
            if let item = style {
                titleLabel.textAlignment = item.headerScroll.titleDateAlignment
                titleLabel.textColor = item.headerScroll.colorTitleDate
                titleLabel.font = item.headerScroll.titleDateFont
            }
        }
    }
    
    var date: Date? {
        didSet {
            if let dt = date, let item = style {
                titleLabel.text = dt.titleForLocale(item.locale, formatter: item.headerScroll.titleFormatter)
            }
        }
    }
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.frame = frame
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func animateTitleIfNeeded() {
        if style?.headerScroll.isAnimateTitleDate == true {
//            let value: CGFloat
//            if offset < 0 {
//                value = -40
//            } else {
//                value = 40
//            }
//            titleLabel.transform = CGAffineTransform(translationX: value, y: 0)
//            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
//                self.titleLabel.transform = CGAffineTransform.identity
//            })
        }
    }
    
}
