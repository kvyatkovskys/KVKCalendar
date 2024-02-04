//
//  WeekView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
struct WeekNewView: View {
    
    @State var vm: WeekNewData
    @Binding var date: Date
    @Binding var event: KVKCalendar.Event?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollableWeekNewView(date: $vm.date, weeks: vm.weeks, type: vm.type, style: vm.style)
                .padding(.top, 2)
            GeometryReader { (geometry) in
                TimelineUIKitView(params: TimelinePageWrapper.Parameters(style: vm.style, dates: vm.timelineDays, events: vm.events, recurringEvents: vm.recurringEvents), frame: geometry.frame(in: .local), date: $vm.date, willDate: .constant(.now), event: $vm.event)
            }
        }
        .onChange(of: vm.event) { newValue in
            event = newValue
        }
        .onChange(of: vm.date) { newValue in
            date = newValue
        }
        .task {
            await vm.setup()
        }
    }
    
}

@available(iOS 17.0, *)
private struct DayPreviewView: View {
    @State var date: Date
    var style: Style
    let commonData: CalendarData
    let events: [Event] = [
        .stub(id: "1", startFrom: -100, duration: 50),
        .stub(id: "2", startFrom: -120, duration: 20),
        .stub(id: "3", startFrom: 30, duration: 55),
        .stub(id: "4", startFrom: 85, duration: 30),
        .stub(id: "5", startFrom: 85, duration: 30)
    ]
    let vmDay: WeekNewData
    
    init() {
        _date = State(initialValue: Date.now)
        style = Style()
        style.startWeekDay = .monday
        let data = CalendarData(date: .now, years: 1, style: style)
        commonData = data
        vmDay = WeekNewData(data: data, type: .day)
        vmDay.events = events
        vmDay.allDayEvents = [.allDayStub(id: "-2")]
    }
    
    var body: some View {
        WeekNewView(vm: vmDay, date: $date, event: .constant(nil))
    }
}

@available(iOS 17.0, *)
#Preview("Day View") {
    DayPreviewView()
}

@available(iOS 17.0, *)
#Preview("Week View") {
    var style = Style()
    style.startWeekDay = .monday
    let commonData = CalendarData(date: Date(), years: 1, style: style)
    let events: [Event] = [
        .stub(id: "1", startFrom: -100, duration: 50),
        .stub(id: "2", startFrom: -120, duration: 20),
        .stub(id: "3", startFrom: 30, duration: 55),
        .stub(id: "4", startFrom: 85, duration: 30),
        .stub(id: "5", startFrom: 85, duration: 30)
    ]
    let vmWeek = WeekNewData(data: commonData, type: .week)
    vmWeek.events = events
    vmWeek.allDayEvents = [.allDayStub(id: "-2")]
    return WeekNewView(vm: vmWeek, date: .constant(.now), event: .constant(nil))
}

final class WeekView: UIView {
    
    struct Parameters {
        var visibleDates: [Date] = []
        var data: WeekData
        var style: Style
    }
    
    private var parameters: Parameters
    private var timelineScale: CGFloat
    
    private var isFullyWeek: Bool {
        style.week.maxDays == 7
    }
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    var scrollableWeekView = ScrollableWeekView(parameters: .init(frame: .zero,
                                                                  weeks: [],
                                                                  date: Date(),
                                                                  type: .week,
                                                                  style: Style()))
    var timelinePage = TimelinePageView(maxLimit: 0, pages: [], frame: .zero)
    
    private var topBackgroundView = UIView()
    private var scrollToCurrentTimeOnlyOnInit: Bool?
    
    private lazy var titleInCornerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = parameters.style.headerScroll.titleDateColorCorner
        return label
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        self.timelineScale = parameters.style.timeline.scale?.min ?? 1
        super.init(frame: frame)
        
        if case .onlyOnInitForDate = parameters.style.timeline.scrollLineHourMode {
            scrollToCurrentTimeOnlyOnInit = true
        }
    }
    
    func setDate(_ date: Date, animated: Bool) {
        parameters.data.date = date
        scrollableWeekView.setDate(date)
        parameters.visibleDates = getVisibleDatesFor(date: date)
    }
    
    func reloadData(_ events: [Event]) {
        parameters.data.recurringEvents = events.filter { $0.recurringType != .none }
        parameters.data.events = parameters.data.filterEvents(events, dates: parameters.visibleDates)
        timelinePage.timelineView?.create(dates: parameters.visibleDates,
                                          events: parameters.data.events,
                                          recurringEvents: parameters.data.recurringEvents,
                                          selectedDate: parameters.data.date)
    }
    
    private func getVisibleDatesFor(date: Date) -> [Date] {
        guard let scrollDate = getScrollDate(date: date) else { return [] }
        
        let days = scrollableWeekView.getDatesByDate(scrollDate)
        return days.compactMap { $0.date }
    }
    
    private func getScrollDate(date: Date) -> Date? {
        guard isFullyWeek else {
            return date
        }
        
        return style.startWeekDay == .sunday ? date.kvkStartSundayOfWeek : date.kvkStartMondayOfWeek
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadDays(data: CalendarData, style: Style) {
        parameters.data.reloadData(data, startDay: style.startWeekDay, maxDays: style.week.maxDays)
    }
    
    func reloadVisibleDates() {
        parameters.visibleDates = getVisibleDatesFor(date: parameters.data.date)
    }
    
    func updateScrollableWeeks() {
        scrollableWeekView.updateWeeks(weeks: parameters.data.weeks)
    }
}

extension WeekView {
    
    private func didSelectDate(_ date: Date, type: CalendarType) {
        let newDates = getVisibleDatesFor(date: date)
        if parameters.visibleDates != newDates {
            parameters.visibleDates = newDates
        }
        delegate?.didSelectDates([date], type: type, frame: nil)
    }
    
}

extension WeekView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            parameters.style
        }
        set {
            parameters.style = newValue
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        var timelineFrame = timelinePage.frame
        timelineFrame.size.width = frame.width
        
        if !style.headerScroll.isHidden {
            topBackgroundView.frame.size.width = frame.width
            scrollableWeekView.reloadFrame(frame)
            timelineFrame.size.height = frame.height - scrollableWeekView.frame.height
        } else {
            timelineFrame.size.height = frame.height
        }
        
        timelinePage.frame = timelineFrame
        timelinePage.timelineView?.reloadFrame(CGRect(origin: .zero, size: timelineFrame.size))
        timelinePage.timelineView?.create(dates: parameters.visibleDates,
                                          events: parameters.data.events,
                                          recurringEvents: parameters.data.recurringEvents,
                                          selectedDate: parameters.data.date)
        timelinePage.reloadCachedControllers()
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        let reload = self.style != style
        self.style = style
        setUI(reload: reload || force)
        timelinePage.reloadPages()
        reloadFrame(frame)
    }
    
    func setUI(reload: Bool) {
        subviews.forEach { $0.removeFromSuperview() }
        
        if reload {
            topBackgroundView = setupTopBackgroundView()
            scrollableWeekView = setupScrollableWeekView()
            scrollableWeekView.updateStyle(style, force: reload)
            
            if !style.headerScroll.isHidden {
                addSubview(topBackgroundView)
                topBackgroundView.addSubview(scrollableWeekView)
            }
            
            timelinePage = setupTimelinePageView()
            timelinePage.didSwitchTimelineView = { [weak self] (timeline, type) in
                guard let self = self else { return }
                
                let newTimeline = self.createTimelineView(frame: self.timelinePage.bounds)
                newTimeline.updateStyle(self.style, force: reload)
                switch type {
                case .next:
                    self.nextDate()
                    self.timelinePage.addNewTimelineView(newTimeline, to: .end)
                case .previous:
                    self.previousDate()
                    self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
                }
                
                self.didSelectDate(self.parameters.data.date, type: .week)
            }
            
            timelinePage.willDisplayTimelineView = { [weak self] (timeline, type) in
                guard let self = self else { return }
                
                let nextDate: Date?
                switch type {
                case .next:
                    nextDate = self.parameters.style.calendar.date(byAdding: .day,
                                                                   value: self.style.week.maxDays,
                                                                   to: self.parameters.data.date)
                case .previous:
                    nextDate = self.parameters.style.calendar.date(byAdding: .day,
                                                                   value: -self.style.week.maxDays,
                                                                   to: self.parameters.data.date)
                }
                
                if let offset = self.timelinePage.timelineView?.contentOffset {
                    timeline.contentOffset = offset
                }
                
                timeline.create(dates: self.getVisibleDatesFor(date: nextDate ?? self.parameters.data.date),
                                events: self.parameters.data.events,
                                recurringEvents: self.parameters.data.recurringEvents,
                                selectedDate: self.parameters.data.date)
            }
            timelinePage.updateStyle(style, force: reload)
        }
        
        addSubview(timelinePage)
        timelinePage.isPagingEnabled = style.timeline.scrollDirections.contains(.horizontal)
    }
    
    private func createTimelineView(frame: CGRect) -> TimelineView {
        var viewFrame = frame
        viewFrame.origin = .zero
        
        let view = TimelineView(parameters: .init(style: style,
                                                  type: .week,
                                                  scale: timelineScale,
                                                  scrollToCurrentTimeOnlyOnInit: scrollToCurrentTimeOnlyOnInit),
                                frame: viewFrame)
        view.delegate = self
        view.dataSource = dataSource
        view.deselectEvent = { [weak self] (event) in
            self?.delegate?.didDeselectEvent(event, animated: true)
        }
        view.didChangeParameters = { [weak self] (params) in
            if params.scale != self?.timelineScale {
                self?.timelineScale = params.scale
            }
            if params.scrollToCurrentTimeOnlyOnInit != self?.scrollToCurrentTimeOnlyOnInit {
                self?.scrollToCurrentTimeOnlyOnInit = params.scrollToCurrentTimeOnlyOnInit
            }
        }
        return view
    }
    
    private func setupTimelinePageView() -> TimelinePageView {
        var timelineFrame = frame
        
        if !style.headerScroll.isHidden {
            timelineFrame.origin.y = scrollableWeekView.frame.height
            timelineFrame.size.height -= scrollableWeekView.frame.height
        }
        
        let timelineViews = Array(0..<style.timeline.maxLimitCachedPages).reduce([]) { (acc, _) -> [TimelineView] in
            return acc + [createTimelineView(frame: timelineFrame)]
        }
        let page = TimelinePageView(maxLimit: style.timeline.maxLimitCachedPages,
                                    pages: timelineViews,
                                    frame: timelineFrame)
        return page
    }
    
    private func setupTopBackgroundView() -> UIView {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: heightView))
        view.backgroundColor = style.headerScroll.colorBackground
        return view
    }
    
    private func setupScrollableWeekView() -> ScrollableWeekView {
        let heightView: CGFloat
        if style.headerScroll.isHiddenSubview {
            heightView = style.headerScroll.heightHeaderWeek
        } else {
            heightView = style.headerScroll.heightHeaderWeek + style.headerScroll.heightSubviewHeader
        }
        let view = ScrollableWeekView(parameters: .init(frame: CGRect(x: 0, y: 0,
                                                                       width: frame.width, height: heightView),
                                                        weeks: parameters.data.weeks,
                                                         date: parameters.data.date,
                                                         type: .week,
                                                         style: style))
        view.dataSource = dataSource
        view.didSelectDate = { [weak self] (date, type) in
            guard let self = self else { return }
            if let item = date {
                self.parameters.data.date = item
                self.didSelectDate(item, type: type)
                self.delegate?.didDisplayHeaderTitle(item, style: self.style, type: type)
            }
        }
        view.didTrackScrollOffset = { [weak self] (offset, stop) in
            self?.timelinePage.timelineView?.moveEvents(offset: offset, stop: stop)
        }
        view.didChangeDay = { [weak self] (type) in
            guard let self = self else { return }
            
            self.timelinePage.changePage(type)
            let newTimeline = self.createTimelineView(frame: self.timelinePage.bounds)
            switch type {
            case .next:
                self.timelinePage.addNewTimelineView(newTimeline, to: .end)
            case .previous:
                self.timelinePage.addNewTimelineView(newTimeline, to: .begin)
            }
        }
        view.didUpdateStyle = { [weak self] (type) in
            guard let self = self else { return }
            
            self.delegate?.didUpdateStyle(self.scrollableWeekView.style, type: type)
        }
        return view
    }
    
}

extension WeekView: TimelineDelegate {
    
    func didDisplayEvents(_ events: [Event], dates: [Date?]) {
        delegate?.didDisplayEvents(events, dates: dates, type: .week)
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: .week, frame: frame)
    }
    
    func nextDate() {
        let date = scrollableWeekView.calculateDateWithOffset(style.week.maxDays, needScrollToDate: true)
        parameters.data.date = date
        delegate?.didDisplayHeaderTitle(date, style: style, type: .week)
    }
    
    func previousDate() {
        let date = scrollableWeekView.calculateDateWithOffset(-style.week.maxDays, needScrollToDate: true)
        parameters.data.date = date
        delegate?.didDisplayHeaderTitle(date, style: style, type: .week)
    }
    
    func swipeX(transform: CGAffineTransform, stop: Bool) {
        guard !stop else { return }
        
        scrollableWeekView.scrollHeaderByTransform(transform)
    }
    
    func didResizeEvent(_ event: Event, startTime: ResizeTime, endTime: ResizeTime) {
        var startComponents = DateComponents()
        startComponents.year = event.start.kvkYear
        startComponents.month = event.start.kvkMonth
        startComponents.day = event.start.kvkDay
        startComponents.hour = startTime.hour
        startComponents.minute = startTime.minute
        let startDate = style.calendar.date(from: startComponents)
        
        var endComponents = DateComponents()
        endComponents.year = event.end.kvkYear
        endComponents.month = event.end.kvkMonth
        endComponents.day = event.end.kvkDay
        endComponents.hour = endTime.hour
        endComponents.minute = endTime.minute
        let endDate = style.calendar.date(from: endComponents)
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
    func didAddNewEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint) {
        var components = DateComponents()
        components.year = event.start.kvkYear
        components.month = event.start.kvkMonth
        components.day = event.start.kvkDay
        components.hour = hour
        components.minute = minute
        let newDate = style.calendar.date(from: components)
        delegate?.didAddNewEvent(event, newDate)
    }
    
    func didChangeEvent(_ event: Event, minute: Int, hour: Int, point: CGPoint, newDate: Date?) {
        var day = event.start.kvkDay
        var month = event.start.kvkMonth
        var year = event.start.kvkYear
        if let newDayEvent = newDate {
            day = newDayEvent.kvkDay
            month = newDayEvent.kvkMonth
            year = newDayEvent.kvkYear
        } else if let newDate = scrollableWeekView.getDateByPointX(point.x), day != newDate.kvkDay {
            day = newDate.kvkDay
            month = newDate.kvkMonth
            year = newDate.kvkYear
        }
        
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = day
        startComponents.hour = hour
        startComponents.minute = minute
        let startDate = style.calendar.date(from: startComponents)
        
        let hourOffset = event.end.kvkHour - event.start.kvkHour
        let minuteOffset = event.end.kvkMinute - event.start.kvkMinute
        var endComponents = DateComponents()
        
        if event.end.kvkYear != event.start.kvkYear {
            let offset = event.end.kvkYear - event.start.kvkYear
            endComponents.year = year + offset
        } else {
            endComponents.year = year
        }
        
        if event.end.kvkMonth != event.start.kvkMonth {
            let offset = event.end.kvkMonth - event.start.kvkMonth
            endComponents.month = month + offset
        } else {
            endComponents.month = month
        }
        
        if event.end.kvkDay != event.start.kvkDay {
            let offset = event.end.kvkDay - event.start.kvkDay
            endComponents.day = day + offset
        } else {
            endComponents.day = day
        }
        
        endComponents.hour = hour + hourOffset
        endComponents.minute = minute + minuteOffset
        let endDate = style.calendar.date(from: endComponents)
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
    }
    
    func dequeueTimeLabel(_ label: TimelineLabel) -> (current: TimelineLabel, others: [UILabel])? {
        handleTimelineLabel(zones: style.selectedTimeZones, label: label)
    }
    
}

#endif
