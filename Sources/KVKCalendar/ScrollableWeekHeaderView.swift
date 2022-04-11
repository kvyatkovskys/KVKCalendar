//
//  ScrollableWeekHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 3/27/22.
//

#if os(iOS)

import UIKit

final class ScrollableWeekHeaderView: UIView {
        
    var style: Style? {
        didSet {
            if let item = style {
                titleLabel.textAlignment = item.headerScroll.titleDateAlignment
                titleLabel.textColor = item.headerScroll.titleDateColor
                titleLabel.font = item.headerScroll.titleDateFont
            }
        }
    }
    
    var date: Date? {
        didSet {
            if let dt = date, let item = style {
                titleLabel.text = dt.titleForLocale(item.locale, formatter: item.headerScroll.titleFormatter)
                if let oldDate = oldValue {
                    animateTitleIfNeeded(isPreviousDate: dt < oldDate)
                }
            }
        }
    }
    
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.frame = frame
        titleLabel.frame.origin = .zero
        addSubview(titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func animateTitleIfNeeded(isPreviousDate: Bool) {
        if style?.headerScroll.isAnimateTitleDate == true {
            let value: CGFloat
            if isPreviousDate {
                value = -40
            } else {
                value = 40
            }
            titleLabel.transform = CGAffineTransform(translationX: value, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.titleLabel.transform = CGAffineTransform.identity
            })
        }
    }
    
}

#endif
