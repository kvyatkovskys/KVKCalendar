//
//  ResizeEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.10.2020.
//

#if os(iOS)

import UIKit

final class ResizeEventView: UIView {
    
    enum ResizeEventViewType: Int {
        case top, bottom
        
        var tag: Int {
            return rawValue
        }
    }
    
    weak var delegate: ResizeEventViewDelegate?
    
    let event: Event
    let mainYOffset: CGFloat = 15
    let originalFrameEventView: CGRect
    var startTime: TimeContainer?
    var endTime: TimeContainer?
    
    private lazy var eventView: UIView = {
        let view = UIView()
        view.backgroundColor = event.color?.value ?? event.backgroundColor
        return view
    }()
    
    private lazy var topView = createPanView(type: .top)
    private lazy var bottomView = createPanView(type: .bottom)
    private let mainHeightOffset: CGFloat = 30
    private let style: Style
    
    var haveNewSize: (needSave: Bool, frame: CGRect) {
        guard originalFrameEventView.height != eventView.frame.height else {
            return (false, .zero)
        }
        
        let newFrame = CGRect(x: originalFrameEventView.origin.x,
                              y: frame.origin.y,
                              width: originalFrameEventView.width,
                              height: eventView.frame.height)
        return (true, newFrame)
    }
    
    private func createPanView(type: ResizeEventViewType) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: mainYOffset)))
        view.backgroundColor = .clear
        view.tag = type.tag
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(trackGesture))
        view.addGestureRecognizer(gesture)

        return view
    }
    
    private func createCircleView() -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
        view.backgroundColor = .white
        view.layer.borderWidth = 1.5
        view.layer.borderColor = event.color?.value.cgColor ?? event.backgroundColor.cgColor
        view.layer.cornerRadius = 4
        return view
    }
    
    init(view: UIView, event: Event, frame: CGRect, style: Style) {
        self.event = event
        self.originalFrameEventView = frame
        self.style = style
        self.startTime = TimeContainer(minute: event.start.minute, hour: event.start.hour)
        self.endTime = TimeContainer(minute: event.end.minute, hour: event.end.hour)
        
        var newFrame = frame
        newFrame.origin.y -= mainYOffset
        newFrame.size.height += mainHeightOffset
        super.init(frame: newFrame)
        
        backgroundColor = .clear
        
        eventView.frame = CGRect(origin: CGPoint(x: 0, y: mainYOffset), size: CGSize(width: frame.width, height: frame.height))
        addSubview(eventView)
        eventView.layer.cornerRadius = 5
        
        view.frame = CGRect(origin: .zero, size: eventView.frame.size)
        eventView.addSubview(view)
        
        topView.frame.origin = CGPoint(x: frame.width * 0.8, y: mainYOffset * 0.5)
        if (topView.frame.origin.x + topView.frame.width) > frame.width {
            topView.frame.origin.x = frame.width - topView.frame.width
        }
        addSubview(topView)
        
        bottomView.frame.origin = CGPoint(x: (frame.width * 0.2) - bottomView.frame.width, y: frame.height + (mainYOffset * 0.5))
        if bottomView.frame.origin.x < 0 {
            bottomView.frame.origin.x = 0
        }
        addSubview(bottomView)
        
        let topCircleView = createCircleView()
        topCircleView.frame.origin = CGPoint(x: (topView.frame.width * 0.5) - 4, y: topView.frame.height * 0.5 - 4)
        topView.addSubview(topCircleView)
        
        let bottomCircleView = createCircleView()
        bottomCircleView.frame.origin = CGPoint(x: (bottomView.frame.width * 0.5) - 4, y: bottomView.frame.height * 0.5 - 4)
        bottomView.addSubview(bottomCircleView)
        
        if #available(iOS 13.4, *) {
            addPointInteraction(on: self, delegate: self)
        }
    }
    
    func updateHeight() {
        bottomView.frame.origin.y = (frame.height - mainHeightOffset) + (mainYOffset * 0.5)
        eventView.frame.size.height = frame.height - mainHeightOffset
        eventView.subviews.forEach({ $0.frame.size.height = frame.height - mainHeightOffset })
    }
    
    @objc private func trackGesture(gesture: UIPanGestureRecognizer) {
        guard let tag = gesture.view?.tag, let type = ResizeEventViewType(rawValue: tag) else { return }
        
        switch gesture.state {
        case .began:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .changed:
            delegate?.didStart(gesture: gesture, type: type)
        case .cancelled, .failed, .ended:
            delegate?.didEnd(gesture: gesture, type: type)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.4, *)
extension ResizeEventView: PointerInteractionProtocol {
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .highlight(targetedPreview))
        }
        return pointerStyle
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        if topView.frame.contains(request.location) {
            return UIPointerRegion(rect: topView.frame)
        } else if bottomView.frame.contains(request.location) {
            return UIPointerRegion(rect: bottomView.frame)
        } else {
            return nil
        }
    }
    
}

protocol ResizeEventViewDelegate: AnyObject {
    func didStart(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didEnd(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didStartMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer, view: UIView)
    func didEndMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
    func didChangeMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
}

#endif
