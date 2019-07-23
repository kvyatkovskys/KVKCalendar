//
//  YearViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class YearViewCalendar: UIView {
    private var data: YearData
    private var style: Style
    private var animated: Bool = false
    private var collectionView: UICollectionView!
    
    weak var delegate: CalendarPrivateDelegate?
    
    private let layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        return layout
    }()
    
    private lazy var headerView: YearHeaderView = {
        let view = YearHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: style.yearStyle.heightTitleHeader))
        view.style = style
        return view
    }()
    
    init(data: YearData, frame: CGRect, style: Style) {
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
    
    private func createCollectionView(frame: CGRect, style: YearStyle)  -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.register(YearCollectionViewCell.self,
                            forCellWithReuseIdentifier: YearCollectionViewCell.cellIdentifier)
        return collection
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .year, frame: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                if let idx = self.data.months.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month }) {
                    self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                     at: .top,
                                                     animated: animated)
                }
                return
            }
            if let idx = self.data.months.firstIndex(where: { $0.date.year == date.year }) {
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

extension YearViewCalendar: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(self.frame)
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame, style: style.yearStyle)
        collectionView.frame.origin.y = style.yearStyle.heightTitleHeader
        collectionView.frame.size.height -= style.yearStyle.heightTitleHeader
        addSubview(collectionView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                if let idx = self.data.months.firstIndex(where: { $0.date.year == self.data.date.year && $0.date.month == self.data.date.month }) {
                    self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                     at: .top,
                                                     animated: false)
                }
                return
            }
            if let idx = self.data.months.firstIndex(where: { $0.date.year == self.data.date.year }) {
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
        
        collectionView = createCollectionView(frame: frame, style: style.yearStyle)
        collectionView.frame.origin.y = style.yearStyle.heightTitleHeader
        collectionView.frame.size.height -= style.yearStyle.heightTitleHeader
        addSubview(collectionView)
        addSubview(headerView)
    }
}

extension YearViewCalendar: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: YearCollectionViewCell.cellIdentifier,
                                                      for: indexPath) as? YearCollectionViewCell ?? YearCollectionViewCell()
        let month = data.months[indexPath.row]
        cell.style = style
        cell.selectDate = data.date
        cell.title = month.name
        cell.days = data.addStartEmptyDay(days: month.days, startDay: style.startWeekDay)
        return cell
    }
}

extension YearViewCalendar: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [YearCollectionViewCell] ?? [YearCollectionViewCell()]
        let newMoveDate = cells.reduce([]) { (acc, month) -> [Date?] in
            var resultDate = acc
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                if let day = month.days.filter({ $0.date?.day == data.date.day }).first {
                    resultDate = [day.date]
                }
                return resultDate
            }
            if let day = month.days.filter({ $0.date?.month == data.date.month && $0.date?.day == data.date.day }).first {
                resultDate = [day.date]
            }
            return resultDate
            }
            .compactMap({ $0 })
            .first
        data.date = newMoveDate ?? Date()
        headerView.date = newMoveDate
        delegate?.didSelectCalendarDate(newMoveDate, type: .year, frame: nil)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        let date = data.months[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.date.day).\(date.month).\(date.year)")
        data.date = newDate ?? Date()
        headerView.date = newDate
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectCalendarDate(newDate, type: style.yearStyle.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard UIDevice.current.userInterfaceIdiom == .pad, style.monthStyle.isAnimateSelection else { return }
        
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
        guard UIDevice.current.userInterfaceIdiom == .pad, style.monthStyle.isAnimateSelection else { return }
        
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht: CGFloat
        let height: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            widht = collectionView.frame.width / 4
            height = collectionView.frame.height / 3
        } else {
            widht = collectionView.frame.width
            height = collectionView.frame.height
        }
        return CGSize(width: widht - 10, height: height - 10)
    }
}
