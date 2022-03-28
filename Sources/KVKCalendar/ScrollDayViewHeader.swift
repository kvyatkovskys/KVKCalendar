//
//  ScrollDayHeaderView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class ScrollDayHeaderView: UIView {
    
    var didTrackScrollOffset: ((CGFloat?, Bool) -> Void)?
    var didSelectDate: ((Date?, CalendarType) -> Void)?
    var didChangeDay: ((TimelinePageView.SwitchPageType) -> Void)?
    
    struct Parameters {
        let frame: CGRect
        var days: [Day]
        var date: Date
        let type: CalendarType
        var style: Style
    }
    
    private var params: Parameters
    private var collectionView: UICollectionView!
    private var isAnimate = false
    private var lastContentOffset: CGFloat = 0
    private var trackingTranslation: CGFloat?
    
    private var days: [Day] {
        params.days
    }
    private var calendar: Calendar {
        params.style.calendar
    }
    private var type: CalendarType {
        params.type
    }
        
    var date: Date {
        get {
            params.date
        }
        set {
            params.date = newValue
            titleView?.date = newValue
        }
    }
    
    private var maxDays: Int {
        switch type {
        case .week:
            return style.week.maxDays
        default:
            return 7
        }
    }
    
    private var isFullyWeek: Bool {
        maxDays == 7
    }
    
    weak var dataSource: DisplayDataSource?
    
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    private var titleView: ScrollDayHeaderReusableView?
    
    init(parameters: Parameters) {
        self.params = parameters
        super.init(frame: parameters.frame)
        setUI()
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
    
    @discardableResult
    func calculateDateWithOffset(_ offset: Int, needScrollToDate: Bool) -> Date {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return date }
        
        date = nextDate
        if needScrollToDate {
            scrollToDate(date, isAnimate: true, isDelay: false)
        }
        
        collectionView.reloadData()
        return nextDate
    }
    
    func getDateByPointX(_ pointX: CGFloat) -> Date? {
        let startRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: startRect.origin.x + pointX, y: startRect.midY)) else { return nil }

        let day = days[indexPath.row]
        return day.date
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
        guard let scrollDate = getScrollDate(date),
              let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                                            && $0.date?.month == scrollDate.month
                                            && $0.date?.day == scrollDate.day }) else { return }
        
        if isDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .left,
                                                 animated: isAnimate)
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
    
    var style: Style {
        params.style
    }
    
    func setUI() {
        subviews.forEach { $0.removeFromSuperview() }
        var newFrame = frame
        newFrame.origin.y = 0
        setupViews(mainFrame: &newFrame)
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width - self.frame.origin.x
        var newFrame = self.frame
        newFrame.origin.y = 0
        
        collectionView.removeFromSuperview()
        setupViews(mainFrame: &newFrame)
        
        guard let scrollDate = getScrollDate(date),
              let idx = days.firstIndex(where: { $0.date?.year == scrollDate.year
                  && $0.date?.month == scrollDate.month
                  && $0.date?.day == scrollDate.day }) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0), at: .left, animated: false)
            self.lastContentOffset = self.collectionView.contentOffset.x
        }
        collectionView.reloadData()
    }
    
    func updateStyle(_ style: Style) {
        params.style = style
        setUI()
        scrollToDate(date, isAnimate: false)
    }
    
    private func setupViews(mainFrame: inout CGRect) {
        if let customView = dataSource?.willDisplayHeaderView(date: date, frame: mainFrame, type: type) {
            params.days = []
            collectionView.reloadData()
            addSubview(customView)
        } else {
            calculateFrameForCollectionViewIfNeeded(&mainFrame)
            collectionView = createCollectionView(frame: mainFrame,
                                                  isScrollEnabled: style.headerScroll.isScrollEnabled)
            addSubview(collectionView)
            addTitleHeaderIfNeeded(frame: mainFrame)
        }
    }
    
    private func addTitleHeaderIfNeeded(frame: CGRect) {
        titleView?.removeFromSuperview()
        guard !style.headerScroll.isHiddenSubview else { return }
        
        let titleFrame: CGRect
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            titleFrame = CGRect(origin: CGPoint(x: 5, y: frame.height),
                                size: CGSize(width: frame.width - 10, height: style.headerScroll.heightSubviewHeader))
        default:
            titleFrame = CGRect(origin: CGPoint(x: 5, y: 0),
                                size: CGSize(width: frame.width - 10, height: style.headerScroll.heightSubviewHeader))
        }
        
        titleView = ScrollDayHeaderReusableView(frame: titleFrame)
        titleView?.style = style
        titleView?.date = date
        if let view = titleView {
            addSubview(view)
        }
    }
    
    private func calculateFrameForCollectionViewIfNeeded(_ frame: inout CGRect) {
        guard !style.headerScroll.isHiddenSubview else { return }
            
        frame.size.height = style.headerScroll.heightHeaderWeek
        if UIDevice.current.userInterfaceIdiom != .phone {
            frame.origin.y = style.headerScroll.heightSubviewHeader
        }
    }
    
    private func getScrollDate(_ date: Date) -> Date? {
        guard isFullyWeek else {
            return date
        }
        
        return style.startWeekDay == .sunday ? date.startSundayOfWeek : date.startMondayOfWeek
    }
}

extension ScrollDayHeaderView: UICollectionViewDataSource {
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = days[indexPath.row]
        
        if let cell = dataSource?.dequeueCell(dateParameter: .init(date: day.date), type: type, view: collectionView, indexPath: indexPath) as? UICollectionViewCell {
            return cell
        } else {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return collectionView.kvkDequeueCell(indexPath: indexPath) { (cell: DayPhoneCell) in
                    cell.phoneStyle = style
                    cell.day = day
                    cell.selectDate = date
                }
            default:
                return collectionView.kvkDequeueCell(indexPath: indexPath) { (cell: DayPadCell) in
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
            calculateDateWithOffset(-maxDays, needScrollToDate: false)
            didSelectDate?(date, type)
        } else if targetOffset.x > lastContentOffset {
            didChangeDay?(.next)
            calculateDateWithOffset(maxDays, needScrollToDate: false)
            didSelectDate?(date, type)
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
        case .week:
            guard let dateNew = days[indexPath.row].date else { return }
            
            date = dateNew
        default:
            break
        }
        
        didSelectDate?(date, type)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / CGFloat(maxDays)
        return CGSize(width: width, height: collectionView.bounds.height)
    }
}

#endif
