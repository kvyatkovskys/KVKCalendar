//
//  ScrollDayHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class ScrollDayHeaderView: UIView {
    var didTrackScrollOffset: ((CGFloat) -> Void)?
    var didSelectDate: ((Date?, CalendarType) -> Void)?
    
    private let days: [Day]
    private var date: Date
    private var style: Style
    private var collectionView: UICollectionView!
    private var isAnimate: Bool = false
    private let type: CalendarType
    private let calendar: Calendar
    private var lastContentOffset: CGFloat = 0
    
    weak var dataSource: DisplayDataSource?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = style.headerScroll.colorTitleDate
        return label
    }()
        
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    init(frame: CGRect, days: [Day], date: Date, type: CalendarType, style: Style) {
        self.days = days
        self.date = date
        self.type = type
        self.style = style
        self.calendar = style.calendar
        super.init(frame: frame)
        
        var newFrame = frame
        newFrame.origin.x = 0
        collectionView = createCollectionView(frame: newFrame, isScrollEnabled: style.headerScroll.isScrollEnabled)
        
        if !style.headerScroll.isHiddenTitleDate {
            collectionView.frame.size.height = frame.height - style.headerScroll.heightTitleDate
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
    
    func scrollHeaderByTransform(_ transform: CGAffineTransform) {
        guard !transform.isIdentity else {
            guard let scrollDate = getScrollDate(date),
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
        scrollToDate(date, isAnimate: isAnimate)
        collectionView.reloadData()
    }
    
    func selectDate(offset: Int) {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return }
        
        setDate(nextDate)
    }
    
    func getDateByPointX(_ pointX: CGFloat) -> Date? {
        let startRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: startRect.origin.x + pointX, y: startRect.midY)) else { return nil }

        let day = days[indexPath.row]
        return day.date
    }
    
    private func setDateToTitle(_ date: Date?) {
        if let date = date, !style.headerScroll.isHiddenTitleDate {
            titleLabel.text = style.headerScroll.formatterTitle.string(from: date)
        }
    }
    
    private func createCollectionView(frame: CGRect, isScrollEnabled: Bool) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = isScrollEnabled
        collection.register(ScrollHeaderDayCell.self)
        return collection
    }
    
    private func scrollToDate(_ date: Date, isAnimate: Bool) {
        didSelectDate?(date, type)
        setDateToTitle(date)
        
        guard var indexPath = getMiddleIndexPath(), let middleDate = days[indexPath.row].date else { return }
        
        switch type {
        case .day:
            let minOffset = 4
            let maxOffset = 5
            guard middleDate.day - date.day >= minOffset || date.day - middleDate.day >= minOffset else {
                guard let scrollDate = getScrollDate(date),
                    let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                        && $0.date?.month == scrollDate.month
                        && $0.date?.day == scrollDate.day }) else { return }
                indexPath.row = idx
                break
            }
            
            if middleDate.day > date.day, minOffset...maxOffset ~= middleDate.day - date.day {
                indexPath.row -= 10
            } else if date.day > middleDate.day, minOffset...maxOffset ~= date.day - middleDate.day {
                indexPath.row += 4
            } else {
                guard let scrollDate = getScrollDate(date),
                           let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                               && $0.date?.month == scrollDate.month
                               && $0.date?.day == scrollDate.day }) else { return }
                indexPath.row = idx
            }
        case .week:
            guard let scrollDate = getScrollDate(date),
                       let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                           && $0.date?.month == scrollDate.month
                           && $0.date?.day == scrollDate.day }) else { return }

            indexPath.row = idx
        default:
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.collectionView.scrollToItem(at: indexPath, at: .left, animated: isAnimate)
        }
        
        if !self.isAnimate {
            self.isAnimate = true
        }
        
        if type == .day, !style.headerScroll.isHiddenTitleDate {
            UIView.animate(withDuration: 0.3) {
                self.titleLabel.transform = .identity
                self.titleLabel.alpha = 1
            }
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
        let newView = createCollectionView(frame: self.frame, isScrollEnabled: style.headerScroll.isScrollEnabled)
        newView.frame.origin.x = 0
        if !style.headerScroll.isHiddenTitleDate {
            newView.frame.size.height = self.frame.height - style.headerScroll.heightTitleDate
        }
        addSubview(newView)
        
        guard let scrollDate = getScrollDate(date),
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
    
    private func getScrollDate(_ date: Date) -> Date? {
        return style.startWeekDay == .sunday ? date.startSundayOfWeek : date.startMondayOfWeek
    }
    
    private func getMiddleIndexPath() -> IndexPath? {
        let rect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        return collectionView.indexPathForItem(at: CGPoint(x: rect.midX, y: rect.midY))
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScrollHeaderDayCell.identifier,
                                                      for: indexPath) as? ScrollHeaderDayCell ?? ScrollHeaderDayCell()
        let day = days[indexPath.row]
        cell.style = style
        cell.item = styleForDay(day)
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
        guard var indexPath = getMiddleIndexPath(), let scrollDate = days[indexPath.row].date else { return }
        
        if date.isSunday {
            switch style.startWeekDay {
            case .monday:
                indexPath.row += 3
            case .sunday:
                indexPath.row -= 3
            }
        } else if date.weekday > scrollDate.weekday {
            indexPath.row += date.weekday - scrollDate.weekday
        } else if scrollDate.weekday > date.weekday {
            indexPath.row -= scrollDate.weekday - date.weekday
        }
        
        guard let newMoveDate = days[indexPath.row].date else { return }
        
        date = newMoveDate
        didSelectDate?(newMoveDate, type)
        setDateToTitle(newMoveDate)
        collectionView.reloadData()
        
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch type {
        case .day:
            guard date != days[indexPath.row].date, let dateNew = days[indexPath.row].date else { return }
            
            date = dateNew
            didSelectDate?(date, .day)
            setDateToTitle(date)
            collectionView.reloadData()
        case .week:
            guard let dateTemp = days[indexPath.row].date else { return }
            
            date = dateTemp
            didSelectDate?(date, style.week.selectCalendarType)
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

extension ScrollDayHeaderView: DayStyleProtocol {
    typealias Model = DayStyle
    
    func styleForDay(_ day: Day) -> DayStyle {
        guard let item = dataSource?.willDisplayDate(day.date, events: day.events) else { return DayStyle(day, nil) }
        
        return DayStyle(day, item)
    }
}
