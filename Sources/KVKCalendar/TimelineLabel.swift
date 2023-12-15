//
//  TimelineLabel.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import UIKit

public class TimelineLabel: UILabel {
    
    public var hashTime: Int = 0
    
    var time: TimeContainer = TimeContainer(minute: 0, hour: 0) {
        didSet {
            guard 1..<60 ~= time.minute else {
                text = nil
                return
            }
            
            text = ":\(time.minute)"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.adjustsFontForContentSizeCategory = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

#endif
