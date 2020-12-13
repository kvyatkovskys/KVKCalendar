//
//  TimelinePageView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 05.12.2020.
//

import UIKit

final class TimelinePageView: UIView {
    
    enum SwitchPageType: Int {
        case next, previous
    }
    
    enum AddNewTimelineViewType: Int {
        case begin, end
    }
    
    private var pages: [Int: TimelineView]
    private var currentIndex: Int
    
    var didSwitchTimelineView: ((TimelineView?, SwitchPageType) -> Void)?
    var willDisplayTimelineView: ((TimelineView, SwitchPageType) -> Void)?
    
    var timelineView: TimelineView? {
        return pages[currentIndex]
    }
    
    private lazy var mainPageView: UIPageViewController = {
        let pageView = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        pageView.dataSource = self
        pageView.delegate = self
        return pageView
    }()
    
    init(pages: [TimelineView], frame: CGRect) {
        self.pages = pages.enumerated().reduce([:], { (acc, item) -> [Int: TimelineView] in
            var accTemp = acc
            accTemp[item.offset] = item.element
            return accTemp
        })
        self.currentIndex = (pages.count / 2) - 1
        super.init(frame: frame)
        
        let timelineView = pages[currentIndex]
        let container = TimelineContainerVC(index: currentIndex, contentView: timelineView)
        mainPageView.setViewControllers([container], direction: .forward, animated: false, completion: nil)
        mainPageView.view.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(mainPageView.view)
    }
    
    func addNewTimelineView(_ timeline: TimelineView, to: AddNewTimelineViewType) {
        switch to {
        case .end:
            pages[currentIndex + 1] = timeline
        case .begin:
            pages[currentIndex - 1] = timeline
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelinePageView: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let vc = pendingViewControllers.first as? TimelineContainerVC, let contentOffset = timelineView?.contentOffset {
            let pendingTimelineView = pages[vc.index]
            pendingTimelineView?.contentOffset = contentOffset
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerVC)?.index else {
            return nil
        }
        
        newIndex -= 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        willDisplayTimelineView?(newTimelineView, .previous)
        let container = TimelineContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelineContainerVC)?.index, (newIndex + 1) < pages.count else {
            return nil
        }
        
        newIndex += 1
        guard let newTimelineView = pages[newIndex] else { return nil }
        
        willDisplayTimelineView?(newTimelineView, .next)
        let container = TimelineContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? TimelineContainerVC)?.index, completed else { return }
                
        let type: SwitchPageType
        if index > currentIndex {
            type = .next
            currentIndex = index
        } else {
            type = .previous
            currentIndex = index
        }
        
        currentIndex = index
        didSwitchTimelineView?(timelineView, type)
    }
}
