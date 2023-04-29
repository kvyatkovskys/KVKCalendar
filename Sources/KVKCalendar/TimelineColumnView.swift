//
//  TimelineColumnView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 4/29/23.
//

import SwiftUI

@available(iOS 16.0, *)
struct TimelineColumnView: View {
    
    struct Container: Identifiable {
        let event: Event
        var rect: CGRect
        
        var id: String {
            event.id
        }
    }
    
    var items: [TimelineColumnView.Container]
    
    init(items: [TimelineColumnView.Container]) {
        self.items = items
    }
    
    var body: some View {
        GeometryReader { (proxy) in
            EventStack(items: items, width: proxy.size.width) {
                ForEach(items) { (item) in
                    Text(item.id)
                        .frame(width: getActualWidth(proxy, for: item),
                               height: item.rect.height)
                        .border(.red)
                        .padding(2)
                }
            }
            .background(.clear)
        }
    }
    
    private func getIntersectsCount(for item: TimelineColumnView.Container) -> CGFloat {
        items.reduce(0) { (acc, other) in
            if checkPoint(for: item, in: other) {
                return acc + 1
            }
            return acc
        }
    }
    
    private func checkPoint(for item1: TimelineColumnView.Container,
                            in item2: TimelineColumnView.Container) -> Bool {
        if item2.rect.intersects(item1.rect) {
            return true
        }
        return false
    }
    
    private func getActualWidth(_ proxy: GeometryProxy,
                                for item: TimelineColumnView.Container) -> CGFloat {
        let max = getIntersectsCount(for: item)
        return (proxy.size.width / max) - 3
    }
    
}

@available(iOS 16.0, *)
struct TimelineColumnView_Previews: PreviewProvider {
    static var previews: some View {
        let items: [TimelineColumnView.Container] = [
            TimelineColumnView.Container(event: .stub(id: "1"), rect: CGRect(x: 0, y: 100, width: 0, height: 300)),
            TimelineColumnView.Container(event: .stub(id: "2"), rect: CGRect(x: 0, y: 300, width: 0, height: 180)),
            TimelineColumnView.Container(event: .stub(id: "3"), rect: CGRect(x: 0, y: 410, width: 0, height: 200)),
            TimelineColumnView.Container(event: .stub(id: "4"), rect: CGRect(x: 0, y: 550, width: 0, height: 100))
        ]
        return TimelineColumnView(items: items)
    }
}

@available(iOS 16.0, *)
struct EventStack: Layout {
    
    var items: [TimelineColumnView.Container]
    var width: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // get ideal size based on subviews size
        let combinedSize = subviews
            .compactMap {
                $0.sizeThatFits(.unspecified)
            }
            .reduce(.zero) {
                CGSize(width: 0,
                       height: $0.height + $1.height)
            }
        return CGSize(width: width, height: combinedSize.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // get ideal size based
        let subviewSizes = subviews
            .compactMap {
                $0.sizeThatFits(.unspecified)
            }
        
        var step: CGFloat = 0
        var temp: [String: CGRect] = [:]
        // place subviews
        for index in subviews.indices {
            let subviewSize = subviewSizes[index]
            let sizeProposal = ProposedViewSize(width: subviewSize.width,
                                                height: subviewSize.height)
            
            let item = items[index]
            let lastIntersectsItem = getLastIntersect(for: item)
            let point: CGPoint
            if let lastIntersectsItem, let lastRect = temp[lastIntersectsItem.id] {
                let x: CGFloat
                if index == 0 {
                    x = bounds.minX
                    step = 0
                } else {
                    x = lastRect.width
                    step += 1
                }
                point = CGPoint(x: x, y: item.rect.minY)
            } else {
                point = CGPoint(x: bounds.minX, y: item.rect.minY)
                step = 0
            }
            temp[item.id] = CGRect(origin: point, size: subviewSize)
            subviews[index].place(at: point,
                                  anchor: .topLeading,
                                  proposal: sizeProposal)
        }
    }
    
    private func getLastIntersect(for item: TimelineColumnView.Container) -> TimelineColumnView.Container? {
        items.last(where: { checkPoint(for: item, in: $0) })
    }
    
    private func checkPoint(for item1: TimelineColumnView.Container,
                            in item2: TimelineColumnView.Container) -> Bool {
        let y1 = item2.rect.minY
        let y2 = item2.rect.maxY
        if y1...y2 ~= item1.rect.minY {
            return true
        }
        return false
    }
    
}
