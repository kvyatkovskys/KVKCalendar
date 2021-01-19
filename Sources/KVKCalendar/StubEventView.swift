//
//  StubEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 04.10.2020.
//

import UIKit

final class StubEventView: UIView {
    var valueHash: Int?
    
    private let color: UIColor
    
    init(event: Event, frame: CGRect) {
        self.color = Event.Color(event.color?.value ?? event.backgroundColor).value
        super.init(frame: frame)
        backgroundColor = event.backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.interpolationQuality = .none
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2)
        let x: CGFloat = 1
        let y: CGFloat = 0
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: bounds.height))
        context.strokePath()
        context.restoreGState()
    }
}
