//
//  ScrollDayHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

protocol ScrollDayHeaderDelegate: class {
    func didSelectDateScrollHeader(_ date: Date?, type: CalendarType)
}

protocol ScrollDayHeaderSwipeDelegate: class {
    func swipeHeader(transform: CGAffineTransform)
    func weekSwiped()
}

final class ScrollDayHeaderView: UIView {
    fileprivate var days: [Day]
    fileprivate var moveDate: Date?
    fileprivate var style: Style
    var collectionView: UICollectionView!
    fileprivate var animated: Bool = false
    fileprivate let type: CalendarType
    fileprivate let calendar: Calendar
    var lastContentOffset: CGFloat = 0
    
    weak var delegate: ScrollDayHeaderDelegate?
    weak var swipeDelegate: ScrollDayHeaderSwipeDelegate?
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    fileprivate let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    init(frame: CGRect, days: [Day], date: Date, type: CalendarType, style: Style, calendar: Calendar) {
        self.days = days
        self.moveDate = date
        self.type = type
        self.style = style
        self.calendar = calendar
        super.init(frame: frame)
        
        collectionView = createCollectionView(frame: frame)
        collectionView.frame.origin.x = 0
        if !style.headerScrollStyle.isHiddenTitleDate {
            collectionView.frame.size.height = frame.height - style.headerScrollStyle.heightTitleDate
            titleLabel.frame = frame
            titleLabel.frame.origin.x = 0
            titleLabel.frame.size.width -= frame.origin.x
            titleLabel.frame.origin.y = collectionView.frame.size.height
            titleLabel.frame.size.height -= (titleLabel.frame.origin.y + 5)
            
            setDateToTitle(date: date)
            addSubview(titleLabel)
        }
        collectionView.isScrollEnabled = style.headerScrollStyle.isScrollEnabled
        addSubview(collectionView)
    }
    
    func setDate(date: Date) {
        moveDate = date
        scrollToDate(date: date, animated: animated)
        collectionView.reloadData()
    }
    
    func selectDate(offset: Int) {
        guard let date = moveDate, let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return }
        setDate(date: nextDate)
    }
    
    fileprivate func setDateToTitle(date: Date?) {
        if let date = date, !style.headerScrollStyle.isHiddenTitleDate {
            titleLabel.text = style.headerScrollStyle.formatter.string(from: date)
        }
    }
    
    fileprivate func createCollectionView(frame: CGRect) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.register(ScrollHeaderDayCollectionViewCell.self,
                            forCellWithReuseIdentifier: ScrollHeaderDayCollectionViewCell.cellIdentifier)
        return collection
    }
    
    fileprivate func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectDateScrollHeader(date, type: type)
        setDateToTitle(date: date)
        
        guard let scrollDate = getScrollDate(date: date),
            let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day })
            else {
                return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                             at: .left,
                                             animated: animated)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScrollDayHeaderView: CalendarFrameProtocol {
    func reloadFrame(frame: CGRect) {
        self.frame.size.width = frame.width - self.frame.origin.x
        titleLabel.frame.size.width = self.frame.width
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame)
        collectionView.frame.origin.x = 0
        if !style.headerScrollStyle.isHiddenTitleDate {
            collectionView.frame.size.height = frame.height - style.headerScrollStyle.heightTitleDate
        }
        
        addSubview(collectionView)
        
        if let date = moveDate {
            guard let scrollDate = getScrollDate(date: date),
                let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                    && $0.date?.month == scrollDate.month
                    && $0.date?.day == scrollDate.day })
                else {
                    return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .left,
                                                 animated: false)
            }
            
        }
        collectionView.reloadData()
    }
    
    private func getScrollDate(date: Date) -> Date? {
        return date.startOfWeek
    }
}

extension ScrollDayHeaderView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScrollHeaderDayCollectionViewCell.cellIdentifier,
                                                      for: indexPath) as? ScrollHeaderDayCollectionViewCell ?? ScrollHeaderDayCollectionViewCell()
        cell.style = style.headerScrollStyle
        cell.day = days[indexPath.row]
        cell.selectDate = moveDate ?? Date()
        return cell
    }
}

extension ScrollDayHeaderView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset.x
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        swipeDelegate?.swipeHeader(transform: CGAffineTransform(translationX: lastContentOffset - scrollView.contentOffset.x, y: 0))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [ScrollHeaderDayCollectionViewCell] ?? [ScrollHeaderDayCollectionViewCell()]
        let cellDays = cells.filter({ $0.day.type != .empty })
        let newMoveDate = cellDays.filter({ $0.day.date?.weekday == moveDate?.weekday && $0.day.date != $0.selectDate }).first?.day.date ?? moveDate
        if let diffInDays = Calendar.current.dateComponents([.day], from: moveDate ?? Date(), to: newMoveDate ?? Date()).day, diffInDays == 7 {
            swipeDelegate?.weekSwiped()
        }
        moveDate = newMoveDate
        delegate?.didSelectDateScrollHeader(newMoveDate, type: type)
        setDateToTitle(date: newMoveDate)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard type != .day else {
            guard moveDate != days[indexPath.row].date else { return }
            moveDate = days[indexPath.row].date
            delegate?.didSelectDateScrollHeader(moveDate, type: .day)
            setDateToTitle(date: moveDate)
            collectionView.reloadData()
            return
        }
        moveDate = days[indexPath.row].date
        delegate?.didSelectDateScrollHeader(moveDate, type: .day)
        setDateToTitle(date: moveDate)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht = collectionView.frame.width / 7
        let height = collectionView.frame.height
        return CGSize(width: widht, height: height)
    }
}
