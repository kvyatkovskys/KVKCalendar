//
//  MonthView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthView: UIView {
    private var monthData: MonthData
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
        self.monthData = data
        self.style = style
        super.init(frame: frame)
        setUI()
        scrollToDate(data.date, animated: false)
    }
    
    func setDate(_ date: Date) {
        headerView.date = date
        monthData.date = date
        monthData.selectedDates.removeAll()
        scrollToDate(date, animated: monthData.isAnimate)
        collectionView?.reloadData()
    }
    
    func reloadData(_ events: [Event]) {
        let displayableValues = monthData.reloadEventsInDays(events: events, date: monthData.date)
        delegate?.didDisplayCalendarEvents(displayableValues.events, dates: displayableValues.dates, type: .month)
        collectionView?.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: MonthStyle) -> UICollectionView {
        if let customCollectionView = dataSource?.willDisplayCollectionView(frame: frame, type: .month) {
            if customCollectionView.delegate == nil {
                customCollectionView.delegate = self
            }
            if customCollectionView.dataSource == nil {
                customCollectionView.dataSource = self
            }
            return customCollectionView
        }
        
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.isScrollEnabled = style.isScrollEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return collection
    }
    
    private func scrollToDate(_ date: Date, animated: Bool) {
        if let idx = monthData.data.months.firstIndex(where: { $0.date.month == date.month && $0.date.year == date.year }) {
            scrollToIndex(idx, animated: animated)
        }
        
        if !monthData.isAnimate {
            monthData.isAnimate = true
        }
    }
    
    private func scrollToIndex(_ idx: Int, animated: Bool) {
        let scrollType: UICollectionView.ScrollPosition = style.month.scrollDirection == .horizontal ? .left : .top
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx), at: scrollType, animated: animated)
        }
    }
    
    private func didSelectDates(_ dates: [Date], indexPath: IndexPath) {
        guard let date = dates.last else {
            collectionView?.reloadData()
            return
        }
        
        monthData.date = date
        headerView.date = date
        
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let attributes = collectionView?.layoutAttributesForItem(at: index)
        let frame = collectionView?.convert(attributes?.frame ?? .zero, to: collectionView) ?? .zero
        
        delegate?.didSelectCalendarDates(dates, type: style.month.selectCalendarType, frame: frame)
        collectionView?.reloadData()
    }
    
    private func getVisibleDate() -> Date? {
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let days = cells.compactMap { (indexPath) -> Day in
            let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
            return monthData.data.months[index.section].days[index.row]
        }
        guard let newMoveDate = days.filter({ $0.date?.day == monthData.date.day }).first?.date else {
            let sorted = days.sorted(by: { ($0.date?.day ?? 0) < ($1.date?.day ?? 0) })
            if let lastDate = sorted.last?.date, lastDate.day < monthData.date.day {
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
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView = createCollectionView(frame: collectionFrame, style: style.month)
        if let tempView = collectionView {
            addSubview(tempView)
        }
        
        if let idx = monthData.data.months.firstIndex(where: { $0.date.month == monthData.date.month && $0.date.year == monthData.date.year }) {
            scrollToIndex(idx, animated: false)
        }
        collectionView?.reloadData()
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        headerView.updateStyle(style)
        setUI()
        setDate(monthData.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(headerView)
        collectionView = nil
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView = createCollectionView(frame: collectionFrame, style: style.month)
        if let tempView = collectionView {
            addSubview(tempView)
        }
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / monthData.itemsInPage
            let b = indexPath.item / monthData.rowsInPage - a * monthData.columnsInPage
            let c = indexPath.item % monthData.rowsInPage
            let newIdx = (c * monthData.columnsInPage + b) + a * monthData.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
}

extension MonthView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return monthData.data.months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch style.month.scrollDirection {
        case .horizontal:
            return monthData.rowsInPage * monthData.columns
        default:
            return monthData.data.months[section].days.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        guard let day = monthData.getDay(indexPath: index) else { return UICollectionViewCell() }
        
        if let cell = dataSource?.dequeueDateCell(date: day.date, type: .month, collectionView: collectionView, indexPath: index), day.type != .empty {
            return cell
        } else {
            return collectionView.dequeueCell(indexPath: index) { (cell: MonthCell) in
                let date = day.date ?? Date()
                switch style.month.selectionMode {
                case .multiple:
                    cell.selectDate = monthData.selectedDates.contains(date) ? date : monthData.date
                case .single:
                    cell.selectDate = monthData.date
                }
                cell.style = style
                cell.day = day
                cell.events = day.events
                cell.delegate = self
                cell.isHidden = index.row > monthData.daysCount
                if let date = day.date {
                    cell.isSelected = monthData.selectedDates.contains(date)
                } else {
                    cell.isSelected = false
                }
            }
        }
    }
}

extension MonthView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if monthData.isFirstLoad {
            monthData.isFirstLoad = false
            return
        }
        
        guard let newMoveDate = getVisibleDate(), monthData.willSelectDate.month != newMoveDate.month, monthData.date != newMoveDate else {
            return
        }
        
        monthData.willSelectDate = newMoveDate
        willSelectDate?(newMoveDate)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !style.month.isPagingEnabled, let visibleItems = collectionView?.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row }) {
            let middleIndex = visibleItems[visibleItems.count / 2]
            let newDate = monthData.data.months[middleIndex.section].date
            headerView.date = newDate
            
            if style.month.isAutoSelectDateScrolling {
                monthData.date = newDate
                delegate?.didSelectCalendarDates([newDate], type: .month, frame: nil)
                collectionView?.reloadData()
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard style.month.isPagingEnabled else { return }
        
        let visibleIndex: Int
        switch style.month.scrollDirection {
        case .vertical:
            visibleIndex = Int(targetContentOffset.pointee.y / scrollView.bounds.height)
        case .horizontal:
            visibleIndex = Int(targetContentOffset.pointee.x / scrollView.bounds.width)
        @unknown default:
            fatalError()
        }

        let newDate = monthData.data.months[visibleIndex].date
        headerView.date = newDate
        guard style.month.isAutoSelectDateScrolling else { return }
        
        monthData.date = newDate
        delegate?.didSelectCalendarDates([newDate], type: .month, frame: nil)
        collectionView?.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        guard let date = monthData.getDay(indexPath: index)?.date else { return }
        
        switch style.month.selectionMode {
        case .multiple:
            monthData.selectedDates = monthData.updateSelectedDates(monthData.selectedDates, date: date, calendar: style.calendar)
            didSelectDates(monthData.selectedDates.compactMap({ $0 }), indexPath: index)
        case .single:
            didSelectDates([date], indexPath: index)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        guard let day = monthData.getDay(indexPath: index) else { return .zero }
        
        if let size = delegate?.sizeForCell(day.date, type: .month) {
            return size
        }
        
        let width: CGFloat
        let height: CGFloat
        
        switch style.month.scrollDirection {
        case .horizontal:
            width = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        case .vertical:
            if collectionView.frame.width > 0 {
                width = collectionView.frame.width / 7 - 0.2
            } else {
                width = 0
            }
            
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
        
        return CGSize(width: width, height: height)
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
        
        monthData.movingEvent = event
        eventPreview = nil
        eventPreview = snapshot
        monthData.eventPreviewXOffset = (snapshot?.bounds.width ?? monthData.eventPreviewXOffset) / 2
        eventPreview?.frame.origin = CGPoint(x: point.x - monthData.eventPreviewXOffset, y: point.y - monthData.eventPreviewYOffset)
        eventPreview?.alpha = 0.9
        eventPreview?.tag = monthData.tagEventPagePreview
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
        guard let indexPath = collectionView?.indexPathForItem(at: point), let event = monthData.movingEvent?.event else { return }
        
        monthData.movingEvent = nil
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let day = monthData.data.months[index.section].days[index.row]
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
        didSelectDates([newDate], indexPath: index)
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
        
        eventPreview?.frame.origin = CGPoint(x: point.x - monthData.eventPreviewXOffset, y: point.y - monthData.eventPreviewYOffset)
    }
}
