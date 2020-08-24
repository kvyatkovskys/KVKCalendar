//
//  VerticalLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.08.2020.
//

import UIKit

final class VerticalLineView: UIView {
    var date: Date?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
