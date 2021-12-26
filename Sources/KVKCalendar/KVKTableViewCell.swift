//
//  KVKTableViewCell.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 30.10.2021.
//

#if os(iOS)

import UIKit

class KVKTableViewCell: UITableViewCell {

    var isSkeleton: Bool = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSkeletons(_ skeletons: Bool,
                      insets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4),
                      cornerRadius: CGFloat = 2)
    {
        isSkeleton = skeletons
        isUserInteractionEnabled = !skeletons
        contentView.subviews.forEach { $0.setAsSkeleton(skeletons, cornerRadius: cornerRadius, insets: insets) }
    }
    
}

#endif
