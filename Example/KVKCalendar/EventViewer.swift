//
//  EventViewer.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 04/01/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

final class EventViewer: UIView {
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Select event to view the description"
        return label
    }()
    
    private let lineView: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGray3
        } else {
            view.backgroundColor = .lightGray
        }
        return view
    }()
    
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }
        addSubview(textLabel)
        addSubview(lineView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadFrame(frame: CGRect) {
        textLabel.frame = frame
        lineView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: frame.height))
    }
}
