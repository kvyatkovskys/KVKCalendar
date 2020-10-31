//
//  CalendarContentVC.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 31.10.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 13.0.0, *)
class CalendarContentVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let childView = UIHostingController(rootView: CalendarViewSwiftUI())
        addChild(childView)
        childView.view.frame = view.bounds
        addConstrained(subview: childView.view)
        childView.didMove(toParent: self)
    }
    
    func addConstrained(subview: UIView) {
        view.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}
