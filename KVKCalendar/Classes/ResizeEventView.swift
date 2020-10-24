//
//  ResizeEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.10.2020.
//

import UIKit

final class ResizeEventView: UIView {
    
    enum ResizeEventViewType: Int {
        case top, bottom
        
        var tag: Int {
            return rawValue
        }
    }
    
    weak var delegate: ResizeEventViewDelegate?
    
    private let event: Event
    
    lazy var eventView: UIView = {
        let view = UIView()
        view.backgroundColor = event.color?.value ?? event.backgroundColor
        return view
    }()
    lazy var topView = createPanView(type: .top)
    lazy var bottomView = createPanView(type: .bottom)
    
    private func createPanView(type: ResizeEventViewType) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 80, height: 80)))
        view.backgroundColor = .white
        view.layer.borderWidth = 1
        view.layer.borderColor = event.color?.value.cgColor ?? event.backgroundColor.cgColor
        view.setRoundCorners(radius: CGSize(width: 4, height: 4))
        view.tag = type.tag
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(trackGesture))
        view.addGestureRecognizer(gesture)

        return view
    }
    
    init(view: UIView, event: Event, frame: CGRect) {
        self.event = event
        var newFrame = frame
        newFrame.origin.y -= 20
        newFrame.size.height += 40
        super.init(frame: newFrame)
        backgroundColor = .systemRed
        
        eventView.frame = CGRect(origin: CGPoint(x: 0, y: 20), size: CGSize(width: frame.width, height: frame.height))
        addSubview(eventView)
        
        view.frame = CGRect(origin: .zero, size: eventView.frame.size)
        eventView.addSubview(view)
        
        topView.frame.origin = CGPoint(x: frame.width * 0.7, y: 0)
        addSubview(topView)
        
        bottomView.frame.origin = CGPoint(x: frame.width * 0.3, y: frame.height)
        addSubview(bottomView)
    }
    
    @objc private func trackGesture(gesture: UIPanGestureRecognizer) {
        guard let tag = gesture.view?.tag, let type = ResizeEventViewType(rawValue: tag) else { return }
        
        switch type {
        case .top:
            switch gesture.state {
            case .changed:
                delegate?.didStart(gesture: gesture, type: type)
            case .cancelled, .failed, .ended:
                delegate?.didEnd(gesture: gesture, type: type)
            default:
                break
            }
        case .bottom:
            switch gesture.state {
            case .changed:
                delegate?.didStart(gesture: gesture, type: type)
            case .cancelled, .failed, .ended:
                delegate?.didEnd(gesture: gesture, type: type)
            default:
                break
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol ResizeEventViewDelegate: class {
    func didStart(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didEnd(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didStartMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer, view: UIView)
    func didEndMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
    func didChangeMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
}
