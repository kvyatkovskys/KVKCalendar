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
    
    private var pages: [TimelineView]
    private var currentIndex: Int
    
    var didSwitchTimelineView: ((SwitchPageType) -> Void)?
    var willDisplayTimelineView: ((TimelineView, SwitchPageType) -> Void)?
    
    var timelineView: TimelineView {
        return pages[currentIndex]
    }
    
    private lazy var mainPageView: UIPageViewController = {
        let pageView = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        pageView.dataSource = self
        pageView.delegate = self
        return pageView
    }()
    
    init(pages: [TimelineView], frame: CGRect) {
        self.pages = pages
        self.currentIndex = (pages.count / 2) - 1
        super.init(frame: frame)
        
        let timelineView = pages[currentIndex]
        let container = TimelinePageContainerVC(index: currentIndex, contentView: timelineView)
        mainPageView.setViewControllers([container], direction: .forward, animated: false, completion: nil)
        mainPageView.view.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(mainPageView.view)
    }
    
    func addNewTimelineView(_ timeline: TimelineView, to: AddNewTimelineViewType) {
        switch to {
        case .end:
            pages.append(timeline)
        case .begin:
            pages.insert(timeline, at: 0)
            
//            if currentIndex == 0 {
//                currentIndex += 1
//            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TimelinePageView: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelinePageContainerVC)?.index else {
            return nil
        }
        
        if newIndex == 0 {
            newIndex = 0
        } else {
            newIndex -= 1
        }
        
        let newTimelineView = pages[newIndex]
        willDisplayTimelineView?(newTimelineView, .previous)
        let container = TimelinePageContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard var newIndex = (viewController as? TimelinePageContainerVC)?.index, (newIndex + 1) < pages.count else {
            return nil
        }
        
        newIndex += 1
        let newTimelineView = pages[newIndex]
        willDisplayTimelineView?(newTimelineView, .next)
        let container = TimelinePageContainerVC(index: newIndex, contentView: newTimelineView)
        return container
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = (pageViewController.viewControllers?.first as? TimelinePageContainerVC)?.index, completed else { return }
        
        if index == 0 {
            currentIndex = 1
        }
        
        print(index, currentIndex, (mainPageView.viewControllers?.first as? TimelinePageContainerVC)?.index)
        let type: SwitchPageType
        
        if index > currentIndex {
            type = .next
            currentIndex = index
        } else {
            type = .previous
            currentIndex = index
        }
        
        currentIndex = index
        didSwitchTimelineView?(type)
    }
}
