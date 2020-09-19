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
    private var collectionView: UICollectionView!
    private var eventPreview: UIView?
    
    weak var delegate: CalendarPrivateDelegate?
    weak var dataSource: DisplayDataSource?
    
    private lazy var headerView: WeekHeaderView = {
        let height: CGFloat
        if style.month.isHiddenTitleDate {
            height = style.month.heightHeaderWeek
        } else {
            height = style.month.heightHeaderWeek + style.month.heightTitleDate
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
    }
    
    func setDate(_ date: Date) {
        headerView.date = date
        data.date = date
        scrollToDate(date, animated: data.isAnimate)
        collectionView.reloadData()
    }
    
    func reloadData(events: [Event]) {
        data.reloadEventsInDays(events: events)
        collectionView.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: MonthStyle) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.register(MonthCell.self)
        return collection
    }
    
    private func scrollToDate(_ date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .month, frame: nil)
        if let idx = data.days.firstIndex(where: { $0.date?.month == date.month && $0.date?.year == date.year }) {
            let index = getIndexForDirection(style.month.scrollDirection, indexPath: IndexPath(row: idx, section: 0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: index, at: .top, animated: animated)
            }
        }
        
        if !data.isAnimate {
            data.isAnimate = true
        }
    }
    
    private func didSelectDate(_ date: Date, indexPath: IndexPath) {
        data.date = date
        headerView.date = date
        
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let attributes = collectionView.layoutAttributesForItem(at: index)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectCalendarDate(date, type: style.month.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    private func getVisibaleDate() -> Date? {
        let cells = collectionView.visibleCells as? [MonthCell] ?? [MonthCell()]
        let cellDays = cells.filter({ $0.item?.day.type != .empty })
        guard let newMoveDate = cellDays.filter({ $0.item?.day.date?.day == data.date.day }).first?.item?.day.date else {
            let sorted = cellDays.sorted(by: { ($0.item?.day.date?.day ?? 0) < ($1.item?.day.date?.day ?? 0) })
            if let lastDate = sorted.last?.item?.day.date, lastDate.day < data.date.day {
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

extension MonthView: MonthCellDelegate {
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectCalendarMore(date, frame: frame)
    }
    
    func didStartMoveEventPage(_ event: Event, snapshot: UIView?, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        
        eventPreview = nil
        eventPreview = snapshot
        data.eventPreviewXOffset = (snapshot?.bounds.width ?? data.eventPreviewXOffset) / 2
        eventPreview?.frame.origin = CGPoint(x: point.x - data.eventPreviewXOffset, y: point.y - data.eventPreviewYOffset)
        eventPreview?.alpha = 0.9
        eventPreview?.tag = data.tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        guard let eventTemp = eventPreview else { return }
        
        collectionView.addSubview(eventTemp)
        UIView.animate(withDuration: 0.3) {
            self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIImpactFeedbackGenerator().impactOccurred()
    }
    
    func didEndMoveEventPage(_ event: Event, gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        
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
    }
    
    func didChangeMoveEventPage(_ event: Event, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        guard collectionView.frame.width >= (point.x + 20), (point.x - 20) >= 0 else { return }
        
        var offset = collectionView.contentOffset
        if (point.y - 80) < collectionView.contentOffset.y, (point.y - (eventPreview?.bounds.height ?? 50)) >= 0 {
            // scroll up
            offset.y -= 5
            collectionView.setContentOffset(offset, animated: false)
        } else if (point.y + 80) > (collectionView.contentOffset.y + collectionView.bounds.height), point.y + (eventPreview?.bounds.height ?? 50) <= collectionView.contentSize.height {
            // scroll down
            offset.y += 5
            collectionView.setContentOffset(offset, animated: false)
        }
        
        eventPreview?.frame.origin = CGPoint(x: point.x - data.eventPreviewXOffset, y: point.y - data.eventPreviewYOffset)
    }
}

extension MonthView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(frame)
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame, style: style.month)
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
        
        if let idx = data.days.firstIndex(where: { $0.date?.month == data.date.month && $0.date?.year == data.date.year }) {
            let index = getIndexForDirection(style.month.scrollDirection, indexPath: IndexPath(row: idx, section: 0))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: index,
                                                 at: .top,
                                                 animated: false)
            }
        }
        collectionView.reloadData()
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
        collectionView = createCollectionView(frame: frame, style: style.month)
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let row = indexPath.row % data.rows
            let column = floor(Double(indexPath.row / data.rows))
            let newIndex = (indexPath.section * data.rows * data.columns) + Int(column) + row * data.columns
            return IndexPath(row: newIndex, section: indexPath.section)
        default:
            return indexPath
        }
    }
}

extension MonthView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch style.month.scrollDirection {
        case .horizontal:
            return Int(ceil(Float(data.days.count) / Float(data.rows * data.columns)))
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch style.month.scrollDirection {
        case .horizontal:
            return data.rows * data.columns
        default:
            return data.days.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MonthCell.identifier,
                                                      for: indexPath) as? MonthCell ?? MonthCell()
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let day = data.days[index.row]
        cell.selectDate = data.date
        cell.style = style
        cell.item = styleForDay(day)
        cell.events = day.events
        cell.delegate = self
        return cell
    }
}

extension MonthView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let newMoveDate = getVisibaleDate(), data.willSelectDate?.month != newMoveDate.month, data.date != newMoveDate else { return }
        
        print(newMoveDate)
        data.willSelectDate = newMoveDate
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard style.month.isAutoSelectDateScrolling, let newMoveDate = getVisibaleDate() else { return }
        
        data.date = newMoveDate
        headerView.date = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .month, frame: nil)
        collectionView.reloadData()
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
        let widht: CGFloat
        let height: CGFloat
        
        switch style.month.scrollDirection {
        case .horizontal:
            widht = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        case .vertical:
            if style.month.isPagingEnabled {
                widht = (collectionView.frame.width / 7) - 0.2
                height = collectionView.frame.height / 6
            } else {
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    widht = (collectionView.frame.width / 7) - 0.2
                    height = collectionView.frame.height / 7
                default:
                    widht = (collectionView.frame.width / 7) - 0.2
                    height = collectionView.frame.height / 6
                }
            }
        @unknown default:
            fatalError()
        }
        
        return CGSize(width: widht, height: height)
    }
}

extension MonthView: DayStyleProtocol {
    typealias Model = DayStyle
    
    func styleForDay(_ day: Day) -> DayStyle {
        guard let item = dataSource?.willDisplayDate(day.date, events: day.events) else { return DayStyle(day, nil) }
        
        return DayStyle(day, item)
    }
}
