//
//  View+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 15/06/2019.
//

import UIKit

extension UIView {
    static func identityViews(duration: TimeInterval = 0.4, delay: TimeInterval = 0.07, _ views: [UIView], action: @escaping (() -> Void) = {}) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
            views.forEach { (view) in
                view.transform = .identity
            }
            action()
        }, completion: nil)
    }
}
