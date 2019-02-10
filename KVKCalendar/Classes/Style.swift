//
//  Style.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

let gainsboro: UIColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1)

public struct Style {
    public var timelineStyle = TimelineStyle()
    public var weekStyle = WeekStyle()
    public var allDayStyle = AllDayStyle()
    public var headerScrollStyle = HeaderScrollStyle()
    public var monthStyle = MonthStyle()
    public var yearStyle = YearStyle()
    public var locale = Locale.autoupdatingCurrent
    public var calendar = Calendar.autoupdatingCurrent
    public var timezone = TimeZone.autoupdatingCurrent
    public var defaultType: CalendarType?
    
    public init() {}
}

public struct HeaderScrollStyle {
    fileprivate let format: DateFormatter = {
        let format = DateFormatter()
        format.dateStyle = .full
        return format
    }()
    
    public var titleDays: [String] = []
    public var heightHeaderWeek: CGFloat = 70
    public var heightTitleDate: CGFloat = 30
    public var backgroundColor: UIColor = UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1)
    public var isHiddenTitleDate: Bool = false
    public lazy var formatter: DateFormatter = format
    public var colorTitleDate: UIColor = .black
    public var colorDate: UIColor = .black
    public var colorNameDay: UIColor = .black
    public var colorCurrentDate: UIColor = .white
    public var colorBackgroundCurrentDate: UIColor = .red
    public var colorBackgroundSelectDate: UIColor = .black
    public var colorSelectDate: UIColor = .white
    public var colorWeekendDate: UIColor = .gray
}

public struct TimelineStyle {
    public var eventFont: UIFont = .boldSystemFont(ofSize: 12)
    public var offsetEvent: CGFloat = 1
    public var startHour: Int = 0
    public var heightLine: CGFloat = 0.5
    public var offsetLineLeft: CGFloat = 10
    public var offsetLineRight: CGFloat = 10
    public var backgroundColor: UIColor = .white
    public var widthTime: CGFloat = 40
    public var heightTime: CGFloat = 20
    public var offsetTimeX: CGFloat = 10
    public var offsetTimeY: CGFloat = 50
    public var timeColor: UIColor = .gray
    public var timeFont: UIFont = .systemFont(ofSize: 12)
    public var scrollToCurrentHour: Bool = true
    public var widthEventViewer: CGFloat = 0
    public var iconFile: UIImage = UIImage()
    public var colorIconFile: UIColor = .black
}

public struct WeekStyle {
    public var colorBackground: UIColor = gainsboro.withAlphaComponent(0.4)
    public var colorDate: UIColor = .black
    public var colorNameDay: UIColor = .black
    public var colorCurrentDate: UIColor = .white
    public var colorBackgroundCurrentDate: UIColor = .red
    public var colorBackgroundSelectDate: UIColor = .black
    public var colorSelectDate: UIColor = .white
    public var colorWeekendDate: UIColor = .gray
    public var colorBackgroundWeekendDate: UIColor = gainsboro.withAlphaComponent(0.4)
}

public struct MonthStyle {
    fileprivate let format: DateFormatter = {
        let format = DateFormatter()
        format.dateStyle = .full
        return format
    }()
    
    public lazy var formatter: DateFormatter = format
    public var heightHeaderWeek: CGFloat = 50
    public var heightTitleDate: CGFloat = 30
    public var isHiddenTitleDate: Bool = false
    public var colorDate: UIColor = .black
    public var colorNameDay: UIColor = .black
    public var fontNameDate: UIFont = .boldSystemFont(ofSize: 16)
    public var colorCurrentDate: UIColor = .white
    public var colorBackgroundCurrentDate: UIColor = .red
    public var colorBackgroundSelectDate: UIColor = .black
    public var colorSelectDate: UIColor = .white
    public var colorWeekendDate: UIColor = .gray
    public var moreTitle: String = "more"
    public var colorMoreTitle: UIColor = .gray
    public var colorEventTitle: UIColor = .black
    public var fontEventTitle: UIFont = .systemFont(ofSize: 14)
    public var isHiddenSeporator: Bool = false
    public var widthSeporator: CGFloat = 0.7
    public var colorSeporator: UIColor = gainsboro.withAlphaComponent(0.9)
    public var colorBackgroundWeekendDate: UIColor = gainsboro.withAlphaComponent(0.4)
    public var colorBackgroundDate: UIColor = .white
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical
}

public struct YearStyle {
    fileprivate let format: DateFormatter = {
        let format = DateFormatter()
        format.dateStyle = .full
        return format
    }()
    
    public lazy var formatter: DateFormatter = format
    public var colorCurrentDate: UIColor = .white
    public var colorBackgroundCurrentDate: UIColor = .red
    public var colorBackgroundSelectDate: UIColor = .black
    public var colorSelectDate: UIColor = .white
    public var colorWeekendDate: UIColor = .gray
    public var colorBackgroundWeekendDate: UIColor = gainsboro.withAlphaComponent(0.4)
    public var weekFont: UIFont = .boldSystemFont(ofSize: 14)
    public var fontTitle: UIFont = .systemFont(ofSize: 19)
    public var colorTitle: UIColor = .black
    public var colorBackgroundHeader: UIColor = gainsboro.withAlphaComponent(0.4)
    public var fontTitleHeader: UIFont = .boldSystemFont(ofSize: 20)
    public var colorTitleHeader: UIColor = .black
    public var heightTitleHeader: CGFloat = 50
    public var aligmentTitleHeader: NSTextAlignment = .center
    public var fontDayTitle: UIFont = .systemFont(ofSize: 15)
    public var colorDayTitle: UIColor = .black
}

public struct AllDayStyle {
    public var backgroundColor: UIColor = .gray
    public var titleText: String = "all-day"
    public var titleColor: UIColor = .black
    public var textColor: UIColor = .black
    public var backgroundColorEvent: UIColor = .clear
    public var font: UIFont = .systemFont(ofSize: 12)
    public var offset: CGFloat = 2
    public var height: CGFloat = 25
    public var fontTitle: UIFont = .systemFont(ofSize: 10)
    public var isPinned: Bool = false
}
