//
//  EventViewer.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 04/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

final class EventViewer: UIView {
    fileprivate let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Select event to view the description"
        return label
    }()
    
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        textLabel.frame = frame
        addSubview(textLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
