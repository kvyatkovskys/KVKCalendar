//
//  YearView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class YearView: UIView {
    private var data: YearData
    private var style: Style
    private var animated: Bool = false
    private var collectionView: UICollectionView!
    
    weak var delegate: CalendarDataProtocol?
    weak var dataSource: DisplayDataSource?
    
    private let layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        
        let offset: CGFloat
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            offset = 5
        default:
            offset = 10
        }
        
        layout.minimumLineSpacing = offset
        layout.minimumInteritemSpacing = offset
        return layout
    }()
    
    private func scrollDirection(month: Int) -> UICollectionView.ScrollPosition {
        switch month {
        case 1...4:
            return .top
        case 5...8:
            return .centeredVertically
        default:
            return .bottom
        }
    }
    
    private lazy var headerView: YearHeaderView = {
        let view = YearHeaderView(frame: CGRect(x: 0, y: 0, width: frame.width, height: style.year.heightTitleHeader))
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
        return collection
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .year, frame: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.months.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month }) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: self.scrollDirection(month: date.month),
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

extension YearView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        headerView.reloadFrame(self.frame)
        
        collectionView.removeFromSuperview()
        collectionView = createCollectionView(frame: self.frame, style: style.year)
        collectionView.frame.origin.y = style.year.heightTitleHeader
        collectionView.frame.size.height -= style.year.heightTitleHeader
        addSubview(collectionView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.months.firstIndex(where: { $0.date.year == self.data.date.year && $0.date.month == self.data.date.month }) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: self.scrollDirection(month: self.data.date.month),
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
        
        collectionView = createCollectionView(frame: frame, style: style.year)
        collectionView.frame.origin.y = style.year.heightTitleHeader
        collectionView.frame.size.height -= style.year.heightTitleHeader
        addSubview(collectionView)
        addSubview(headerView)
    }
}

extension YearView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let month = data.months[indexPath.row]
        
        if let cell = dataSource?.dequeueDateCell(date: month.date, type: .year, collectionView: collectionView, indexPath: indexPath) {
            return cell
        } else {
            return collectionView.dequeueCell(indexPath: indexPath) { (cell: YearPadCell) in
                cell.style = style
                cell.selectDate = data.date
                cell.title = month.name
                cell.date = month.date
                cell.days = month.days
            }
        }
    }
}

extension YearView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard style.year.isAutoSelectDateScrolling else { return }
        
        let cells = collectionView.indexPathsForVisibleItems
        let dates = cells.compactMap { data.months[$0.row].date }
        delegate?.didDisplayCalendarEvents([], dates: dates, type: .year)
        let newMoveDate = dates.first(where: { $0.month == data.date.month })
        headerView.date = newMoveDate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = data.months[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.date.day).\(date.month).\(date.year)")
        data.date = newDate ?? Date()
        headerView.date = newDate
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectCalendarDate(newDate, type: style.year.selectCalendarType, frame: frame)
        collectionView.reloadData()
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
        
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht: CGFloat
        let height: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            widht = (collectionView.frame.width / 4) - 10
            height = (collectionView.frame.height / 3) - 10
        } else {
            widht = (collectionView.frame.width / 3) - 5
            height = (collectionView.frame.height / 4) - 5
        }
        return CGSize(width: widht, height: height)
    }
}
