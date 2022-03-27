//
//  ScrollDayHeaderReusableView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 3/27/22.
//

import UIKit

final class ScrollDayHeaderReusableView: UICollectionReusableView {
        
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
    
}
