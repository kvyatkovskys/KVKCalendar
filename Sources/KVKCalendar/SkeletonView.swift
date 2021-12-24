//
//  SkeletonView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 19.07.2021.
//

#if os(iOS)

import UIKit

private enum Consts {

    static let animationDuration: TimeInterval = 0.5

    static let animationKey = "pulse"

    static let baseColor = #colorLiteral(red: 0.9607843137, green: 0.9607843137, blue: 0.9607843137, alpha: 1)

    static let highlightedColor = #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1)

}

final class SkeletonView: UIView {

    private let animation: CAAnimation = {
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.backgroundColor))
        pulseAnimation.fromValue = Consts.baseColor.cgColor
        pulseAnimation.toValue = Consts.highlightedColor.cgColor
        pulseAnimation.duration = Consts.animationDuration
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        return pulseAnimation
    }()

    override var isHidden: Bool {
        didSet { updateAnimation() }
    }

    // MARK: - constructors
    
    init(cornerRadius: CGFloat = 2) {
        super.init(frame: .zero)
        layer.masksToBounds = true
        layer.cornerRadius = cornerRadius
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    // MARK: - lifecycle
    
    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil else {
            return
        }

        updateAnimation()
    }

    // MARK: - private functions

    private func setup() {
        backgroundColor = UIColor.clear
        layer.backgroundColor = Consts.baseColor.cgColor
    }

    private func updateAnimation() {
        if layer.animationKeys()?.contains(Consts.animationKey) != true {
            layer.add(animation, forKey: Consts.animationKey)
        }
    }

}

private var skeletonViewAssociationKey: UInt8 = 0

extension UIView {
    
    private var skeletonView: SkeletonView {
        guard let view = objc_getAssociatedObject(self, &skeletonViewAssociationKey) as? SkeletonView else {
            let view = SkeletonView()
            objc_setAssociatedObject(self, &skeletonViewAssociationKey, view, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return view
        }
        return view
    }
    
    func setAsSkeleton(_ asSkeleton: Bool, cornerRadius: CGFloat? = nil, insets: UIEdgeInsets = .zero) {
        guard asSkeleton != (skeletonView.superview != nil) else {
            return
        }
        
        isUserInteractionEnabled = !asSkeleton
        skeletonView.removeFromSuperview()
        
        if asSkeleton {
            skeletonView.layer.cornerRadius = cornerRadius ?? layer.cornerRadius
            skeletonView.frame = frame
            
            if insets != .zero {
                skeletonView.frame.origin.x += insets.left
                skeletonView.frame.origin.y += insets.top
                skeletonView.frame.size.height -= (insets.bottom * 2)
                skeletonView.frame.size.width -= (insets.right * 2)
            }
            
            addSubview(skeletonView)
        }
    }
    
}

#endif
