//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI
import EventKit

@available(iOS 18.0, *)
public struct KVKCalendarSwiftUIView: View {

    private var type: CalendarType
    private var data: CalendarData
    @State private var weekData: WeekNewData
    @State private var dayData: WeekNewData
    private var monthData: MonthNewData
    private var yearData: YearNewData?
    private var listData: ListView.Parameters?
    @Binding var date: Date
    @Binding var event: Event?
    
    public init(type: CalendarType,
                date: Binding<Date>,
                events: [Event] = [],
                event: Binding<Event?> = .constant(nil),
                style: KVKCalendar.Style = KVKCalendar.Style(),
                years: Int = 1) {
        self.type = type
        _date = date
        _event = event
        data = CalendarData(date: date.wrappedValue, years: years, style: style)
        _dayData = State(initialValue: WeekNewData(data: data, events: events, type: .day))
        _weekData = State(initialValue: WeekNewData(data: data, events: events, type: .week))
        monthData = MonthNewData(data: data)
    }
    
    public var body: some View {
        bodyView
            .onChange(of: weekData.date) { oldValue, newValue in
                if !date.kvkIsEqual(newValue) {
                    date = newValue
                }
            }
            .onChange(of: date) { oldValue, newValue in
                if !newValue.kvkIsEqual(weekData.date) {
                    weekData.date = newValue
                }
            }
    }
    
    @ViewBuilder
    private var bodyView: some View {
        switch type {
        case .day:
            WeekNewView(vm: dayData)
        case .week:
            WeekNewView(vm: weekData)
        case .month:
            MonthNewView(vm: monthData)
        case .year:
            YearNewView(monthData: monthData)
        case .list:
            EmptyView() // ListNewView(params: vm.listData, date: $vm.date, event: $vm.selectedEvent, events: .constant([]))
        }
    }
}

@available(iOS 18.0, *)
private struct PreviewProxy: View {
    @State var type = CalendarType.week
    @State var date = Date.now
    
    var body: some View {
        NavigationStack {
            KVKCalendarSwiftUIView(type: type, date: $date)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker(type.title, selection: $type) {
                            ForEach(CalendarType.allCases) { (type) in
                                Text(type.title)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Today") {
                            date = .now
                        }
                    }
                }
        }
    }
}

@available(iOS 18.0, *)
#Preview {
    PreviewProxy()
}

@available(swift, deprecated: 0.6.11, obsoleted: 0.6.12, renamed: "KVKCalendarView")
public final class CalendarView: UIView {}

public final class KVKCalendarView: UIView {
    
    struct Parameters {
        var type = CalendarType.day
        var style: Style
    }
    
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource? {
        didSet {
            dayView.reloadEventViewerIfNeeded()
        }
    }
    public var selectedType: CalendarType {
        parameters.type
    }
    
    let eventStore = EKEventStore()
    var parameters: Parameters
    /// references the current visible Views
    var viewCaches: [CalendarType: UIView] = [:]
    
    private(set) var calendarData: CalendarData
    private var weekData: WeekData
    private(set) var monthData: MonthData
    private var dayData: DayData
    private(set) var yearData: YearData
    private let listData: ListViewData
    
    public private(set) var dayView: DayView
    private(set) var weekView: WeekView
    private(set) var monthView: MonthView
    private(set) var yearView: YearView
    private(set) var listView: ListView
    
    public convenience init(frame: CGRect, date: Date? = nil, style: Style = Style(), years: Int = 4) {
        let calendarData = CalendarData(date: date ?? Date(), years: years, style: style.adaptiveStyle)
        self.init(frame: frame, date: date, style: style, calendarData: calendarData)
    }
    
    public convenience init<R: YearRange>(frame: CGRect, date: Date? = nil, style: Style = Style(), yearRange: R) where R.Bound == Int {
        self.init(frame: frame, date: date, style: style, startYear: yearRange.lowerBound, endYear: yearRange.upperBound)
    }
    
    public convenience init(frame: CGRect, date: Date? = nil, style: Style = Style(), startYear: Int, endYear: Int) {
        let calendarData = CalendarData(date: date ?? Date(), style: style.adaptiveStyle, startYear: startYear, endYear: endYear)
        self.init(frame: frame, date: date, style: style, calendarData: calendarData)
    }
    
    private init(frame: CGRect, date: Date?, style: Style, calendarData: CalendarData) {
        let adaptiveStyle = style.adaptiveStyle
        self.parameters = .init(type: style.defaultType ?? .day, style: adaptiveStyle)
        self.calendarData = calendarData
        
        // day view
        self.dayData = DayData(data: calendarData, startDay: adaptiveStyle.startWeekDay)
        self.dayView = DayView(parameters: .init(style: adaptiveStyle, data: dayData), frame: frame)
        
        // week view
        self.weekData = WeekData(data: calendarData)
        self.weekView = WeekView(parameters: .init(data: weekData, style: adaptiveStyle), frame: frame)
        
        // month view
        self.monthData = MonthData(parameters: .init(data: calendarData))
        self.monthView = MonthView(parameters: .init(monthData: monthData, style: adaptiveStyle), frame: frame)
        
        // year view
        self.yearData = YearData(data: monthData.data, date: calendarData.date, style: adaptiveStyle)
        self.yearView = YearView(data: yearData, frame: frame)
        
        // list view
        self.listData = ListViewData(data: calendarData)
        let params = ListView.Parameters(data: listData)
        self.listView = ListView(parameters: params, frame: frame)
        
        super.init(frame: frame)
        
        setup(with: date)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(with date: Date?) {
        dayView.scrollableWeekView.dataSource = self
        dayView.dataSource = self
        dayView.delegate = self
        
        weekView.scrollableWeekView.dataSource = self
        weekView.dataSource = self
        weekView.delegate = self
        
        monthView.delegate = self
        monthView.dataSource = self
        monthView.willSelectDate = { [weak self] (date) in
            self?.delegate?.willSelectDate(date, type: .month)
        }
        
        yearView.delegate = self
        yearView.dataSource = self
        
        listView.dataSource = self
        listView.delegate = self
        
        viewCaches = [.day: dayView, .week: weekView, .month: monthView, .year: yearView, .list: listView]
        
        if let defaultType = style.adaptiveStyle.defaultType {
            parameters.type = defaultType
        }
        set(type: parameters.type, date: date)
        reloadAllStyles(style.adaptiveStyle, force: true)
    }
}

#endif
