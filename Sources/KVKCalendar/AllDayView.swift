//
//  AllDayView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 20.05.2021.
//

import UIKit

final class AllDayView: UIView {
    
    struct Parameters {
        let date: Date?
        let events: [Event]
        var style: Style
        weak var dataSource: CalendarDataSource?
        weak var delegate: CalendarDelegate?
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 1
        return layout
    }()
    
    private var collectionView: UICollectionView?
    private var params: Parameters
    
    let items: [AllDayEvent]
    
    init(parameters: Parameters, frame: CGRect) {
        self.params = parameters
        
        let startEvents = parameters.events.map({ AllDayEvent(event: $0, date: $0.start) })
        let endEvents = parameters.events.map({ AllDayEvent(event: $0, date: $0.end) })
        let result = startEvents + endEvents
        let distinct = result.reduce([]) { (acc, item) -> [AllDayEvent] in
            guard acc.contains(where: { $0.date.day == item.date.day && $0.event.hash == item.event.hash }) else {
                return acc + [item]
            }
            return acc
        }
        self.items = distinct.filter({ $0.date.day == parameters.date?.day })
        
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calculateSize(index: IndexPath, view: UIView) -> CGSize {
        var newSize: CGSize
        if items.count == 1 {
            newSize = CGSize(width: view.bounds.width, height: params.style.allDay.height)
        } else if items.count % 2 == 0 {
            newSize = CGSize(width: view.bounds.width * 0.5, height: params.style.allDay.height)
        } else {
            if items.count == (index.row + 1) {
                newSize = CGSize(width: view.bounds.width, height: params.style.allDay.height)
            } else {
                newSize = CGSize(width: view.bounds.width * 0.5, height: params.style.allDay.height)
            }
        }
        
        newSize.width -= 1
        return newSize
    }
    
    private func setupView() {
        backgroundColor = params.style.allDay.backgroundColor
        titleLabel.removeFromSuperview()
        collectionView?.removeFromSuperview()
        collectionView = nil
        
        titleLabel.frame = CGRect(x: params.style.allDay.offsetX, y: 0,
                                  width: params.style.allDay.width - params.style.allDay.offsetX,
                                  height: params.style.allDay.height)
        titleLabel.font = params.style.allDay.fontTitle
        titleLabel.textColor = params.style.allDay.titleColor
        titleLabel.textAlignment = params.style.allDay.titleAlignment
        titleLabel.text = params.style.allDay.titleText
        
        let x = titleLabel.frame.width + titleLabel.frame.origin.x
        let collectionFrame = CGRect(origin: CGPoint(x: x, y: 0),
                                     size: CGSize(width: bounds.size.width - x, height: bounds.size.height))
        
        collectionView = UICollectionView(frame: collectionFrame, collectionViewLayout: layout)
        collectionView?.backgroundColor = .clear
        
        if collectionView?.dataSource == nil {
            collectionView?.dataSource = self
        }
        if collectionView?.delegate == nil {
            collectionView?.delegate = self
        }
        
        addSubview(titleLabel)
        if let view = collectionView {
            addSubview(view)
        }
    }
}

extension AllDayView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        return collectionView.dequeueCell(indexPath: indexPath) { (cell: AllDayEventCell) in
            cell.value = (params.style.allDay, item.event)
            cell.setRoundCorners(params.style.allDay.eventCorners, radius: params.style.allDay.eventCornersRadius)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calculateSize(index: indexPath, view: collectionView)
    }
}

extension AllDayView: CalendarSettingProtocol {
    
    var currentStyle: Style {
        params.style
    }
    
    func reloadFrame(_ frame: CGRect) {
        
    }
    
    func updateStyle(_ style: Style) {
        
    }
    
    func setUI() {
        setupView()
    }
    
}
