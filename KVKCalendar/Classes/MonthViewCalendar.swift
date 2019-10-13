//
//  MonthViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthViewCalendar: UIView {
    private var data: MonthData
    private var style: Style
    private var collectionView: UICollectionView!
    private var animated: Bool = false
    
    weak var delegate: CalendarPrivateDelegate?
    
    private lazy var headerView: WeekHeaderView = {
        let height: CGFloat
        if style.monthStyle.isHiddenTitleDate {
            height = style.monthStyle.heightHeaderWeek
        } else {
            height = style.monthStyle.heightHeaderWeek + style.monthStyle.heightTitleDate
        }
        let view = WeekHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: height), style: style)
        view.backgroundColor = style.weekStyle.colorBackground
        return view
    }()
    
    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = style.monthStyle.scrollDirection
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
        scrollToDate(date: date, animated: animated)
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
        collection.register(MonthCollectionViewCell.self,
                            forCellWithReuseIdentifier: MonthCollectionViewCell.cellIdentifier)
        return collection
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .month, frame: nil)
        if let idx = data.days.firstIndex(where: { $0.date?.month == date.month && $0.date?.year == date.year }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .top,
                                                 animated: animated)
            }
        }
        if !self.animated {
            self.animated = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MonthViewCalendar: MonthCellDelegate {
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectCalendarEvent(event, frame: frame)
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectCalendarMore(date, frame: frame)
    }
}

extension MonthViewCalendar: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(frame)
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame, style: style.monthStyle)
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
        
        if let idx = data.days.firstIndex(where: { $0.date?.month == data.date.month && $0.date?.year == data.date.year }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .top,
                                                 animated: false)
            }
        }
        collectionView.reloadData()
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
        setUI()
        setDate(data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        addSubview(headerView)
        collectionView = createCollectionView(frame: frame, style: style.monthStyle)
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
    }
}

extension MonthViewCalendar: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MonthCollectionViewCell.cellIdentifier,
                                                      for: indexPath) as? MonthCollectionViewCell ?? MonthCollectionViewCell()
        let day = data.days[indexPath.row]
        cell.selectDate = data.date
        cell.style = style.monthStyle
        cell.day = day
        cell.events = day.events
        cell.delegate = self
        return cell
    }
}

extension MonthViewCalendar: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [MonthCollectionViewCell] ?? [MonthCollectionViewCell()]
        let cellDays = cells.filter({ $0.day.type != .empty })
        guard let newMoveDate = cellDays.filter({ $0.day.date?.day == data.date.day }).first?.day.date else {
            let sorted = cellDays.sorted(by: { ($0.day.date?.day ?? 0) < ($1.day.date?.day ?? 0) })
            if let lastDate = sorted.last?.day.date, lastDate.day < data.date.day {
                data.date = lastDate
                headerView.date = lastDate
                delegate?.didSelectCalendarDate(lastDate, type: .month, frame: nil)
                collectionView.reloadData()
            }
            return
        }
        data.date = newMoveDate
        headerView.date = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .month, frame: nil)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = data.days[indexPath.row].date
        data.date = date ?? data.date
        headerView.date = date
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectCalendarDate(date, type: style.monthStyle.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard style.monthStyle.isAnimateSelection else { return }
        
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
        guard style.monthStyle.isAnimateSelection else { return }
        
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht: CGFloat
        let height: CGFloat
        
        switch style.monthStyle.scrollDirection {
        case .horizontal:
            widht = collectionView.frame.width / 7
            height = collectionView.frame.height / 6
        case .vertical:
            widht = (collectionView.frame.width / 7) - 0.2
            height = collectionView.frame.height / 6
        @unknown default:
            fatalError()
        }
        
        return CGSize(width: widht, height: height)
    }
}
