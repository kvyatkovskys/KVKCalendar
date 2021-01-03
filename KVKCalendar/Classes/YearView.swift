//
//  YearView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class YearView: UIView {
    private var data: YearData
    private var animated: Bool = false
    private var collectionView: UICollectionView?
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = data.style.year.scrollDirection
        
        switch data.style.year.scrollDirection {
        case .horizontal:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        case .vertical:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 5
        @unknown default:
            fatalError()
        }
        
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
    
    init(data: YearData, frame: CGRect) {
        self.data = data
        super.init(frame: frame)
        setUI()
    }
    
    func setDate(_ date: Date) {
        data.date = date
        scrollToDate(date: date, animated: animated)
        collectionView?.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: YearStyle)  -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return collection
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        delegate?.didSelectCalendarDate(date, type: .year, frame: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.year == date.year }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: date.month),
                                                  animated: animated)
            }
        }
        if !self.animated {
            self.animated = true
        }
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / data.itemsInPage
            let b = indexPath.item / data.rowsInPage - a * data.columnsInPage
            let c = indexPath.item % data.rowsInPage
            let newIdx = (c * data.columnsInPage + b) + a * data.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension YearView: CalendarSettingProtocol {
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        
        collectionView?.removeFromSuperview()
        collectionView = nil
        collectionView = createCollectionView(frame: self.frame, style: data.style.year)
        
        if let viewTemp = collectionView {
            addSubview(viewTemp)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.year == self.data.date.year }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: self.data.date.month),
                                                  animated: false)
            }
        }
        
        collectionView?.reloadData()
    }
    
    func updateStyle(_ style: Style) {
        self.data.style = style
        setUI()
        setDate(data.date)
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        collectionView = nil
        collectionView = createCollectionView(frame: frame, style: data.style.year)
        
        if let viewTemp = collectionView {
            addSubview(viewTemp)
        }
    }
}

extension YearView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.sections[section].months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let month = data.sections[index.section].months[index.row]
        
        if let cell = dataSource?.dequeueDateCell(date: month.date, type: .year, collectionView: collectionView, indexPath: index) {
            return cell
        } else {
            return collectionView.dequeueCell(indexPath: index) { (cell: YearCell) in
                cell.style = data.style
                cell.selectDate = data.date
                cell.title = month.name
                cell.date = month.date
                cell.days = month.days
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        return collectionView.dequeueView(indexPath: index) { (headerView: YearHeaderView) in
            headerView.style = data.style
            headerView.date = data.sections[index.section].date
        }
    }
}

extension YearView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard data.style.year.isAutoSelectDateScrolling else { return }
        
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let dates = cells.compactMap { data.sections[$0.section].months[$0.row].date }
        delegate?.didDisplayCalendarEvents([], dates: dates, type: .year)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let date = data.sections[index.section].months[index.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.date.day).\(date.month).\(date.year)")
        data.date = newDate ?? Date()
        collectionView.reloadData()
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectCalendarDate(newDate, type: data.style.year.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        if let size = delegate?.sizeForCell(data.sections[index.section].months[index.row].date, type: .year) {
            return size
        }
        
        let widht: CGFloat
        let height: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            widht = (collectionView.frame.width / 4) - layout.minimumInteritemSpacing
            height = (collectionView.frame.height - data.style.year.heightTitleHeader) / 3
        } else {
            widht = (collectionView.frame.width / 3) - layout.minimumInteritemSpacing
            height = (collectionView.frame.height - data.style.year.heightTitleHeader) / 4
        }
        return CGSize(width: widht, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch data.style.year.scrollDirection {
        case .horizontal:
            return .zero
        case .vertical:
            return CGSize(width: collectionView.bounds.width, height: data.style.year.heightTitleHeader)
        @unknown default:
            fatalError()
        }
    }
}
