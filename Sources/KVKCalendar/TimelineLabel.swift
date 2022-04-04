//
//  TimelineLabel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

final class TimelineLabel: UILabel {
    var valueHash: Int?
    
    var time: TimeContainer = TimeContainer(minute: 0, hour: 0) {
        didSet {
            if oldValue.minute != time.minute {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            
            text = ":\(time.minute)"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
