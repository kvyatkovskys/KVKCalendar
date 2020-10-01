//
//  ScrollDayHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class ScrollDayHeaderView: UIView {
    var didTrackScrollOffset: ((CGFloat, Bool) -> Void)?
    var didSelectDate: ((Date?, CalendarType) -> Void)?
    
    private let days: [Day]
    private var date: Date
    private var style: Style
    private var collectionView: UICollectionView!
    private var isAnimate: Bool = false
    private let type: CalendarType
    private let calendar: Calendar
    private var lastContentOffset: CGFloat = 0
    private var trackingTranslation: CGFloat?
    
    weak var dataSource: DisplayDataSource?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = style.headerScroll.titleDateAligment
        label.textColor = style.headerScroll.colorTitleDate
        label.font = style.headerScroll.titleDateFont
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
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            newFrame.origin.y = 0
            
            if !style.headerScroll.isHiddenTitleDate {
                titleLabel.frame = CGRect(x: 10, y: frame.height - style.headerScroll.heightTitleDate - 5, width: frame.width - 20, height: style.headerScroll.heightTitleDate - 5)
                
                setDateToTitle(date)
                addSubview(titleLabel)
                
                newFrame.size.height = frame.height - titleLabel.frame.height
            }
        default:
            if !style.headerScroll.isHiddenTitleDate {
                titleLabel.frame = CGRect(x: 10, y: 5, width: frame.width - 20, height: style.headerScroll.heightTitleDate - 5)
                
                setDateToTitle(date)
                addSubview(titleLabel)
                
                newFrame.origin.y = titleLabel.frame.height + 5
                newFrame.size.height = frame.height - newFrame.origin.y
            } else {
                newFrame.origin.y = 0
            }
        }
        
        collectionView = createCollectionView(frame: newFrame, isScrollEnabled: style.headerScroll.isScrollEnabled)
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
    
    func setDate(_ date: Date, isDelay: Bool = true) {
        self.date = date
        scrollToDate(date, isAnimate: isAnimate, isDelay: isDelay)
        collectionView.reloadData()
    }
    
    func selectDate(offset: Int) {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return }
        
        if !style.headerScroll.isHiddenTitleDate && style.headerScroll.isAnimateTitleDate {
            let value: CGFloat
            if offset < 0 {
                value = -40
            } else {
                value = 40
            }
            titleLabel.transform = CGAffineTransform(translationX: value, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.titleLabel.transform = CGAffineTransform.identity
            })
        }
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
        let offsetX: CGFloat
        
        switch type {
        case .week:
            offsetX = style.timeline.widthTime + style.timeline.offsetTimeX + style.timeline.offsetLineLeft
        default:
            offsetX = 0
        }
        
        let newFrame = CGRect(x: offsetX, y: frame.origin.y, width: frame.width - offsetX, height: frame.height)
        let collection = UICollectionView(frame: newFrame, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = isScrollEnabled
        collection.register(ScrollHeaderDayCell.self)
        return collection
    }
    
    private func scrollToDate(_ date: Date, isAnimate: Bool, isDelay: Bool = true) {
        didSelectDate?(date, type)
        setDateToTitle(date)
        
        guard let scrollDate = getScrollDate(date),
              let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                                            && $0.date?.month == scrollDate.month
                                            && $0.date?.day == scrollDate.day }) else { return }
        
        if isDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0), at: .left, animated: isAnimate)
            }
        } else {
            collectionView.scrollToItem(at: IndexPath(row: idx, section: 0), at: .left, animated: isAnimate)
        }
        
        if !self.isAnimate {
            self.isAnimate = true
        }
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScrollDayHeaderView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width - self.frame.origin.x
        var newFrame = self.frame
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            newFrame.origin.y = 0
            
            if !style.headerScroll.isHiddenTitleDate {
                titleLabel.frame = CGRect(x: 10, y: self.frame.height - style.headerScroll.heightTitleDate - 5, width: self.frame.width - 20, height: style.headerScroll.heightTitleDate - 5)
                
                setDateToTitle(date)
                addSubview(titleLabel)
                
                newFrame.size.height = self.frame.height - titleLabel.frame.height
            }
        default:
            if !style.headerScroll.isHiddenTitleDate {
                titleLabel.frame = CGRect(x: 10, y: 5, width: self.frame.width - 20, height: titleLabel.frame.height)
                newFrame.origin.y = titleLabel.frame.height + 5
                newFrame.size.height = frame.height - newFrame.origin.y
            } else {
                newFrame.origin.y = 0
            }
        }
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: newFrame, isScrollEnabled: style.headerScroll.isScrollEnabled)
        addSubview(collectionView)
        
        guard let scrollDate = getScrollDate(date),
            let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                && $0.date?.month == scrollDate.month
                && $0.date?.day == scrollDate.day }) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0), at: .left, animated: false)
            self.lastContentOffset = self.collectionView.contentOffset.x
        }
        collectionView.reloadData()
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
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        let velocity = scrollView.panGestureRecognizer.velocity(in: collectionView)
        
        if trackingTranslation != translation.x {
            trackingTranslation = translation.x
            
            didTrackScrollOffset?(translation.x, false)
            
            let translationLimit: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 160 : 300
            let velocityLimit: CGFloat = 1000
            
            if translation.x > translationLimit || velocity.x > velocityLimit {
                scrollView.panGestureRecognizer.state = .cancelled
            } else if translation.x < -translationLimit || velocity.x < -velocityLimit {
                scrollView.panGestureRecognizer.state = .cancelled
            }
        }
        
        guard lastContentOffset == 0 else { return }
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        let velocity = scrollView.panGestureRecognizer.velocity(in: collectionView)
        
        didTrackScrollOffset?(0, true)
        lastContentOffset = scrollView.contentOffset.x
        
        let translationLimit: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 160 : 300
        let velocityLimit: CGFloat = 300
        
        guard let value = trackingTranslation else { return }
        
        if value > translationLimit || velocity.x > velocityLimit  {
            selectDate(offset: -7)
        } else if value < -translationLimit || velocity.x < -velocityLimit {
            selectDate(offset: 7)
        }
        
        trackingTranslation = translation.x
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
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
