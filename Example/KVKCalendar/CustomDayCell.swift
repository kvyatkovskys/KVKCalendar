//
//  CustomDayCell.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 02.10.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

final class CustomDayCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = CGRect(origin: .zero, size: frame.size)
        contentView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
