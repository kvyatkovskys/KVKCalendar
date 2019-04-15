//
//  MonthViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class MonthViewCalendar: UIView {
    fileprivate var data: MonthData
    fileprivate let style: Style
    fileprivate var collectionView: UICollectionView!
    fileprivate var animated: Bool = false
    
    weak var delegate: CalendarSelectDateDelegate?
    
    fileprivate lazy var headerView: WeekHeaderView = {
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
    
    fileprivate lazy var layout: UICollectionViewLayout = {
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
        addSubview(headerView)
        
        collectionView = createCollectionView(frame: frame)
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)        
    }
    
    func setDate(date: Date) {
        headerView.date = date
        data.moveDate = date
        scrollToDate(date: date, animated: animated)
        collectionView.reloadData()
    }
    
    func reloadData(events: [Event]) {
        data.reloadEventsInDays(events: events)
        collectionView.reloadData()
    }
    
    fileprivate func createCollectionView(frame: CGRect) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.dataSource = self
        collection.delegate = self
        collection.register(MonthCollectionViewCell.self,
                            forCellWithReuseIdentifier: MonthCollectionViewCell.cellIdentifier)
        return collection
    }
    
    fileprivate func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .month)
        if let idx = data.days.index(where: { $0.date?.month == date.month && $0.date?.year == date.year }) {
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

extension MonthViewCalendar: CalendarFrameDelegate {
    func reloadFrame(frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(frame: frame)
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame)
        
        var collectionFrame = frame
        collectionFrame.origin.y = headerView.frame.height
        collectionFrame.size.height = collectionFrame.height - headerView.frame.height
        collectionView.frame = collectionFrame
        addSubview(collectionView)
        
        if let idx = data.days.index(where: { $0.date?.month == data.moveDate.month && $0.date?.year == data.moveDate.year }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .top,
                                                 animated: false)
            }
        }
        collectionView.reloadData()
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
        cell.style = style.monthStyle
        cell.day = day
        cell.selectDate = data.moveDate
        cell.events = day.events
        cell.delegate = self
        return cell
    }
}

extension MonthViewCalendar: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [MonthCollectionViewCell] ?? [MonthCollectionViewCell()]
        let cellDays = cells.filter({ $0.day.type != .empty })
        guard let newMoveDate = cellDays.filter({ $0.day.date?.day == data.moveDate.day }).first?.day.date else {
            let sorted = cellDays.sorted(by: { ($0.day.date?.day ?? 0) < ($1.day.date?.day ?? 0) })
            if let lastDate = sorted.last?.day.date, lastDate.day < data.moveDate.day {
                data.moveDate = lastDate
                headerView.date = lastDate
                delegate?.didSelectCalendarDate(lastDate, type: .month)
                collectionView.reloadData()
            }
            return
        }
        data.moveDate = newMoveDate
        headerView.date = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .month)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = data.days[indexPath.row].date
        data.moveDate = date ?? data.moveDate
        headerView.date = date
        delegate?.didSelectCalendarDate(date, type: .month)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
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
        }
        
        return CGSize(width: widht, height: height)
    }
}
