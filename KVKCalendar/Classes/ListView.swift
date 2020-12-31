//
//  ListView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

import UIKit

final class ListView: UIView, CalendarSettingProtocol {
    
    struct Parameters {
        let style: Style
        let data: ListViewData
        weak var dataSource: DisplayDataSource?
        weak var delegate: DisplayDelegate?
    }
    
    private let params: Parameters
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView()
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.params = parameters
        super.init(frame: frame)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUI() {
        backgroundColor = .white
        tableView.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(tableView)
        setDate(params.data.date)
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        tableView.frame = CGRect(origin: .zero, size: frame.size)
    }
    
    func reloadData(_ events: [Event]) {
        params.data.reloadEvents(events)
        tableView.reloadData()
    }
    
    func setDate(_ date: Date) {
        params.delegate?.didSelectCalendarDate(date, type: .list, frame: nil)
        params.data.date = date
        
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return params.data.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return params.data.numberOfItemsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = params.data.event(indexPath: indexPath)
        if let cell = params.dataSource?.dequeueListCell(date: event.start, tableView: tableView, indexPath: indexPath) {
            return cell
        } else {
            return tableView.dequeueCell(indexPath: indexPath) { (cell: ListViewCell) in
                cell.txt = event.textForList
                cell.dotColor = event.color?.value
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let date = params.data.sections[section].date
        if let headerView = params.dataSource?.dequeueListHeader(date: date, tableView: tableView, section: section) {
            return headerView
        } else {
            return tableView.dequeueView { (view: ListViewHeader) in
                view.title = params.data.titleOfHeader(section: section)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let event = params.data.event(indexPath: indexPath)
        if let height = params.delegate?.sizeForCell(event.start, type: .list)?.height {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let date = params.data.sections[section].date
        if let height = params.delegate?.sizeForHeader(date, type: .list)?.height {
            return height
        } else {
            return params.style.list.heightHeaderView
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let event = params.data.event(indexPath: indexPath)
        let frameCell = tableView.cellForRow(at: indexPath)?.frame
        params.delegate?.didSelectCalendarEvent(event, frame: frameCell)
    }
}
