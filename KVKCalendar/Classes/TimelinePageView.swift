//
//  TimelinePageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 05.12.2020.
//

import UIKit

final class TimelinePageView: UIView {
    
    private var pages: [UIView]
    
    var didGetCurrentIndex: ((Int) -> Void)?
    
    private lazy var mainPageView: UIPageViewController = {
        let pageView = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageView.dataSource = self
        pageView.delegate = self
        return pageView
    }()
    
    init(pages: [UIView], frame: CGRect) {
        self.pages = pages
        super.init(frame: frame)
        
        let containers = pages.enumerated().compactMap({ TimelinePageContainerVC(index: $0.offset, contentView: $0.element) })
        mainPageView.setViewControllers(containers, direction: .forward, animated: false, completion: nil)
        mainPageView.view.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(mainPageView.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelinePageView: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let newIndex = (viewController as? TimelinePageContainerVC)?.index, (newIndex - 1) >= 0 else { return nil }
        
        let container = TimelinePageContainerVC(index: newIndex, contentView: pages[newIndex])
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let newIndex = (viewController as? TimelinePageContainerVC)?.index, (newIndex + 1) < pages.count else { return nil }
        
        let container = TimelinePageContainerVC(index: newIndex, contentView: pages[newIndex])
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? TimelinePageContainerVC)?.index, completed else { return }
        
        didGetCurrentIndex?(index)
    }
}
