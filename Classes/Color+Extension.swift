//
//  Color+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 01/10/2019.
//

import UIKit

extension UIColor {
    @available(iOS 13, *)
    static func useForStyle(dark: UIColor, white: UIColor) -> UIColor {
        return UIColor { (traitCollection: UITraitCollection) -> UIColor in
            if traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return white
            }
        }
    }
}
