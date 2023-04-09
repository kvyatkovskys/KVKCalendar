//
//  TimelinePageContainerVC.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 05.12.2020.
//

#if os(iOS)

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

final class TimelineContainerProxyVC: UIViewController {
    
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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let top = contentView.topAnchor.constraint(equalTo: view.topAnchor)
        let leading = contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bottom = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }

}

#endif
