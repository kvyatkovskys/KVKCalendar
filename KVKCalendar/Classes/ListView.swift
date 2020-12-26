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
    }
    
    func reloadFrame(_ frame: CGRect) {
        
    }
    
    func reloadData(_ events: [Event]) {
        params.data.reloadEvents(events)
        tableView.reloadData()
    }
    
    func setDate(_ date: Date) {
        params.data.date = date
        
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
            return tableView.dequeueCell(indexPath: indexPath) { (cell: UITableViewCell) in
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueView { (view: UITableViewHeaderFooterView) in
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
