//
//  YearViewCalendar.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

final class YearViewCalendar: UIView {
    fileprivate var data: YearData
    fileprivate let style: Style
    weak var delegate: CalendarSelectDateDelegate?
    
    fileprivate lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.isPagingEnabled = true
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    init(data: YearData, frame: CGRect, style: Style) {
        self.data = data
        self.style = style
        super.init(frame: frame)
        collectionView.frame = frame
        addSubview(collectionView)
        
        collectionView.register(YearCollectionViewCell.self, forCellWithReuseIdentifier: YearCollectionViewCell.cellIdentifier)
        scrollToDate(date: data.moveDate, animation: false)
    }
    
    func setDate(date: Date) {
        data.moveDate = date
        scrollToDate(date: date, animation: true)
        collectionView.reloadData()
    }
    
    fileprivate func scrollToDate(date: Date, animation: Bool) {
        delegate?.didSelectCalendarDate(date, type: .year)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let idx = self.data.months.index(where: { $0.date.year == self.data.moveDate.year }) {
                self.collectionView.scrollToItem(at: IndexPath(row: idx, section: 0),
                                                 at: .top,
                                                 animated: animation)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        cell.selectDate = data.moveDate
        cell.title = month.name
        cell.days = data.addStartEmptyDay(days: month.days)
        return cell
    }
}

extension YearViewCalendar: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cells = collectionView.visibleCells as? [YearCollectionViewCell] ?? [YearCollectionViewCell()]
        let newMoveDate = cells.reduce([]) { (acc, month) -> [Date?] in
            var resultDate = acc
            if let day = month.days.filter({ $0.date?.month == data.moveDate.month && $0.date?.day == data.moveDate.day }).first {
                resultDate = [day.date]
            }
            return resultDate
            }
            .compactMap({ $0 })
            .first
        data.moveDate = newMoveDate ?? Date()
        delegate?.didSelectCalendarDate(newMoveDate, type: .year)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = data.months[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.moveDate.day).\(date.month).\(date.year)")
        delegate?.didSelectCalendarDate(newDate, type: .month)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
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
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.1) {
            cell?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widht = collectionView.frame.width / 4
        let height = collectionView.frame.height / 3
        return CGSize(width: widht - 10, height: height - 10)
    }
}
