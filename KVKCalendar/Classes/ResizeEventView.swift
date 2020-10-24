//
//  ResizeEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.10.2020.
//

import UIKit

final class ResizeEventView: UIView {
    
    private enum ResizeEventViewType: Int {
        case top, bottom
        
        var tag: Int {
            return rawValue
        }
    }
    
    weak var delegate: ResizeEventViewDelegate?
    
    private let event: Event
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(trackGesture))
        return gesture
    }()
    
    private lazy var topView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 6, height: 6)))
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = event.color?.value.cgColor ?? event.backgroundColor.cgColor
        view.setRoundCorners(radius: CGSize(width: 3, height: 3))
        view.tag = ResizeEventViewType.top.tag
        view.addGestureRecognizer(panGesture)
        return view
    }()
    
    init(eventView: UIView, event: Event, frame: CGRect) {
        self.event = event
        var newFrame = frame
        newFrame.origin.y -= 3
        newFrame.size.height += 3
        super.init(frame: newFrame)
        
        eventView.frame = CGRect(origin: CGPoint(x: 0, y: 3), size: frame.size)
        addSubview(eventView)
        
        topView.frame.origin = CGPoint(x: frame.width * 0.7, y: 0)
        addSubview(topView)
    }
    
    @objc private func trackGesture(gesture: UIPanGestureRecognizer) {
        guard let tag = gesture.view?.tag, let type = ResizeEventViewType(rawValue: tag) else { return }
        
        switch type {
        case .top:
            switch gesture.state {
            case .changed:
                delegate?.didStart(gesture: gesture)
            case .cancelled, .failed, .ended:
                delegate?.didEnd(gesture: gesture)
            default:
                break
            }
        case .bottom:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol ResizeEventViewDelegate: class {
    func didStart(gesture: UIPanGestureRecognizer)
    func didEnd(gesture: UIPanGestureRecognizer)
}
