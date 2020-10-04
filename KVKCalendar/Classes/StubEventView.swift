//
//  StubEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 04.10.2020.
//

import UIKit

final class StubEventView: UIView {
    var valueHash: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
