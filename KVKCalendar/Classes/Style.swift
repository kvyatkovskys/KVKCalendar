//
//  Style.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

private let gainsboro: UIColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1)

public struct Style {
    public var event = EventStyle()
    public var timeline = TimelineStyle()
    public var week = WeekStyle()
    public var allDay = AllDayStyle()
    public var headerScroll = HeaderScrollStyle()
    public var month = MonthStyle()
    public var year = YearStyle()
    public var locale = Locale.current
    public var calendar = Calendar.current
    public var timezone = TimeZone.current
    public var defaultType: CalendarType?
    public var timeHourSystem: TimeHourSystem = .twentyFourHour
    public var startWeekDay: StartDayType = .monday
    public var followInSystemTheme: Bool = false
    
    public init() {}
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
    public var startFromFirstEvent: Bool = true
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
    public var movingMinutesColor: UIColor = .systemBlue
    public var shadowColumnColor: UIColor = .systemTeal
    public var shadowColumnAlpha: CGFloat = 0.1
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
    private let format: DateFormatter = {
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
    public var isHiddenMoreTitle: Bool = false
    public var colorMoreTitle: UIColor = .gray
    public var colorEventTitle: UIColor = .black
    public var fontEventTitle: UIFont = .systemFont(ofSize: 15)
    public var fontEventTime: UIFont = .systemFont(ofSize: 10)
    public var fontEventBullet: UIFont = .boldSystemFont(ofSize: 18)
    public var isHiddenSeporator: Bool = false
    public var widthSeporator: CGFloat = 0.7
    public var colorSeporator: UIColor = gainsboro.withAlphaComponent(0.9)
    public var colorBackgroundWeekendDate: UIColor = gainsboro.withAlphaComponent(0.4)
    public var colorBackgroundDate: UIColor = .white
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    public var selectCalendarType: CalendarType = .week
    public var isAnimateSelection: Bool = false
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

public struct EventStyle {
    public var isEnableMoveEvent: Bool = false
    public var minimumPressDuration: TimeInterval = 1
}

extension Style {
    var checkStyle: Style {
        guard followInSystemTheme else { return self }
        
        var newStyle = self
        if #available(iOS 13.0, *) {
            let colorBackgroundWeekendDate = UIColor.useForStyle(dark: .systemGray6, white: gainsboro.withAlphaComponent(0.2))
            
            // header
            newStyle.headerScroll.backgroundColor = UIColor.useForStyle(dark: .black, white: UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1))
            newStyle.headerScroll.colorTitleDate = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.headerScroll.colorTitleCornerDate = .systemRed
            newStyle.headerScroll.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScroll.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScroll.colorCurrentDate = .systemGray6
            newStyle.headerScroll.colorBackgroundCurrentDate = .systemRed
            newStyle.headerScroll.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.headerScroll.colorSelectDate = .systemGray6
            newStyle.headerScroll.colorWeekendDate = .systemGray2
            
            // timeline
            newStyle.timeline.backgroundColor = UIColor.useForStyle(dark: .black, white: .white)
            newStyle.timeline.timeColor = .systemGray
            newStyle.timeline.colorIconFile = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.timeline.currentLineHourColor = UIColor.useForStyle(dark: .systemRed, white: .red)
            
            // week
            newStyle.week.colorBackground = UIColor.useForStyle(dark: .black, white: gainsboro.withAlphaComponent(0.4))
            newStyle.week.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.week.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.week.colorCurrentDate = UIColor.useForStyle(dark: .systemGray, white: .white)
            newStyle.week.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.week.colorBackgroundCurrentDate = .systemRed
            newStyle.week.colorSelectDate = .white
            newStyle.week.colorWeekendDate = .systemGray2
            newStyle.week.colorBackgroundWeekendDate = colorBackgroundWeekendDate
            
            // month
            newStyle.month.colorDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.month.colorNameDay = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.month.colorCurrentDate = .white
            newStyle.month.colorBackgroundCurrentDate = .systemRed
            newStyle.month.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.month.colorSelectDate = UIColor.useForStyle(dark: .black, white: .white)
            newStyle.month.colorWeekendDate = .systemGray2
            newStyle.month.colorMoreTitle = UIColor.useForStyle(dark: .systemGray3, white: .gray)
            newStyle.month.colorEventTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.month.colorSeporator = UIColor.useForStyle(dark: .systemGray, white: gainsboro.withAlphaComponent(0.9))
            newStyle.month.colorBackgroundWeekendDate = colorBackgroundWeekendDate
            newStyle.month.colorBackgroundDate = UIColor.useForStyle(dark: .black, white: .white)
            
            // year
            newStyle.year.colorCurrentDate = .white
            newStyle.year.colorBackgroundCurrentDate = .systemRed
            newStyle.year.colorBackgroundSelectDate = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.year.colorSelectDate = .white
            newStyle.year.colorWeekendDate = .systemGray2
            newStyle.year.colorBackgroundWeekendDate = colorBackgroundWeekendDate
            newStyle.year.colorTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            newStyle.year.colorBackgroundHeader = UIColor.useForStyle(dark: .black, white: gainsboro.withAlphaComponent(0.4))
            newStyle.year.colorTitleHeader = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.year.colorDayTitle = UIColor.useForStyle(dark: .systemGray, white: .black)
            
            // all day
            newStyle.allDay.backgroundColor = .systemGray
            newStyle.allDay.titleColor = UIColor.useForStyle(dark: .white, white: .black)
            newStyle.allDay.textColor = UIColor.useForStyle(dark: .white, white: .black)
        }
        return newStyle
    }
}
