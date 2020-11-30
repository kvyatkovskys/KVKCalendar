//
//  Calendar+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private enum AssociatedKeys {
    static var timer: UInt8 = 0
}

/// Any object can start and stop delayed action for key
protocol CalendarTimer: class {}

extension CalendarTimer {
    
    private var timers: [String: Timer] {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.timer) as? [String: Timer] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func stopTimer(_ key: String = "Timer") {
        timers[key]?.invalidate()
        timers[key] = nil
    }
    
    func startTimer(_ key: String = "Timer", interval: TimeInterval = 1, action: @escaping () -> Void) {
        timers[key] = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { _ in
            action()
        })
    }
    
}

extension UIScrollView {
   var currentPage: Int {
      return Int((contentOffset.x + (0.5 * frame.width)) / frame.width) + 1
   }
}

extension UIApplication {
    var isAvailableBotomHomeIndicator: Bool {
        if #available(iOS 13.0, *), let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow.safeAreaInsets.bottom > 0
        } else if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.keyWindow {
            return keyWindow.safeAreaInsets.bottom > 0
        } else {
            return false
        }
    }
}

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
    func reuseIndentifier<T>(for type: T.Type) -> String {
        return String(describing: type)
    }
    
    func register<T: UICollectionViewCell>(_ cell: T.Type) {
        register(T.self, forCellWithReuseIdentifier: cell.identifier)
    }
    
    func registerView<T: UICollectionReusableView>(_ view: T.Type, kind: String = UICollectionView.elementKindSectionHeader) {
        register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: view.identifier)
    }
}

public extension UICollectionReusableView {
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
    func setBlur(style: UIBlurEffect.Style) {
        let blur = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
    }
    
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

public extension UICollectionView {
    func dequeueCell<T: UICollectionViewCell>(id: String = T.identifier,
                                              indexPath: IndexPath,
                                              configure: (T) -> Void) -> T {
        register(T.self)
        
        let cell: T
        if let dequeued = dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? T {
            cell = dequeued
        } else {
            cell = T(frame: .zero)
        }
        
        configure(cell)
        return cell
    }
    
    func dequeueView<T: UICollectionReusableView>(id: String = T.identifier,
                                                  kind: String = UICollectionView.elementKindSectionHeader,
                                                  indexPath: IndexPath,
                                                  configure: (T) -> Void) -> T {
        registerView(T.self, kind: kind)
        
        let view: T
        if let dequeued = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: id, for: indexPath) as? T {
            view = dequeued
        } else {
            view = T(frame: .zero)
        }
        
        configure(view)
        
        return view
    }
}

@available(iOS 13.4, *)
protocol PointerInteractionProtocol: class, UIPointerInteractionDelegate {
    func addPointInteraction(on view: UIView, delegate: UIPointerInteractionDelegate)
}

@available(iOS 13.4, *)
extension PointerInteractionProtocol {
    func addPointInteraction(on view: UIView, delegate: UIPointerInteractionDelegate) {
        let interaction = UIPointerInteraction(delegate: delegate)
        view.addInteraction(interaction)
    }
}
