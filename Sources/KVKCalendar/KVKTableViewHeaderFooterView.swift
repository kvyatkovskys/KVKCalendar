//
//  KVKTableViewHeaderFooterView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 31.10.2021.
//

#if os(iOS)

import UIKit

class KVKTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    var isSkeleton: Bool = false

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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
