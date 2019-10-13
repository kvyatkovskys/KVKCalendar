//
//  Style.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let gainsboro: UIColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1)

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
    public var timeHourSystem: TimeHourSystem = .twentyFourHour
    public var startWeekDay: StartDayType = .monday
    public var followInInterfaceStyle: Bool = false
    
    public init() {}
    
    var checkStyle: Style {
        guard followInInterfaceStyle else { return self }
        
        var newStyle = self
        if #available(iOS 13.0, *) {
            newStyle.headerScrollStyle.backgroundColor = UIColor.useForStyle(dark: .black, white: UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1))
            newStyle.headerScrollStyle.colorTitleDate = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.headerScrollStyle.colorTitleCornerDate = .systemRed
            newStyle.headerScrollStyle.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScrollStyle.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScrollStyle.colorCurrentDate = .systemGray6
            newStyle.headerScrollStyle.colorBackgroundCurrentDate = .systemRed
            newStyle.headerScrollStyle.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScrollStyle.colorSelectDate = .systemGray6
            newStyle.headerScrollStyle.colorWeekendDate = .systemGray2
            
            newStyle.timelineStyle.backgroundColor = UIColor.useForStyle(dark: .black, white: .white)
            newStyle.timelineStyle.timeColor = .systemGray
            newStyle.timelineStyle.colorIconFile = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.timelineStyle.currentLineHourColor = UIColor.useForStyle(dark: .systemRed, white: .red)
            
            newStyle.weekStyle.colorBackground = UIColor.useForStyle(dark: .black, white: gainsboro.withAlphaComponent(0.4))
            newStyle.weekStyle.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.weekStyle.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.weekStyle.colorCurrentDate = UIColor.useForStyle(dark: .systemGray, white: .white)
            newStyle.weekStyle.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.weekStyle.colorBackgroundCurrentDate = .systemRed
            newStyle.weekStyle.colorSelectDate = .white
            newStyle.weekStyle.colorWeekendDate = .systemGray2
            newStyle.weekStyle.colorBackgroundWeekendDate = UIColor.useForStyle(dark: .systemGray, white: gainsboro.withAlphaComponent(0.4))
            
            newStyle.monthStyle.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.monthStyle.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.monthStyle.colorCurrentDate = .white
            newStyle.monthStyle.colorBackgroundCurrentDate = .systemRed
            newStyle.monthStyle.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.monthStyle.colorSelectDate = UIColor.useForStyle(dark: .black, white: .white)
            newStyle.monthStyle.colorWeekendDate = .systemGray2
            newStyle.monthStyle.colorMoreTitle = UIColor.useForStyle(dark: .systemGray3, white: .gray)
            newStyle.monthStyle.colorEventTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.monthStyle.colorSeporator = UIColor.useForStyle(dark: .systemGray, white: gainsboro.withAlphaComponent(0.9))
            newStyle.monthStyle.colorBackgroundWeekendDate = UIColor.useForStyle(dark: .systemGray5, white: gainsboro.withAlphaComponent(0.4))
            newStyle.monthStyle.colorBackgroundDate = UIColor.useForStyle(dark: .black, white: .white)
            
            newStyle.yearStyle.colorCurrentDate = .white
            newStyle.yearStyle.colorBackgroundCurrentDate = .systemRed
            newStyle.yearStyle.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.yearStyle.colorSelectDate = .white
            newStyle.yearStyle.colorWeekendDate = .systemGray2
            newStyle.yearStyle.colorBackgroundWeekendDate = UIColor.useForStyle(dark: .systemGray5, white: gainsboro.withAlphaComponent(0.4))
            newStyle.yearStyle.colorTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.yearStyle.colorBackgroundHeader = UIColor.useForStyle(dark: .black, white: gainsboro.withAlphaComponent(0.4))
            newStyle.yearStyle.colorTitleHeader = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.yearStyle.colorDayTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            
            newStyle.allDayStyle.backgroundColor = .systemGray
            newStyle.allDayStyle.titleColor = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.allDayStyle.textColor = UIColor.useForStyle(dark: .white, white: .black)
        }
        return newStyle
    }
}

public struct HeaderScrollStyle {
    private let formatFull: DateFormatter = {
        let format = DateFormatter()
        format.dateStyle = .full
        return format
    }()
    
    private let formatSort: DateFormatter = {
        let format = DateFormatter()
        format.locale = Locale(identifier: "en_EN")
        format.dateFormat = "LLL"
        return format
    }()
    
    public var titleDays: [String] = []
    public var heightHeaderWeek: CGFloat = 70
    public var heightTitleDate: CGFloat = 30
    public var backgroundColor: UIColor = UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1)
    public var isHiddenTitleDate: Bool = false
    public var isHiddenCornerTitleDate: Bool = true
    public lazy var formatterTitle: DateFormatter = formatFull
    public lazy var formatterCornerTitle: DateFormatter = formatSort
    public var colorTitleDate: UIColor = .black
    public var colorTitleCornerDate: UIColor = .red
    public var colorDate: UIColor = .black
    public var colorNameDay: UIColor = .black
    public var colorCurrentDate: UIColor = .white
    public var colorBackgroundCurrentDate: UIColor = .red
    public var colorBackgroundSelectDate: UIColor = .black
    public var colorSelectDate: UIColor = .white
    public var colorWeekendDate: UIColor = .gray
    public var isScrollEnabled: Bool = true
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
    public var iconFile: UIImage? = nil
    public var colorIconFile: UIColor = .black
    public var showCurrentLineHour: Bool = true
    public var currentLineHourFont: UIFont = .systemFont(ofSize: 12)
    public var currentLineHourColor: UIColor = .red
    public var currentLineHourWidth: CGFloat = 50
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
    public var selectCalendarType: CalendarType = .day
    public var showVerticalDayDivider: Bool = true
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
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    public var selectCalendarType: CalendarType = .week
    public var isAnimateSelection: Bool = true
    public var isPagingEnabled: Bool = true
}

public struct YearStyle {
    private let format: DateFormatter = {
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
    public var selectCalendarType: CalendarType = .month
    public var isAnimateSelection: Bool = true
    public var isPagingEnabled: Bool = true
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
