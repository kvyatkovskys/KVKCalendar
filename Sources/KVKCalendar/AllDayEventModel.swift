//
//  AllDayEventModel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

@available(iOS 13.4, *)
extension AllDayEventView: PointerInteractionProtocol {
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?

        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: .hover(targetedPreview))
        }
        return pointerStyle
    }
    
}

struct AllDayEvent {
    let date: Date
    let event: Event
    let xOffset: CGFloat
    let width: CGFloat
}

extension AllDayEvent: EventProtocol {
    
    func compare(_ event: Event) -> Bool {
        self.event.hash == event.hash
    }
    
}

protocol AllDayEventDelegate: AnyObject {
    
    func didSelectAllDayEvent(_ event: Event, frame: CGRect?)
    
}

#endif
