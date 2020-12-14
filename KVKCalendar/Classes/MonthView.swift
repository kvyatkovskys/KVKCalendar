//
//  MonthView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthView: UIView {
    private var data: MonthData
    private var style: Style
    private var collectionView: UICollectionView?
    private var eventPreview: UIView?
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    var willSelectDate: ((Date) -> Void)?
    
    private lazy var headerView: WeekHeaderView = {
        let height: CGFloat
        if style.month.isHiddenTitleDate {
            height = style.month.heightHeaderWeek
        } else {
            height = style.month.heightHeaderWeek + style.month.heightTitleDate + 5
        }
        let view = WeekHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: height), style: style)
        view.backgroundColor = style.week.colorBackground
        return view
    }()
    
    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = style.month.scrollDirection
        return layout
    }()
    
    init(data: MonthData, frame: CGRect, style: Style) {
        self.data = data
        self.style = style
        super.init(frame: frame)
        setUI()
        scrollToDate(data.date, animated: false)
    }
    
    func setDate(_ date: Date) {
        headerView.date = date
        data.date = date
        scrollToDate(date, animated: data.isAnimate)
        collectionView?.reloadData()
    }
    
    func reloadData(events: [Event]) {
        let displayableValues = data.reloadEventsInDays(events: events)
        delegate?.didDisplayCalendarEvents(displayableValues.events, dates: displayableValues.dates, type: .month)
        collectionView?.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: MonthStyle) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return collection
    }
    
    private func scrollToDate(_ date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .month, frame: nil)
        if let idx = data.days.firstIndex(where: { $0.date?.month == date.month && $0.date?.year == date.year }) {
            scrollToIndex(idx + 15, animated: animated)
        }
        
        if !data.isAnimate {
            data.isAnimate = true
        }
    }
    
    private func scrollToIndex(_ idx: Int, animated: Bool) {
        let newIndex = getIndexForDirection(style.month.scrollDirection, indexPath: IndexPath(row: idx, section: 0))
        let scrollType: UICollectionView.ScrollPosition = style.month.scrollDirection == .horizontal ? .left : .top
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.collectionView?.scrollToItem(at: newIndex, at: scrollType, animated: animated)
        }
    }
    
    private func didSelectDate(_ date: Date, indexPath: IndexPath) {
        data.date = date
        headerView.date = date
        
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let attributes = collectionView?.layoutAttributesForItem(at: index)
        let frame = collectionView?.convert(attributes?.frame ?? .zero, to: collectionView) ?? .zero
        
        delegate?.didSelectCalendarDate(date, type: style.month.selectCalendarType, frame: frame)
        collectionView?.reloadData()
    }
    
    private func getVisibaleDate() -> Date? {
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let days = cells.compactMap { (indexPath) -> Day in
            let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
            return data.days[index.row]
        }
        guard let newMoveDate = days.filter({ $0.date?.day == data.date.day }).first?.date else {
            let sorted = days.sorted(by: { ($0.date?.day ?? 0) < ($1.date?.day ?? 0) })
            if let lastDate = sorted.last?.date, lastDate.day < data.date.day {
                return lastDate
            }
            return nil
        }
        return newMoveDate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MonthView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(frame)
        
        collectionView?.removeFromSuperview()
        collectionView = nil
        collectionView = createCollectionView(frame: self.frame, style: style.month)
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView?.frame = collectionFrame
        if let tempView = collectionView {
            addSubview(tempView)
        }
        
        if let idx = data.days.firstIndex(where: { $0.date?.month == data.date.month && $0.date?.year == data.date.year }) {
            scrollToIndex(idx, animated: false)
        }
        collectionView?.reloadData()
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        headerView.updateStyle(style)
        setUI()
        setDate(data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(headerView)
        collectionView = nil
        collectionView = createCollectionView(frame: frame, style: style.month)
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView?.frame = collectionFrame
        if let tempView = collectionView {
            addSubview(tempView)
        }
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / data.itemsInPage
            let b = indexPath.item / data.rowsInPage - a * data.columnsInPage
            let c = indexPath.item % data.rowsInPage
            let newIdx = (c * data.columnsInPage + b) + a * data.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
}

extension MonthView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch style.month.scrollDirection {
        case .horizontal:
            return data.rowsInPage * data.columns
        default:
            return data.days.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let day = data.days[index.row]
        
        if let cell = dataSource?.dequeueDateCell(date: day.date, type: .month, collectionView: collectionView, indexPath: index), day.type != .empty {
            return cell
        } else {
            return collectionView.dequeueCell(indexPath: index) { (cell: MonthCell) in
                cell.selectDate = data.date
                cell.style = style
                cell.day = day
                cell.events = day.events
                cell.delegate = self
                cell.isHidden = index.row > data.days.count
            }
        }
    }
}

extension MonthView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if data.isFirstLoad {
            data.isFirstLoad = false
            return
        }
        
        guard let newMoveDate = getVisibaleDate(), data.willSelectDate.month != newMoveDate.month, data.date != newMoveDate else {
            return
        }
        
        data.willSelectDate = newMoveDate
        willSelectDate?(newMoveDate)
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let newMoveDate = getVisibaleDate() else { return }
        
        headerView.date = newMoveDate
        guard style.month.isAutoSelectDateScrolling else { return }
        
        data.date = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .month, frame: nil)
        collectionView?.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let date = data.days[index.row].date
        didSelectDate(date ?? data.date, indexPath: index)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard style.month.isAnimateSelection else { return }
        
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.3,
                       initialSpringVelocity: 0.8,
                       options: .curveLinear,
                       animations: { cell?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) },
                       completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard style.month.isAnimateSelection else { return }
        
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let cell = collectionView.cellForItem(at: index)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let date = data.days[index.row].date
        
        if let size = delegate?.sizeForCell(date, type: .month) {
            return size
        }
        
        let widht: CGFloat
        let height: CGFloat
        
        switch style.month.scrollDirection {
        case .horizontal:
            widht = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        case .vertical:
            widht = (collectionView.frame.width / 7) - 0.2
            
            if style.month.isPagingEnabled {
                height = collectionView.frame.height / 6
            } else {                
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    height = collectionView.frame.height / 7
                default:
                    height = collectionView.frame.height / 6
                }
            }
        @unknown default:
            fatalError()
        }
        
        return CGSize(width: widht, height: height)
    }
}

extension MonthView: MonthCellDelegate {
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectCalendarMore(date, frame: frame)
    }
    
    func didStartMoveEvent(_ event: EventViewGeneral, snapshot: UIView?, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        
        data.movingEvent = event
        eventPreview = nil
        eventPreview = snapshot
        data.eventPreviewXOffset = (snapshot?.bounds.width ?? data.eventPreviewXOffset) / 2
        eventPreview?.frame.origin = CGPoint(x: point.x - data.eventPreviewXOffset, y: point.y - data.eventPreviewYOffset)
        eventPreview?.alpha = 0.9
        eventPreview?.tag = data.tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        guard let eventTemp = eventPreview else { return }
        
        collectionView?.addSubview(eventTemp)
        UIView.animate(withDuration: 0.3) {
            self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIImpactFeedbackGenerator().impactOccurred()
        collectionView?.isScrollEnabled = false
    }
    
    func didEndMoveEvent(gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView?.indexPathForItem(at: point), let event = data.movingEvent?.event else { return }
        
        data.movingEvent = nil
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let day = data.days[index.row]
        let newDate = day.date ?? event.start

        var startComponents = DateComponents()
        startComponents.year = newDate.year
        startComponents.month = newDate.month
        startComponents.day = newDate.day
        startComponents.hour = event.start.hour
        startComponents.minute = event.start.minute
        let startDate = style.calendar.date(from: startComponents)

        var endComponents = DateComponents()
        endComponents.year = newDate.year
        endComponents.month = newDate.month
        endComponents.day = newDate.day
        endComponents.hour = event.end.hour
        endComponents.minute = event.end.minute
        let endDate = style.calendar.date(from: endComponents)

        delegate?.didChangeCalendarEvent(event, start: startDate, end: endDate)
        scrollToDate(newDate, animated: true)
        didSelectDate(newDate, indexPath: index)
        collectionView?.isScrollEnabled = true
    }
    
    func didChangeMoveEvent(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        guard (collectionView?.frame.width ?? 0) >= (point.x + 20), (point.x - 20) >= 0 else { return }
        
        var offset = collectionView?.contentOffset ?? .zero
        let contentSize = collectionView?.contentSize ?? .zero
        if (point.y - 80) < offset.y, (point.y - (eventPreview?.bounds.height ?? 50)) >= 0 {
            // scroll up
            offset.y -= 5
            collectionView?.setContentOffset(offset, animated: false)
        } else if (point.y + 80) > (offset.y + (collectionView?.bounds.height ?? 0)), point.y + (eventPreview?.bounds.height ?? 50) <= contentSize.height {
            // scroll down
            offset.y += 5
            collectionView?.setContentOffset(offset, animated: false)
        }
        
        eventPreview?.frame.origin = CGPoint(x: point.x - data.eventPreviewXOffset, y: point.y - data.eventPreviewYOffset)
    }
}
