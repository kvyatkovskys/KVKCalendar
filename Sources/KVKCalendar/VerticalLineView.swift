//
//  VerticalLineView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.08.2020.
//

#if os(iOS)

import UIKit

final class VerticalLineView: UIView {
    private let date: Date
    private let color: UIColor
    private let width: CGFloat
    
    init(date: Date, color: UIColor, width: CGFloat, frame: CGRect = .zero) {
        self.date = date
        self.color = color
        self.width = width
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let line = VerticalLineLayer(date: date,
                                     frame: frame,
                                     tag: tag,
                                     start: .zero,
                                     end: CGPoint(x: 0, y: bounds.height),
                                     color: color,
                                     width: width)
        layer.addSublayer(line)
    }
}

final class VerticalLineLayer: CAShapeLayer {
    let date: Date?
    let lineFrame: CGRect

    override init(layer: Any) {
        date = nil
        lineFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        super.init(layer: layer)
    }
    
    init(date: Date? = nil,
         frame: CGRect = .zero,
         tag: Int,
         start: CGPoint = .zero,
         end: CGPoint = .zero,
         color: UIColor,
         width: CGFloat) {
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
