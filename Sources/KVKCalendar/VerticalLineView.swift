//
//  VerticalLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.08.2020.
//

#if os(iOS)

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

final class VerticalLineLayer: CAShapeLayer {
    let date: Date?
    let lineFrame: CGRect
    
    init(date: Date? = nil, frame: CGRect, tag: Int, start: CGPoint, end: CGPoint, color: UIColor, width: CGFloat) {
        self.date = date
        self.lineFrame = frame
        super.init()
        
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        path = linePath.cgPath
        lineWidth = width
        fillColor = nil
        opacity = 1.0
        strokeColor = color.cgColor
        name = "\(tag)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

#endif
