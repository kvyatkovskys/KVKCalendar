//
//  AllDayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 20.05.2021.
//

#if os(iOS)

import UIKit

final class AllDayView: UIView {
    
    struct PrepareEvents {
        let events: [Event]
        let date: Date?
        let xOffset: CGFloat
        let width: CGFloat
    }
    
    struct Parameters {
        let prepareEvents: [PrepareEvents]
        let type: CalendarType
        var style: Style
        weak var delegate: TimelineDelegate?
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let scrollView = UIScrollView()
    private let linePoints: [CGPoint]
    private var params: Parameters
    private weak var dataSource: DisplayDataSource?

    let items: [[AllDayEvent]]
    
    init(parameters: Parameters, frame: CGRect, dataSource: DisplayDataSource?) {
        self.params = parameters
        self.items = parameters.prepareEvents.compactMap { item -> [AllDayEvent] in
            item.events.compactMap { AllDayEvent(date: $0.start, event: $0, xOffset: item.xOffset, width: item.width) }
        }
        self.linePoints = parameters.prepareEvents.compactMap({ CGPoint(x: $0.xOffset, y: 0) })
        self.dataSource = dataSource
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calculateFrame(index: Int, countEvents: Int, width: CGFloat, height: CGFloat) -> CGRect {
        var newSize: CGSize
        var newPoint: CGPoint
        let newY = height * CGFloat(index / 2)
        let newWidth = width * 0.5
        
        if countEvents == (index + 1) {
            newSize = CGSize(width: index % 2 == 0 ? width : newWidth, height: height)
            newPoint = CGPoint(x: index % 2 == 0 ? 0 : newWidth, y: newY)
        } else if index % 2 == 0 {
            newSize = CGSize(width: newWidth, height: height)
            newPoint = CGPoint(x: 0, y: newY)
        } else {
            newSize = CGSize(width: newWidth, height: height)
            newPoint = CGPoint(x: newWidth, y: newY)
        }
        
        newSize.width -= params.style.allDay.offsetWidth
        newSize.height -= params.style.allDay.offsetHeight
        newPoint.y += 1
        
        return CGRect(origin: newPoint, size: newSize)
    }
    
    private func setupView() {
        backgroundColor = params.style.allDay.backgroundColor
        titleLabel.removeFromSuperview()
        scrollView.removeFromSuperview()
        
        let widthTitle = params.style.timeline.widthTime + params.style.timeline.offsetTimeX + params.style.timeline.offsetLineLeft + params.style.timeline.offsetAdditionalTimeX
        titleLabel.frame = CGRect(x: params.style.allDay.offsetX, y: 0,
                                  width: widthTitle - params.style.allDay.offsetX,
                                  height: params.style.allDay.height)
        titleLabel.font = params.style.allDay.fontTitle
        titleLabel.textColor = params.style.allDay.titleColor
        titleLabel.textAlignment = params.style.allDay.titleAlignment
        titleLabel.text = params.style.allDay.titleText
        
        let x = titleLabel.frame.width + titleLabel.frame.origin.x
        let scrollFrame = CGRect(origin: CGPoint(x: x, y: 0),
                                 size: CGSize(width: bounds.size.width - x, height: bounds.size.height))
        
        let maxItems = CGFloat(items.max(by: { $0.count < $1.count })?.count ?? 0)
        scrollView.frame = scrollFrame
        
        switch params.type {
        case .day:
            scrollView.contentSize = CGSize(width: scrollFrame.width,
                                            height: (maxItems / 2).rounded(.up) * params.style.allDay.height)
        case .week:
            scrollView.contentSize = CGSize(width: scrollFrame.width,
                                            height: maxItems * params.style.allDay.height)
        default:
            break
        }
        
        addSubview(titleLabel)
        addSubview(scrollView)
    }
    
    private func createEventViews() {
        switch params.type {
        case .day:
            if let item = items.first {
                item.enumerated().forEach { (event) in
                    let frameEvent = calculateFrame(index: event.offset,
                                                    countEvents: item.count,
                                                    width: scrollView.bounds.width,
                                                    height: params.style.allDay.height)
                    let eventView = createEventView(event: event.element.event, frame: frameEvent)
                    scrollView.addSubview(eventView)
                }
            }
        case .week:
            items.enumerated().forEach { item in
                item.element.enumerated().forEach { (event) in
                    let x = item.offset == 0 ? 0 : event.element.xOffset
                    let frameEvent = CGRect(origin: CGPoint(x: x, y: params.style.allDay.height * CGFloat(event.offset)),
                                            size: CGSize(width: event.element.width - params.style.allDay.offsetWidth,
                                                         height: params.style.allDay.height - params.style.allDay.offsetHeight))
                    let eventView = createEventView(event: event.element.event, frame: frameEvent)
                    scrollView.addSubview(eventView)
                }
            }
            
            if params.style.allDay.isPinned {
                linePoints.enumerated().forEach { (point) in
                    let x = point.offset == 0 ? scrollView.frame.origin.x : (point.element.x + scrollView.frame.origin.x)
                    let line = createVerticalLine(pointX: x)
                    addSubview(line)
                }
            }
        default:
            break
        }
    }
    
    private func createEventView(event: Event, frame: CGRect) -> UIView {
        if let customView = dataSource?.dequeueAllDayViewEvent(event, date: event.start, frame: frame) {
            return customView
        } else {
            let eventView = AllDayEventView(style: params.style.allDay, event: event,  frame: frame)
            eventView.delegate = self
            return eventView
        }
    }
    
    private func createVerticalLine(pointX: CGFloat) -> VerticalLineView {
        let frame = CGRect(x: pointX, y: 0, width: params.style.timeline.widthLine, height: bounds.height)
        let line = VerticalLineView(frame: frame)
        line.backgroundColor = params.style.timeline.separatorLineColor
        line.isHidden = !params.style.week.showVerticalDayDivider
        return line
    }
}

extension AllDayView: AllDayEventDelegate {
    
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?) {
        params.delegate?.didSelectEvent(event, frame: frame)
    }
    
}

extension AllDayView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            params.style
        }
        set {
            params.style = newValue
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
    }
    
    func setUI(reload: Bool = false) {
        setupView()
        createEventViews()
    }
    
}

#endif
