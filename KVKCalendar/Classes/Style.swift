//
//  Style.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

import UIKit

let gainsboro: UIColor = UIColor(red: 220 / 255, green: 220 / 255, blue: 220 / 255, alpha: 1)

struct Style {
    var timelineStyle = TimelineStyle()
    var weekStyle = WeekStyle()
    var allDayStyle = AllDayStyle()
    var headerScrollStyle = HeaderScrollStyle()
    var monthStyle = MonthStyle()
}

struct HeaderScrollStyle: DateStyle {
    var heightHeaderWeek: CGFloat = 70
    var heightTitleDate: CGFloat = 30
    var backgroundColor: UIColor = UIColor(red: 246 / 255, green: 246 / 255, blue: 246 / 255, alpha: 1)
    var isHiddenTitleDate: Bool = false
    var formatter: DateFormatter = DateFormatter()
    var colorTitleDate: UIColor = .black
    var colorDate: UIColor = .black
    var colorNameDay: UIColor = .black
    var colorCurrentDate: UIColor = .white
    var colorBackgroundCurrentDate: UIColor = .red
    var colorBackgroundSelectDate: UIColor = .black
    var colorSelectDate: UIColor = .white
    var colorWeekdayDate: UIColor = .gray
}

struct TimelineStyle {
    var offsetEvent: CGFloat = 1
    var startHour: Int = 0
    var heightLine: CGFloat = 0.5
    var offsetLineLeft: CGFloat = 10
    var offsetLineRight: CGFloat = 10
    var backgroundColor: UIColor = .white
    var widthTime: CGFloat = 40
    var heightTime: CGFloat = 20
    var offsetTimeX: CGFloat = 10
    var offsetTimeY: CGFloat = 50
    var timeColor: UIColor = .gray
    var timeFont: UIFont = .systemFont(ofSize: 12)
    var scrollToCurrentHour: Bool = true
    var widthEventViewer: CGFloat = 500
}

struct WeekStyle: DateStyle {
    var colorDate: UIColor = .black
    var colorNameDay: UIColor = .black
    var colorCurrentDate: UIColor = .white
    var colorBackgroundCurrentDate: UIColor = .red
    var colorBackgroundSelectDate: UIColor = .black
    var colorSelectDate: UIColor = .white
    var colorWeekdayDate: UIColor = .gray
    var colorBackgroundWeekdayDate: UIColor = gainsboro.withAlphaComponent(0.4)
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
}

struct MonthStyle: DateStyle {
    var colorDate: UIColor = .black
    var colorNameDay: UIColor = .black
    var colorFontNameDate: UIFont = .boldSystemFont(ofSize: 16)
    var colorCurrentDate: UIColor = .white
    var colorBackgroundCurrentDate: UIColor = .red
    var colorBackgroundSelectDate: UIColor = .black
    var colorSelectDate: UIColor = .white
    var colorWeekdayDate: UIColor = .gray
    var moreTitle: String = "more"
    var colorMoreTitle: UIColor = .gray
    var colorEventTitle: UIColor = .black
    var fontEventTitle: UIFont = .systemFont(ofSize: 14)
    var isHiddenSeporator: Bool = true
    var widthSeporator: CGFloat = 0.7
    var colorSeporator: UIColor = gainsboro.withAlphaComponent(0.9)
    var colorBackgroundWeekdayDate: UIColor = gainsboro.withAlphaComponent(0.4)
    var colorBackgroundDate: UIColor = .white
}

struct AllDayStyle {
    var backgroundColor: UIColor = .gray
    var titleText: String = "all-day"
    var titleColor: UIColor = .black
    var textColor: UIColor = .black
    var backgroundColorEvent: UIColor = .clear
    var font: UIFont = .systemFont(ofSize: 12)
    var offset: CGFloat = 2
    var height: CGFloat = 25
    var fontTitle: UIFont = .systemFont(ofSize: 10)
    var isPinned: Bool = false
}

protocol DateStyle {
    var colorDate: UIColor { get }
    var colorNameDay: UIColor { get }
    var colorCurrentDate: UIColor { get }
    var colorBackgroundCurrentDate: UIColor { get }
    var colorBackgroundSelectDate: UIColor { get }
    var colorSelectDate: UIColor { get }
    var colorWeekdayDate: UIColor { get }
}
