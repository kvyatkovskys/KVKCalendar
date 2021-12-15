//
//  ListView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

#if os(iOS)

import UIKit

public final class ListView: UIView, CalendarSettingProtocol {
    
    public struct Parameters {
        var style: Style
        let data: ListViewData
        weak var dataSource: CalendarDataSource?
        weak var delegate: CalendarDelegate?
        
        public init(style: Style, data: ListViewData, dataSource: CalendarDataSource?, delegate: CalendarDelegate?) {
            self.style = style
            self.data = data
            self.dataSource = dataSource
            self.delegate = delegate
        }
    }
    
    var style: Style {
        params.style
    }
    
    private var params: Parameters
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView()
        table.dataSource = self
        table.delegate = self
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        return table
    }()
    
    private var listStyle: ListViewStyle {
        params.style.list
    }
    
    public init(parameters: Parameters, frame: CGRect) {
        self.params = parameters
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateStyle(_ style: Style) {
        params.style = style
        setUI()
    }
    
    func setUI() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        backgroundColor = listStyle.backgroundColor
        tableView.backgroundColor = listStyle.backgroundColor
        tableView.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(tableView)
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        tableView.frame = CGRect(origin: .zero, size: frame.size)
    }
    
    func reloadData(_ events: [Event]) {
        params.data.reloadEvents(events)
        tableView.reloadData()
    }
    
    func showSkeletonVisible(_ visible: Bool) {
        params.data.isSkeletonVisible = visible
        tableView.reloadData()
    }
    
    func setDate(_ date: Date) {
        params.data.date = date
        
        guard !params.data.isSkeletonVisible else { return }
        
        if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month && $0.date.day == date.day }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year && $0.date.month == date.month }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.year == date.year }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: true)
        }
    }
    
}

extension ListView: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        params.data.numberOfSection()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        params.data.numberOfItemsInSection(section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !params.data.isSkeletonVisible else {
            return tableView.kvkDequeueCell { (cell: ListViewCell) in
                cell.setSkeletons(params.data.isSkeletonVisible)
            }
        }
        
        let event = params.data.event(indexPath: indexPath)
        if let cell = params.dataSource?.dequeueCell(dateParameter: .init(date: event.start), type: .list, view: tableView, indexPath: indexPath) as? UITableViewCell {
            return cell
        } else {
            return tableView.kvkDequeueCell(indexPath: indexPath) { (cell: ListViewCell) in
                cell.txt = event.textForList
                cell.dotColor = event.color?.value
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !params.data.isSkeletonVisible else {
            return tableView.kvkDequeueView { (view: ListViewHeader) in
                view.setSkeletons(params.data.isSkeletonVisible)
            }
        }
        
        let date = params.data.sections[section].date
        if let headerView = params.dataSource?.dequeueHeader(date: date, type: .list, view: tableView, indexPath: IndexPath(row: 0, section: section)) as? UIView {
            return headerView
        } else {
            return tableView.kvkDequeueView { (view: ListViewHeader) in
                view.title = params.data.titleOfHeader(section: section,
                                                       formatter: params.style.list.headerDateFormatter,
                                                       locale: params.style.locale)
                view.didTap = { [weak self] in
                    self?.params.delegate?.didSelectDates([date], type: .list, frame: view.frame)
                }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !params.data.isSkeletonVisible else {
            return 45
        }
        
        let event = params.data.event(indexPath: indexPath)
        if let height = params.delegate?.sizeForCell(event.start, type: .list)?.height {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard !params.data.isSkeletonVisible else {
            return 50
        }
        
        let date = params.data.sections[section].date
        if let height = params.delegate?.sizeForHeader(date, type: .list)?.height {
            return height
        } else if let height = params.style.list.heightHeaderView {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let event = params.data.event(indexPath: indexPath)
        let frameCell = tableView.cellForRow(at: indexPath)?.frame
        params.delegate?.didSelectEvent(event, type: .list, frame: frameCell)
    }
    
}

#endif
