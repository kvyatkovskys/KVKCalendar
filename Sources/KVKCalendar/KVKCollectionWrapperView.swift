//
//  KVKCollectionWrapperView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 2/18/24.
//

import SwiftUI

@available(iOS 17.0, *)
struct KVKCollectionWrapperView<Cell: View>: UIViewRepresentable {
    typealias UIViewType = UICollectionView
    
    struct Parameters {
        var monthData: KVKCalendar.MonthNewData
        var style: Style
    }
    
    var params: KVKCollectionWrapperView.Parameters
    let cell: (KVKCalendar.Day) -> Cell
    
    private var monthStyle: MonthStyle {
        params.style.month
    }
    
    init(params: KVKCollectionWrapperView.Parameters, @ViewBuilder cell: @escaping (KVKCalendar.Day) -> Cell) {
        self.params = params
        self.cell = cell
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = monthStyle.colorBackground
        view.isPagingEnabled = monthStyle.isPagingEnabled
        view.isScrollEnabled = monthStyle.isScrollEnabled
        view.dataSource = context.coordinator
        view.delegate = context.coordinator
        
        if monthStyle.isPrefetchingEnabled {
            view.prefetchDataSource = context.coordinator
            view.isPrefetchingEnabled = true
        }
        
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    @available(iOS 17.0, *)
    final class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
        
        private let parent: KVKCollectionWrapperView
        
        init(parent: KVKCollectionWrapperView) {
            self.parent = parent
        }
        
        private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
            switch direction {
            case .horizontal:
                let a = indexPath.item / parent.params.monthData.itemsInPage
                let b = indexPath.item / parent.params.monthData.rowsInPage - a * parent.params.monthData.columnsInPage
                let c = indexPath.item % parent.params.monthData.rowsInPage
                let newIdx = (c * parent.params.monthData.columnsInPage + b) + a * parent.params.monthData.itemsInPage
                return IndexPath(row: newIdx, section: indexPath.section)
            default:
                return indexPath
            }
        }
        
        private func getActualCachedDay(indexPath: IndexPath) -> MonthData.DayOfMonth {
            if let value = parent.params.monthData.days[indexPath] {
                return value
            } else {
                let index = getIndexForDirection(parent.monthStyle.scrollDirection, indexPath: indexPath)
                return parent.params.monthData.getDay(indexPath: index)
            }
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            parent.params.monthData.data.months.count
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.params.monthData.data.months[section].days.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let item = getActualCachedDay(indexPath: indexPath) 
            guard let day = item.day else { return UICollectionViewCell() }
            return collectionView.kvkDequeueCell(indexPath: item.indexPath) { (cell: UICollectionViewCell) in
                cell.contentConfiguration = UIHostingConfiguration {
                    parent.cell(day)
                }
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
            indexPaths.forEach {
                let indexPath = getIndexForDirection(parent.monthStyle.scrollDirection, indexPath: $0)
                let item = parent.params.monthData.getDay(indexPath: indexPath)
                parent.params.monthData.days[$0] = item
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let item = getActualCachedDay(indexPath: indexPath)
            let width: CGFloat
            let height: CGFloat
            
            let heightSectionHeader = parent.monthStyle.heightSectionHeader
            switch parent.monthStyle.scrollDirection {
            case .horizontal:
                var superViewWidth = collectionView.bounds.width
                if !parent.monthStyle.isHiddenSectionHeader && superViewWidth >= heightSectionHeader {
                    superViewWidth -= heightSectionHeader
                }
                width = superViewWidth / 7
                height = collectionView.frame.height / 6
            case .vertical:
                if collectionView.frame.width > 0 {
                    width = collectionView.frame.width / 7 - 0.2
                } else {
                    width = 0
                }
                
                var superViewHeight = collectionView.bounds.height
                if !parent.monthStyle.isHiddenSectionHeader && superViewHeight >= heightSectionHeader {
                    superViewHeight -= heightSectionHeader
                }
                
                height = superViewHeight / CGFloat(item.weeks)
            @unknown default:
                fatalError()
            }
            
            return CGSize(width: width, height: 200)
        }
        
        func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let month = parent.params.monthData.data.months[indexPath.section]
            let index = IndexPath(row: 0, section: indexPath.section)
            
            return collectionView.kvkDequeueView(indexPath: index) { (headerView: MonthHeaderView) in
                // headerView.value = (parent.monthStyle, month.date)
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            guard !parent.monthStyle.isHiddenSectionHeader else { return .zero }
            
            switch parent.monthStyle.scrollDirection {
            case .horizontal:
                return CGSize(width: parent.monthStyle.heightSectionHeader, height: collectionView.bounds.height)
            case .vertical:
                return CGSize(width: collectionView.bounds.width, height: parent.monthStyle.heightSectionHeader)
            @unknown default:
                fatalError()
            }
        }
        
    }
}
