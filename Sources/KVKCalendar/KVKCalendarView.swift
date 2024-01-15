//
//  CalendarView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI
import EventKit

@available(iOS 17.0, *)
public struct KVKCalendarSwiftUIView: View {

    private var type: CalendarType
    @State private var vm: KVKCalendarViewModel
    
    public init(type: CalendarType,
                date: Date,
                events: [Event],
                selectedEvent: Event? = nil,
                style: KVKCalendar.Style = KVKCalendar.Style()) {
        self.type = type
        _vm = State(initialValue: KVKCalendarViewModel(date: date, events: events, selectedEvent: selectedEvent, style: style))
    }
    
    public var body: some View {
        switch type {
        case .day:
            if let item = vm.dayData {
                WeekNewView(vm: item)
            } else {
                EmptyView()
            }
        case .week:
            if let item = vm.weekData {
                WeekNewView(vm: item)
            } else {
                EmptyView()
            }
        case .month:
            if let item = vm.monthData {
                MonthNewView(vm: item)
            } else {
                EmptyView()
            }
        case .year:
            EmptyView() // YearNewView(data: vm.data)
        case .list:
            EmptyView() // ListNewView(params: vm.listData, date: $vm.date, event: $vm.selectedEvent, events: .constant([]))
        }
    }
}

@available(iOS 17.0, *)
private struct PreviewProxy: View {
    @State var type = CalendarType.week
    @State var date = Date()
    
    var body: some View {
        NavigationStack {
            KVKCalendarSwiftUIView(type: type, date: date, events: [])
                .navigationTitle(date.description)
                .navigationBarTitleDisplayMode(.inline)
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

@available(iOS 17.0, *)
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
    
    private(set) var dayView: DayView
    private(set) var weekView: WeekView
    private(set) var monthView: MonthView
    private(set) var yearView: YearView
    private(set) var listView: ListView
    
    public init(frame: CGRect, date: Date? = nil, style: Style = Style(), years: Int = 4) {
        let adaptiveStyle = style.adaptiveStyle
        self.parameters = .init(type: style.defaultType ?? .day, style: adaptiveStyle)
        self.calendarData = CalendarData(date: date ?? Date(), years: years, style: adaptiveStyle)
        
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
        
        if let defaultType = adaptiveStyle.defaultType {
            parameters.type = defaultType
        }
        set(type: parameters.type, date: date)
        reloadAllStyles(adaptiveStyle, force: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

#endif
