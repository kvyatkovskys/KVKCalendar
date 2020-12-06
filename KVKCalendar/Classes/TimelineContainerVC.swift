//
//  TimelinePageContainerVC.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 05.12.2020.
//

import UIKit

final class TimelineContainerVC: UIViewController {
    
    var index: Int
    
    private let contentView: UIView
    
    init(index: Int, contentView: UIView) {
        self.index = index
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
    }

}
