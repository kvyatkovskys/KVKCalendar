//
//  Calendar+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

extension UIStackView {
    func addBackground(color: UIColor) {
        let view = UIView(frame: bounds)
        view.backgroundColor = color
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(view, at: 0)
    }
}

extension Array {
    func split(half: Int) -> (left: [Element], right: [Element]) {
        let leftSplit = self[0..<half]
        let rightSplit = self[half..<count]
        return (Array(leftSplit), Array(rightSplit))
    }
}

extension Collection {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UICollectionView {
    func register(_ cell: UICollectionViewCell.Type) {
        register(cell, forCellWithReuseIdentifier: cell.identifier)
    }
}

extension UICollectionViewCell {
    static var identifier: String {
        return String(describing: self)
    }
}

extension UIColor {
    @available(iOS 13, *)
    static func useForStyle(dark: UIColor, white: UIColor) -> UIColor {
        return UIColor { (traitCollection: UITraitCollection) -> UIColor in
            return traitCollection.userInterfaceStyle == .dark ? dark : white
        }
    }
}

extension UIScreen {
    static var isDarkMode: Bool {
        if #available(iOS 12.0, *) {
            return main.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
}

extension UIView {
    func setRoundCorners(_ corners: UIRectCorner = .allCorners, radius: CGSize) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: radius)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func snapshot(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
        return image
    }
}
