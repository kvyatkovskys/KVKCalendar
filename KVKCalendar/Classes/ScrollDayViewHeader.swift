//
//  ScrollDayHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class ScrollDayHeaderView: UIView {
    
    var didTrackScrollOffset: ((CGFloat?, Bool) -> Void)?
    var didSelectDate: ((Date?, CalendarType) -> Void)?
    var didChangeDay: ((TimelinePageView.SwitchPageType) -> Void)?
    
    private let days: [Day]
    private var date: Date
    private var style: Style
    private var collectionView: UICollectionView!
    private var isAnimate: Bool = false
    private let type: CalendarType
    private let calendar: Calendar
    private var lastContentOffset: CGFloat = 0
    private var trackingTranslation: CGFloat?
    private var subviewCustomHeader: UIView?
    
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
    
    private var subviewFrameForDevice: CGRect {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return CGRect(x: 10, y: frame.height - style.headerScroll.heightSubviewHeader - 5, width: frame.width - 20, height: style.headerScroll.heightSubviewHeader - 5)
        default:
            return CGRect(x: 10, y: 5, width: frame.width - 20, height: style.headerScroll.heightSubviewHeader - 5)
        }
    }
    
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
            
            if !style.headerScroll.isHiddenSubview {
                if let subviewHeader = dataSource?.willDisplayHeaderSubview(date: date, frame: subviewFrameForDevice, type: type) {
                    subviewCustomHeader = subviewHeader
                    addSubview(subviewHeader)
                } else {
                    titleLabel.frame = subviewFrameForDevice
                    setDateToTitle(date)
                    addSubview(titleLabel)
                }
                
                newFrame.size.height = frame.height - subviewFrameForDevice.height
            }
        default:
            if !style.headerScroll.isHiddenSubview {
                if let subviewHeader = dataSource?.willDisplayHeaderSubview(date: date, frame: subviewFrameForDevice, type: type) {
                    subviewCustomHeader = subviewHeader
                    addSubview(subviewHeader)
                } else {
                    titleLabel.frame = subviewFrameForDevice
                    setDateToTitle(date)
                    addSubview(titleLabel)
                }
                
                newFrame.origin.y = subviewFrameForDevice.height + 5
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
    
    func selectDate(offset: Int, needScrollToDate: Bool) {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return }
        
        if !style.headerScroll.isHiddenSubview && style.headerScroll.isAnimateTitleDate && titleLabel.superview != nil {
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
        
        if subviewCustomHeader != nil, let newSubview = dataSource?.willDisplayHeaderSubview(date: nextDate, frame: subviewFrameForDevice, type: type) {
            subviewCustomHeader?.removeFromSuperview()
            subviewCustomHeader = newSubview
            addSubview(newSubview)
        }
        
        date = nextDate
        if needScrollToDate {
            scrollToDate(date, isAnimate: true, isDelay: false)
        } else {
            selectDate(date, type: type)
        }
        collectionView.reloadData()
    }
    
    func getDateByPointX(_ pointX: CGFloat) -> Date? {
        let startRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: startRect.origin.x + pointX, y: startRect.midY)) else { return nil }

        let day = days[indexPath.row]
        return day.date
    }
    
    private func setDateToTitle(_ date: Date?) {
        if let date = date, !style.headerScroll.isHiddenSubview {
            titleLabel.text = date.titleForLocale(style.locale, formatter: style.headerScroll.titleFormatter)
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
        return collection
    }
    
    private func scrollToDate(_ date: Date, isAnimate: Bool, isDelay: Bool = true) {
        selectDate(date, type: type)
        
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
    
    private func selectDate(_ date: Date, type: CalendarType) {
        didSelectDate?(date, type)
        
        if let newSubview = dataSource?.willDisplayHeaderSubview(date: date, frame: subviewFrameForDevice, type: type) {
            subviewCustomHeader?.removeFromSuperview()
            subviewCustomHeader = newSubview
            addSubview(newSubview)
        } else {
            subviewCustomHeader?.removeFromSuperview()
            subviewCustomHeader = nil
            
            setDateToTitle(date)
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
            
            if !style.headerScroll.isHiddenSubview {
                subviewCustomHeader?.removeFromSuperview()
                titleLabel.removeFromSuperview()
                
                if let subviewHeader = dataSource?.willDisplayHeaderSubview(date: date, frame: subviewFrameForDevice, type: type) {
                    subviewCustomHeader = subviewHeader
                    addSubview(subviewHeader)
                } else{
                    titleLabel.frame = subviewFrameForDevice
                    setDateToTitle(date)
                    addSubview(titleLabel)
                }
                
                newFrame.size.height = (self.frame.height - subviewFrameForDevice.height) - subviewFrameForDevice.origin.x
            }
        default:
            if !style.headerScroll.isHiddenSubview {
                subviewCustomHeader?.removeFromSuperview()
                titleLabel.removeFromSuperview()
                
                if let subviewHeader = dataSource?.willDisplayHeaderSubview(date: date, frame: subviewFrameForDevice, type: type) {
                    subviewCustomHeader = subviewHeader
                    addSubview(subviewHeader)
                } else {
                    titleLabel.frame = subviewFrameForDevice
                    setDateToTitle(date)
                    addSubview(titleLabel)
                }
                newFrame.origin.y = subviewFrameForDevice.height + 5
                newFrame.size.height = self.frame.height - newFrame.origin.y
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
}

extension ScrollDayHeaderView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = days[indexPath.row]
        
        if let cell = dataSource?.dequeueDateCell(date: day.date, type: type, collectionView: collectionView, indexPath: indexPath) {
            return cell
        } else {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return collectionView.dequeueCell(indexPath: indexPath) { (cell: DayPhoneCell) in
                    cell.phoneStyle = style
                    cell.day = day
                    cell.selectDate = date
                }
            default:
                return collectionView.dequeueCell(indexPath: indexPath) { (cell: DayPadCell) in
                    cell.padStyle = style
                    cell.day = day
                    cell.selectDate = date
                }
            }
        }
    }
}

extension ScrollDayHeaderView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        
        if trackingTranslation != translation.x {
            trackingTranslation = translation.x
            didTrackScrollOffset?(translation.x, false)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        trackingTranslation = translation.x
        
        let targetOffset = targetContentOffset.pointee

        if targetOffset.x == lastContentOffset {
            didTrackScrollOffset?(translation.x, true)
        } else if targetOffset.x < lastContentOffset {
            didChangeDay?(.previous)
            selectDate(offset: -7, needScrollToDate: false)
        } else if targetOffset.x > lastContentOffset {
            didChangeDay?(.next)
            selectDate(offset: 7, needScrollToDate: false)
        }
        
        lastContentOffset = targetOffset.x
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch type {
        case .day:
            guard date != days[indexPath.row].date, let dateNew = days[indexPath.row].date else { return }
            
            date = dateNew
            selectDate(date, type: .day)
        case .week:
            guard let dateNew = days[indexPath.row].date else { return }
            
            date = dateNew
            selectDate(date, type: style.week.selectCalendarType)
        default:
            break
        }
        
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht = collectionView.frame.width / 7
        let height = collectionView.frame.height
        return CGSize(width: widht, height: height)
    }
}
