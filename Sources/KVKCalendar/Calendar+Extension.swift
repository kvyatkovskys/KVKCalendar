//
//  Calendar+Extension.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

enum Platform: Int {
    case phone, pad, mac, none
    
    static var currentDevice: Platform {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .phone
        case .pad:
            return .pad
        case .mac:
            return .mac
        default:
            return .none
        }
    }
    
    static var currentInterface: Platform {
        switch currentDevice {
        case .pad:
            if let vc = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                if vc.view.bounds.width < 600 {
                    return .phone
                } else {
                    return .pad
                }
            } else {
                return .pad
            }
        default:
            return currentDevice
        }
    }
        
}

private enum AssociatedKeys {
    static var timer: UInt8 = 0
}

/// Any object can start and stop delayed action for key
protocol CalendarTimer: AnyObject {}

extension CalendarTimer {
    
    private var timers: [String: Timer] {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.timer) as? [String: Timer] ?? [:] }
        set { objc_setAssociatedObject(self, &AssociatedKeys.timer, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func stopTimer(_ key: String = "Timer") {
        timers[key]?.invalidate()
        timers[key] = nil
    }
    
    func isValidTimer(_ key: String = "Timer") -> Bool {
        timers[key]?.isValid == true
    }
    
    func startTimer(_ key: String = "Timer", interval: TimeInterval = 1, repeats: Bool = false, addToRunLoop: Bool = false, action: @escaping () -> Void) {
        
        let timer: Timer
        if addToRunLoop {
            timer = Timer(timeInterval: interval, repeats: repeats) { (_) in
                action()
            }
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { (_) in
                action()
            }
        }
        
        timers[key] = timer
        
        if addToRunLoop {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
}

extension UIScrollView {
    
   var currentPage: Int {
       Int((contentOffset.x + (0.5 * frame.width)) / frame.width) + 1
   }
    
}

extension UIApplication {
    
    var orientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            let value = UIDevice.current.orientation
            return UIInterfaceOrientation(rawValue: value.rawValue) ?? .unknown
        }
    }
    
    var isAvailableBottomHomeIndicator: Bool {
        if #available(iOS 15.0, *) {
            if let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
            {
                return keyWindow.safeAreaInsets.bottom > 0
            } else if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow.safeAreaInsets.bottom > 0
            } else {
                return false
            }
        } else if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
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

extension Collection where Self == [Event] {
    
    var splitEvents: [Event.EventType: [Event]] {
        reduce([:]) { (acc, event) -> [Event.EventType: [Event]] in
            var accTemp = acc
            if event.isAllDay {
                if var values = accTemp[.allDay] {
                    values.append(event)
                    accTemp[.allDay] = values
                } else {
                    accTemp[.allDay] = [event]
                }
            } else {
                if var values = accTemp[.usual] {
                    values.append(event)
                    accTemp[.usual] = values
                } else {
                    accTemp[.usual] = [event]
                }
            }
            return accTemp
        }
    }
    
}

extension UICollectionView {
    
    func kvkRegister<T: UICollectionViewCell>(_ cell: T.Type, id: String? = nil) {
        register(T.self, forCellWithReuseIdentifier: id ?? cell.kvkIdentifier)
    }
    
    func kvkRegisterView<T: UICollectionReusableView>(_ view: T.Type, id: String? = nil, kind: String = UICollectionView.elementKindSectionHeader) {
        register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: id ?? view.kvkIdentifier)
    }
    
}

extension UITableView {
    
    func kvkRegister<T: UITableViewCell>(_ cell: T.Type) {
        register(T.self, forCellReuseIdentifier: cell.kvkIdentifier)
    }
    
    func kvkRegister<T: UIView>(_ view: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: view.kvkIdentifier)
    }
    
}

extension UIColor {
    
    static func useForStyle(dark: UIColor, white: UIColor) -> UIColor {
        UIColor { (traitCollection: UITraitCollection) -> UIColor in
            traitCollection.userInterfaceStyle == .dark ? dark : white
        }
    }
    
}

extension UIScreen {
    
    static var isDarkMode: Bool {
        main.traitCollection.userInterfaceStyle == .dark
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
        setRoundCorners(corners.convertedCorners, radius: max(radius.width, radius.height))
    }
    
    func setRoundCorners(_ corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner], radius: CGFloat) {
        layer.masksToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = corners
    }
    
    func snapshot(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
        return image
    }
    
    func setTappedState(_ tapped: Bool, animated: Bool = true) {
        let action = { [weak self] in
            if tapped {
                let scale: CGFloat = 0.95
                self?.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else {
                self?.transform = .identity
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: action)
        } else {
            action()
        }
    }
    
}

extension UIRectCorner {
    
    var convertedCorners: CACornerMask {
        switch self {
        case .allCorners:
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .bottomLeft:
            return .layerMinXMaxYCorner
        case .bottomRight:
            return .layerMaxXMaxYCorner
        case .topLeft:
            return .layerMinXMinYCorner
        case .topRight:
            return .layerMaxXMinYCorner
        default:
            return []
        }
    }
    
}

public protocol KVKCellIdentifierProxy: AnyObject {
    
    static var kvkIdentifier: String { get }
    
}

extension UIView: KVKCellIdentifierProxy {
    
    public static var kvkIdentifier: String {
        String(describing: self)
    }
    
}

public protocol KVKDequeueProxyProtocol: AnyObject {}

//public extension KVKDequeueProxyProtocol {
//
//    func kvkDequeueCell<T, U: KVKCellIdentifierProxy>(type: CalendarType,
//                                                      view: T,
//                                                      id: String = U.kvkIdentifier,
//                                                      indexPath: IndexPath? = nil,
//                                                      configure: (U) -> Void) -> U? {
//        switch type {
//
//        case .month:
//            if let cell = (view as? UITableView)?.kvkDequeueCell(id: id,
//                                                                 indexPath: indexPath,
//                                                                 configure: configure) {
//                return cell
//            } else {
//                return nil
//            }
//        default:
//            return nil
//        }
//    }
//
//}

public extension KVKDequeueProxyProtocol where Self: UITableView {
    
    func kvkDequeueCell<T: UITableViewCell>(id: String = T.kvkIdentifier, indexPath: IndexPath? = nil, configure: (T) -> Void) -> T {
        kvkRegister(T.self)
        
        let cell: T
        if let index = indexPath, let dequeued = dequeueReusableCell(withIdentifier: id, for: index) as? T {
            cell = dequeued
        } else if let dequeued = dequeueReusableCell(withIdentifier: id) as? T {
            cell = dequeued
        } else {
            cell = T(frame: .zero)
        }
        
        configure(cell)
        return cell
    }
    
    func kvkDequeueView<T: UIView>(id: String = T.kvkIdentifier, configure: (T) -> Void) -> T {
        kvkRegister(T.self)
        
        let view: T
        if let dequeued = dequeueReusableHeaderFooterView(withIdentifier: id) as? T {
            view = dequeued
        } else {
            view = T(frame: .zero)
        }
        
        configure(view)
        return view
    }
    
}

public extension KVKDequeueProxyProtocol where Self: UICollectionView {
    
    func kvkDequeueCell<T: UICollectionViewCell>(id: String = T.kvkIdentifier, indexPath: IndexPath, configure: (T) -> Void) -> T {
        kvkRegister(T.self, id: id)
        
        let cell: T
        if let dequeued = dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? T {
            cell = dequeued
        } else {
            cell = T(frame: .zero)
        }
        
        configure(cell)
        return cell
    }
    
    func kvkDequeueView<T: UICollectionReusableView>(id: String = T.kvkIdentifier, kind: String = UICollectionView.elementKindSectionHeader, indexPath: IndexPath, configure: (T) -> Void) -> T {
        kvkRegisterView(T.self, id: id, kind: kind)
        
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

extension UITableView: KVKDequeueProxyProtocol {}
extension UICollectionView: KVKDequeueProxyProtocol {}

@available(iOS 13.4, *)
extension UIView: UIPointerInteractionDelegate {
    
    func addPointInteraction() {
        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .highlight(targetedPreview))
        }
        return pointerStyle
    }
    
}

#endif
