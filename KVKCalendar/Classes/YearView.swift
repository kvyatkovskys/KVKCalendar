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
    
    private lazy var layout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = data.style.year.scrollDirection
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
        let month = data.sections[indexPath.section].months[indexPath.row]
        
        if let cell = dataSource?.dequeueDateCell(date: month.date, type: .year, collectionView: collectionView, indexPath: indexPath) {
            return cell
        } else {
            return collectionView.dequeueCell(indexPath: indexPath) { (cell: YearCell) in
                cell.style = data.style
                cell.selectDate = data.date
                cell.title = month.name
                cell.date = month.date
                cell.days = month.days
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueView(indexPath: indexPath) { (headerView: YearHeaderView) in
            headerView.style = data.style
            headerView.date = data.sections[indexPath.section].date
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
        let date = data.sections[indexPath.section].months[indexPath.row].date
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
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard data.style.year.isAnimateSelection else { return }
        
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
        guard data.style.year.isAnimateSelection else { return }
        
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let size = delegate?.sizeForCell(data.sections[indexPath.section].months[indexPath.row].date, type: .year) {
            return size
        }
        
        let widht: CGFloat
        let height: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            widht = (collectionView.frame.width / 4) - 5
            height = (collectionView.frame.height - data.style.year.heightTitleHeader) / 3
        } else {
            widht = (collectionView.frame.width / 3) - 5
            height = (collectionView.frame.height - data.style.year.heightTitleHeader) / 4
        }
        return CGSize(width: widht, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: data.style.year.heightTitleHeader)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}
