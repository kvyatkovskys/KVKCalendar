//
//  EventListView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 13.03.2020.
//

import UIKit

final class EventListView: UIView {
    private lazy var tableView: UITableView = {
        let table = UITableView()
        return table
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.frame = frame
        addSubview(tableView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
