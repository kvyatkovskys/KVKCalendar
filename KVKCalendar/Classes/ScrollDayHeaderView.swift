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

final class ScrollDayHeaderView: UIView {
    private let days: [Day]
    private var date: Date
    private var style: Style
    private var collectionView: UICollectionView!
    private var animated: Bool = false
    private let type: CalendarType
    private let calendar: Calendar
    private var lastContentOffset: CGFloat = 0
    
    weak var delegate: ScrollDayHeaderDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = style.headerScrollStyle.colorTitleDate
        return label
    }()
        
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    init(frame: CGRect, days: [Day], date: Date, type: CalendarType, style: Style, calendar: Calendar) {
        self.days = days
        self.date = date
        self.type = type
        self.style = style
        self.calendar = calendar
        super.init(frame: frame)
        
        var newFrame = frame
        newFrame.origin.x = 0
        collectionView = createCollectionView(frame: newFrame, isScrollEnabled: style.headerScrollStyle.isScrollEnabled)
        
        if !style.headerScrollStyle.isHiddenTitleDate {
            collectionView.frame.size.height = frame.height - style.headerScrollStyle.heightTitleDate
            titleLabel.frame = frame
            titleLabel.frame.origin.x = 0
            titleLabel.frame.size.width -= frame.origin.x
            titleLabel.frame.origin.y = collectionView.frame.size.height
            titleLabel.frame.size.height -= (titleLabel.frame.origin.y + 5)
            
            setDateToTitle(date)
            addSubview(titleLabel)
        }
        
        addSubview(collectionView)
    }
    
    func scrollHeaderTitleByTransform(_ transform: CGAffineTransform) {
        guard !transform.isIdentity else {
            identityViews([titleLabel])
            return
        }
        titleLabel.transform = transform
    }
    
    func scrollHeaderByTransform(_ transform: CGAffineTransform) {
        guard !transform.isIdentity else {
            guard let scrollDate = getScrollDate(date: date),
                let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                    && $0.date?.month == scrollDate.month
                    && $0.date?.day == scrollDate.day }) else { return }

            collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                        at: .left,
                                        animated: true)
            return
        }
        
        collectionView.contentOffset.x = lastContentOffset - transform.tx
    }
    
    func setDate(_ date: Date) {
        self.date = date
        scrollToDate(date, animated: animated)
        collectionView.reloadData()
    }
    
    func selectDate(offset: Int) {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return }
        
        if type == .day, !style.headerScrollStyle.isHiddenTitleDate {
            let x = titleLabel.transform.tx < 0 ? frame.width : -frame.width
            titleLabel.transform = CGAffineTransform(translationX: x, y: 0)
            titleLabel.alpha = 0
        }
        
        setDate(nextDate)
    }
    
    private func setDateToTitle(_ date: Date?) {
        if let date = date, !style.headerScrollStyle.isHiddenTitleDate {
            titleLabel.text = style.headerScrollStyle.formatterTitle.string(from: date)
        }
    }
    
    private func createCollectionView(frame: CGRect, isScrollEnabled: Bool) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = style.headerScrollStyle.backgroundColor
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = isScrollEnabled
        collection.register(ScrollHeaderDayCollectionViewCell.self,
                            forCellWithReuseIdentifier: ScrollHeaderDayCollectionViewCell.cellIdentifier)
        return collection
    }
    
    private func scrollToDate(_ date: Date, animated: Bool) {
        delegate?.didSelectDateScrollHeader(date, type: type)
        setDateToTitle(date)
        
        guard let scrollDate = getScrollDate(date: date),
            let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                             at: .left,
                                             animated: animated)
        }
        
        if type == .day, !style.headerScrollStyle.isHiddenTitleDate {
            UIView.animate(withDuration: 0.3) {
                self.titleLabel.transform = .identity
                self.titleLabel.alpha = 1
            }
        }
        
        if !self.animated {
            self.animated = true
        }
    }
    
    private func identityViews(duration: TimeInterval = 0.4, delay: TimeInterval = 0.07, _ views: [UIView], action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScrollDayHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width - self.frame.origin.x
        titleLabel.frame.size.width = self.frame.width
        
        collectionView.removeFromSuperview()
        let newView = createCollectionView(frame: self.frame, isScrollEnabled: style.headerScrollStyle.isScrollEnabled)
        newView.frame.origin.x = 0
        if !style.headerScrollStyle.isHiddenTitleDate {
            newView.frame.size.height = self.frame.height - style.headerScrollStyle.heightTitleDate
        }
        addSubview(newView)
        
        guard let scrollDate = getScrollDate(date: date),
            let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            newView.scrollToItem(at: IndexPath(row: idx, section: 0), at: .left, animated: false)
            self.lastContentOffset = newView.contentOffset.x
        }
        newView.reloadData()
        collectionView = newView
    }
    
    func updateStyle(_ style: Style) {
        self.style = style
    }
    
    private func getScrollDate(date: Date) -> Date? {
        return style.startWeekDay == .sunday ? date.startSundayOfWeek : date.startMondayOfWeek
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
        cell.selectDate = date
        return cell
    }
}

extension ScrollDayHeaderView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard lastContentOffset == 0 else { return }
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [ScrollHeaderDayCollectionViewCell] ?? [ScrollHeaderDayCollectionViewCell()]
        let cellDays = cells.filter({ $0.day.type != .empty })
        guard let newMoveDate = cellDays.filter({ $0.day.date?.weekday == date.weekday }).first?.day.date, date != newMoveDate else { return }
        
        date = newMoveDate.toLocalTime()
        delegate?.didSelectDateScrollHeader(newMoveDate, type: type)
        setDateToTitle(newMoveDate)
        collectionView.reloadData()
        
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch type {
        case .day:
            guard date != days[indexPath.row].date, let dateNew = days[indexPath.row].date else { return }
            
            date = dateNew.toLocalTime()
            delegate?.didSelectDateScrollHeader(date, type: .day)
            setDateToTitle(date)
            collectionView.reloadData()
        case .week:
            guard let dateTemp = days[indexPath.row].date else { return }
            
            date = dateTemp.toLocalTime()
            delegate?.didSelectDateScrollHeader(date, type: style.weekStyle.selectCalendarType)
            setDateToTitle(date)
            collectionView.reloadData()
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht = collectionView.frame.width / 7
        let height = collectionView.frame.height
        return CGSize(width: widht, height: height)
    }
}
