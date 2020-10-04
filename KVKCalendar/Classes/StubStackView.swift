//
//  StubStackView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 04.10.2020.
//

import UIKit

final class StubStackView: UIStackView {
    enum PositionType: Int {
        case top, bottom
    }
    
    var type: PositionType
    var day: Int
    
    init(type: PositionType, frame: CGRect, day: Int) {
        self.type = type
        self.day = day
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
