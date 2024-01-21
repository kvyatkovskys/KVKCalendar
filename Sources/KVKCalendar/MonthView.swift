//
//  MonthView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
struct MonthNewView: View {
    
    @State private var vm: KVKCalendar.MonthNewData
    
    init(vm: MonthNewData) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        ScrollViewReader { (proxy) in
            VStack(spacing: 0) {
                MonthWeekView(style: vm.style, date: vm.headerDate) {
                    vm.date = .now
                    withAnimation {
                        vm.scrollId = vm.todayIdx
                    }
                }
                .background(.thickMaterial)
                scrollView
            }
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            if Platform.currentInterface == .phone {
                scrollContentView
            } else {
                scrollContentView
                    .scrollTargetLayout()
            }
        }
        .scrollPosition(id: $vm.scrollId)
    }
    
    private var scrollContentView: some View {
        LazyVStack(spacing: 0) {
            ForEach(vm.data.months.indices, id: \.self) { (idx) in
                let month = vm.data.months[idx]
                ContentGrid(month: month,
                            style: vm.style,
                            date: $vm.date,
                            selectedEvent: $vm.selectedEvent)
                .id(idx)
            }
        }
    }
}

@available(iOS 17.0, *)
private struct ContentGrid: View {
    
    var month: KVKCalendar.Month
    var style: KVKCalendar.Style
    @Binding var date: Date
    @Binding var selectedEvent: KVKCalendar.Event?
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]
    
    private var tapCountToSelectDay: Int {
        Platform.currentInterface == .phone ? 1 : 2
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(month.days) { (day) in
                MonthDayView(day: day, selectedDate: date, style: style, selectedEvent: $selectedEvent)
                    .onTapGesture(count: tapCountToSelectDay) {
                        withAnimation {
                            date = day.date ?? Date()
                        }
                    }
                    .disabled(day.type == .empty)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy"
    let date = formatter.date(from: "01.01.2022") ?? Date()
    var style = Style()
    style.startWeekDay = .sunday
    var data = CalendarData(date: date, years: 1, style: style)
    var allDayEvent = Event.stub(id: "4")
    allDayEvent.isAllDay = true
    data.months[0].days[0].events = [allDayEvent, .stub(id: "1"), .stub(id: "2"), .stub(id: "3")]
    return MonthNewView(vm: MonthNewData(data: data))
}

@available(iOS 17.0, *)
struct MonthDayView: View {
    
    let day: Day
    let selectedDate: Date
    let style: KVKCalendar.Style
    @Binding var selectedEvent: KVKCalendar.Event?
    
    private var dayTxt: String {
        switch day.type {
        case .empty:
            return ""
        default:
            guard let dt = day.date else { return "" }
            return "\(dt.kvkDay)"
        }
    }
    private var date: Date {
        day.date ?? Date()
    }
    private var height: CGFloat {
        switch Platform.currentInterface {
        case .phone:
            return 80
        default:
            return 180
        }
    }
    private var dayPadding: CGFloat {
        Platform.currentInterface == .phone ? 0 : 5
    }
    private var borderColor: Color {
        Platform.currentInterface == .phone ? .clear : Color(uiColor: style.month.colorSeparator)
    }
    private var borderWidth: CGFloat {
        Platform.currentInterface == .phone ? 0 : style.month.widthSeparator
    }
    
    var body: some View {
        if Platform.currentInterface == .phone {
            bodyView
        } else {
            bodyView.frame(minHeight: 170)
        }
    }
    
    private var bodyView: some View {
        VStack {
            if day.type != .empty && Platform.currentInterface == .phone {
                VStack {
                    if day.date?.kvkDay == 1 {
                        Text(date.titleForLocale(style.locale, formatter: style.month.shortInDayMonthFormatter).capitalized)
                            .foregroundStyle(getTxtHeaderColor(day))
                            .minimumScaleFactor(0.9)
                            .font(Font(style.month.fontTitleHeader))
                    }
                }
                .frame(height: 14)
                Divider()
            }
            HStack {
                if Platform.currentInterface != .phone {
                    Spacer()
                }
                VStack {
                    Text(dayTxt)
                        .foregroundStyle(getTxtColor(day, selectedDay: selectedDate, style: style))
                        .font(Font(style.month.fontNameDate))
                        .padding(4)
                        .frame(minWidth: 25)
                }
                .background(getBgTxtColor(day, selectedDay: selectedDate))
                .clipShape(Capsule())
                .padding([.top, .trailing], dayPadding)
            }
            if Platform.currentInterface == .phone && !day.events.isEmpty {
                Circle()
                    .foregroundStyle(.gray)
                    .frame(width: 8, height: 8)
                    .fixedSize()
            } else {
                VStack(spacing: 4) {
                    ForEach(day.events.prefix(4)) { (event) in
                        MonthEventView(event: event, selectedEvent: $selectedEvent)
                    }
                }
                .padding([.leading, .trailing], 2)
            }
            Spacer()
        }
        .background(getBgColor(date, style: style))
        .border(borderColor, width: borderWidth)
    }
    
    private func getTxtHeaderColor(_ day: Day) -> Color {
        let currentDate = Date()
        if let dt = day.date,
           dt.kvkYear == currentDate.kvkYear,
           dt.kvkMonth == currentDate.kvkMonth {
            return .red
        } else {
            return .black
        }
    }
    
    private func getBgTxtColor(_ day: Day,
                               selectedDay: Date) -> Color {
        if day.type == .empty {
            return .clear
        }
        
        let date = day.date ?? Date()
        if date.kvkIsEqual(selectedDay) && date.kvkIsEqual(Date()) {
            return .red
        } else if date.kvkIsEqual(selectedDay) {
            return .black
        } else if date.isWeekend && Platform.currentInterface != .phone {
            return .clear
        } else {
            return .white
        }
    }
    
    private func getTxtColor(_ day: Day,
                             selectedDay: Date,
                             style: Style) -> Color {
        if day.type == .empty {
            return .clear
        }
        
        let date = day.date ?? Date()
        if date.kvkIsEqual(Date()) && date.kvkIsEqual(selectedDay) {
            return .white
        } else if date.kvkIsEqual(selectedDay) {
            return .white
        } else if date.isWeekend {
            return Color(uiColor: style.week.colorWeekendDate)
        } else if date.isWeekday {
            return Color(uiColor: style.week.colorDate)
        } else {
            return .black
        }
    }
    
    private func getBgColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return Color(uiColor: style.month.colorBackgroundWeekendDate)
        } else {
            return Color(uiColor: style.month.colorBackgroundDate)
        }
    }
    
}

@available(iOS 17.0, *)
#Preview("Month day view") {
    var allDayEvent = Event.stub(id: "4")
    allDayEvent.isAllDay = true
    let events: [Event] = [allDayEvent, .stub(id: "1"), .stub(id: "2"), .stub(id: "3")]
    return MonthDayView(day: Day(type: .monday, date: Date(), data: events), selectedDate: Date(), style: Style(), selectedEvent: .constant(nil))
}

@available(iOS 17.0, *)
struct MonthWeekView: View, WeekPreparing {
    
    private var date: Date
    private var days: [Date] = []
    private let style: KVKCalendar.Style
    private var didSelectToday: (() -> Void)?
    
    init(style: KVKCalendar.Style,
         date: Date,
         didSelectToday: (() -> Void)? = nil) {
        self.style = style
        self.date = date
        self.didSelectToday = didSelectToday
        days = getWeekDays(style: style)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if Platform.currentInterface != .phone {
                HStack {
                    Text(date.titleForLocale(style.locale, formatter: style.month.titleFormatter))
                        .foregroundStyle(getMonthTxtColor(date, style: style))
                        .font(Font(style.month.fontTitleHeader))
                    Spacer()
                    Button("Today") {
                        didSelectToday?()
                    }
                    .tint(.red)
                }
                .padding([.leading, .trailing])
            }
            HStack {
                ForEach(days, id: \.self) { (day) in
                    Text(day.titleForLocale(style.locale, formatter: style.month.weekdayFormatter))
                        .foregroundStyle(getTxtColor(day, style: style))
                        .font(Font(style.month.weekFont))
                        .minimumScaleFactor(0.5)
                        .background(getTxtBgColor(day, style: style))
                        .frame(maxWidth: .infinity,
                               alignment: Platform.currentInterface == .phone ? .center : .trailing)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding([.top, .bottom], 10)
    }
    
    private func getMonthTxtColor(_ date: Date, style: Style) -> Color {
        if Date().kvkYear == date.kvkYear && Date().kvkMonth == date.kvkMonth {
            return Color(uiColor: style.month.colorTitleCurrentDate)
        } else {
            return Color(uiColor: style.month.colorTitleHeader)
        }
    }
    
    private func getTxtColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return Color(uiColor: style.week.colorWeekendDate)
        } else if day.isWeekday {
            return Color(uiColor: style.week.colorDate)
        } else {
            return .clear
        }
    }
    
    private func getTxtBgColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return Color(uiColor: style.week.colorWeekendBackground)
        } else if day.isWeekday {
            return Color(uiColor: style.week.colorWeekdayBackground)
        } else {
            return .clear
        }
    }
    
}

@available(iOS 17.0, *)
#Preview("Month week view") {
    var style = Style()
    style.startWeekDay = .sunday
    return MonthWeekView(style: style, date: Date())
}

@available(iOS 17.0, *)
struct MonthEventView: View {
    var event: KVKCalendar.Event
    @Binding var selectedEvent: KVKCalendar.Event?
    
    var body: some View {
        Button {
            withAnimation {
                selectedEvent = event
            }
        } label: {
            HStack {
                if event.isAllDay {
                    Text(event.title.month ?? "")
                        .foregroundStyle(txtColor)
                        .lineLimit(1)
                        .padding(2)
                } else {
                    Circle()
                        .frame(width: 7, height: 7)
                        .foregroundStyle(Color(uiColor: event.backgroundColor))
                    Text(event.title.month ?? "")
                        .foregroundStyle(txtColor)
                        .lineLimit(1)
                    Text(event.start.formatted(.dateTime.hour()))
                        .font(.subheadline)
                        .foregroundStyle(txtTimeColor)
                }
            }
            .padding([.leading, .trailing], 1)
        }
        .tint(.black)
        .background(bgColor)
        .cornerRadius(radius)
    }
    
    private var radius: CGFloat {
        if event.uniqID == selectedEvent?.uniqID {
            return 5
        }
        return event.isAllDay ? 5 : 0
    }
    
    private var txtColor: Color {
        event.uniqID == selectedEvent?.uniqID ? .white : .black
    }
    
    private var txtTimeColor: Color {
        event.uniqID == selectedEvent?.uniqID ? .white : .gray
    }
    
    private var bgColor: Color {
        if event.uniqID == selectedEvent?.uniqID {
            return Color(uiColor: event.color?.value ?? event.backgroundColor)
        }
        return event.isAllDay ? Color(uiColor: event.backgroundColor) : .clear
    }
}

@available(iOS 17.0, *)
#Preview("General event") {
    var event = Event.stub(id: "1")
    event.isAllDay = false
    return MonthEventView(event: event, selectedEvent: .constant(nil))
}

@available(iOS 17.0, *)
#Preview("All-day event") {
    var event2 = Event.stub(id: "2")
    event2.isAllDay = true
    return MonthEventView(event: event2, selectedEvent: .constant(nil))
}

final class MonthView: UIView {
    
    struct Parameters {
        var monthData: MonthData
        var style: Style
    }
    
    private var parameters: Parameters
    private var collectionView: UICollectionView?
    private var eventPreview: UIView?
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    var willSelectDate: ((Date) -> Void)?
    
    private var headerViewFrame: CGRect = .zero
    private var weekHeaderView = WeekHeaderView(parameters: .init(style: Style()), frame: .zero)
    
    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()
    
    init(parameters: Parameters, frame: CGRect) {
        self.parameters = parameters
        super.init(frame: frame)
    }
    
    func setDate(_ date: Date, animated: Bool = false) {
        updateHeaderView(date, frame: headerViewFrame)
        parameters.monthData.date = date
        parameters.monthData.selectedDates.removeAll()
        reload()
        scrollToDate(date, animated: animated)
    }
    
    func reloadData(_ events: [Event]) {
        let displayableValues = parameters.monthData.reloadEventsInDays(events: events,
                                                                        date: parameters.monthData.date)
        delegate?.didDisplayEvents(displayableValues.events, dates: displayableValues.dates, type: .month)
        reload()
    }
    
    func showSkeletonVisible(_ visible: Bool) {
        if visible {
            collectionView?.isScrollEnabled = false
        } else {
            collectionView?.isScrollEnabled = style.month.isScrollEnabled
        }
        parameters.monthData.isSkeletonVisible = visible
        reload(force: false)
    }
    
    // MARK: private func
    
    private func updateHeaderView(_ date: Date, frame: CGRect) {
        if let customHeaderView = dataSource?.willDisplayHeaderSubview(date: date, frame: frame, type: .month) {
            headerViewFrame = customHeaderView.frame
            addSubview(customHeaderView)
        } else {
            setHeaderTitleAndNotify(date)
        }
    }
    
    private func createCollectionView(frame: CGRect, style: MonthStyle) -> (view: UICollectionView, customView: Bool) {
        if let customCollectionView = dataSource?.willDisplayCollectionView(frame: frame, type: .month) {
            return (customCollectionView, true)
        }
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.isScrollEnabled = style.isScrollEnabled
        collection.dataSource = self
        collection.delegate = self
        
        if style.isPrefetchingEnabled {
            collection.prefetchDataSource = self
            collection.isPrefetchingEnabled = true
        }
        
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return (collection, false)
    }
    
    private func scrollToDate(_ date: Date, animated: Bool) {
        if let idx = parameters.monthData.data.months.firstIndex(where: { $0.date.kvkMonth == date.kvkMonth && $0.date.kvkYear == date.kvkYear }), idx != parameters.monthData.selectedSection {
            parameters.monthData.selectedSection = idx
            scrollToIndex(idx, animated: animated)
        } else {
            parameters.monthData.selectedSection = -1
        }
    }
    
    private func scrollToIndex(_ idx: Int, animated: Bool) {
        // to check when the calendarView is displayed on superview
        guard superview?.superview != nil && collectionView?.dataSource != nil else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self,
                  let collectionView = self.collectionView,
                  collectionView.numberOfSections >= idx else { return }
            
            if let attributes = self.collectionView?.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: idx)),
               let inset = self.collectionView?.contentInset {
                let contentOffset: CGPoint
                switch self.style.month.scrollDirection {
                case .vertical:
                    let offset = attributes.frame.origin.y - inset.top
                    contentOffset = CGPoint(x: 0, y: offset)
                case .horizontal:
                    let offset = attributes.frame.origin.x - inset.left
                    contentOffset = CGPoint(x: offset, y: 0)
                default:
                    contentOffset = .zero
                }
                self.collectionView?.setContentOffset(contentOffset, animated: animated)
            } else {
                let index = IndexPath(row: 0, section: idx)
                guard self.parameters.monthData.days[index] != nil else { return }
                
                let scrollType: UICollectionView.ScrollPosition = self.style.month.scrollDirection == .horizontal ? .left : .top
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx), at: scrollType, animated: animated)
            }
        }
    }
    
    private func didSelectDates(_ dates: [Date], indexPath: IndexPath) {
        guard let date = dates.last else {
            reload()
            return
        }
        
        parameters.monthData.date = date
        updateHeaderView(date, frame: headerViewFrame)
        
        let index = getActualCachedDay(indexPath: indexPath).indexPath
        let attributes = collectionView?.layoutAttributesForItem(at: index)
        let frame = collectionView?.convert(attributes?.frame ?? .zero, to: collectionView) ?? .zero
        
        delegate?.didSelectDates(dates, type: style.month.selectCalendarType, frame: frame)
        reload()
    }
    
    private func getVisibleDate() -> Date? {
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let days = cells.compactMap { (indexPath) -> Day in
            let index = getActualCachedDay(indexPath: indexPath).indexPath
            return parameters.monthData.data.months[index.section].days[index.row]
        }
        guard let newMoveDate = days.filter({ $0.date?.kvkDay == parameters.monthData.date.kvkDay }).first?.date else {
            let sorted = days.sorted(by: { ($0.date?.kvkDay ?? 0) < ($1.date?.kvkDay ?? 0) })
            if let lastDate = sorted.last?.date, lastDate.kvkDay < parameters.monthData.date.kvkDay {
                return lastDate
            }
            return nil
        }
        return newMoveDate
    }
    
    private func setHeaderTitleAndNotify(_ date: Date) {
        weekHeaderView.date = date
        delegate?.didDisplayHeaderTitle(date, style: style, type: .month)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MonthView: CalendarSettingProtocol {
    
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
        var collectionFrame = frame
        
        headerViewFrame.size.width = frame.width
        if let customHeaderView = dataSource?.willDisplayHeaderSubview(date: parameters.monthData.date, frame: headerViewFrame, type: .month) {
            headerViewFrame = customHeaderView.frame
            addSubview(customHeaderView)
        } else if !style.month.isHiddenTitleHeader {
            weekHeaderView.reloadFrame(frame)
        }
        
        if style.month.isHiddenTitleHeader {
            collectionFrame.origin.y = 0
        } else {
            collectionFrame.origin.y = headerViewFrame.height
            collectionFrame.size.height = collectionFrame.height - headerViewFrame.height
        }
        
        collectionView?.removeFromSuperview()
        collectionView = nil
        let result = createCollectionView(frame: collectionFrame, style: style.month)
        collectionView = result.view
        
        if let tempView = collectionView {
            addSubview(tempView)
            setupConstraintsIfNedeed(view: tempView, customView: result.customView)
        }
        
        reload()
        
        if let idx = parameters.monthData.data.months.firstIndex(where: { $0.date.kvkMonth == parameters.monthData.date.kvkMonth && $0.date.kvkYear == parameters.monthData.date.kvkYear }) {
            scrollToIndex(idx, animated: false)
        }
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        let reload = self.style != style
        self.style = style
        setUI(reload: reload || force)
        weekHeaderView.date = parameters.monthData.date
        if reload {
            parameters.monthData.selectedSection = -1
        }
    }
    
    func setUI(reload: Bool = false) {
        subviews.forEach { $0.removeFromSuperview() }
        
        layout.scrollDirection = style.month.scrollDirection
        collectionView = nil
        var collectionFrame = frame
        
        let height: CGFloat
        if style.month.isHiddenTitleHeader {
            height = style.month.heightHeaderWeek
        } else {
            height = style.month.heightHeaderWeek + style.month.heightTitleHeader + 5
        }
        headerViewFrame = CGRect(x: 0, y: 0, width: frame.width, height: height)
        
        if let customHeaderView = dataSource?.willDisplayHeaderSubview(date: parameters.monthData.date,
                                                                       frame: headerViewFrame,
                                                                       type: .month) {
            headerViewFrame = customHeaderView.frame
            addSubview(customHeaderView)
        } else if !style.month.isHiddenTitleHeader {
            if reload {
                weekHeaderView = setupWeekHeaderView(prepareFrame: headerViewFrame)
            }
            addSubview(weekHeaderView)
        }
        
        if style.month.isHiddenTitleHeader {
            collectionFrame.origin.y = 0
        } else {
            collectionFrame.origin.y = headerViewFrame.height
            collectionFrame.size.height = collectionFrame.height - headerViewFrame.height
        }
        
        let result = createCollectionView(frame: collectionFrame, style: style.month)
        collectionView = result.view
        
        if let tempView = collectionView {
            addSubview(tempView)
            setupConstraintsIfNedeed(view: tempView, customView: result.customView)
        }
    }
    
    private func setupConstraintsIfNedeed(view: UICollectionView, customView: Bool) {
        if !customView {
            view.translatesAutoresizingMaskIntoConstraints = false
            let top: NSLayoutConstraint
            if style.month.isHiddenTitleHeader {
                top = view.topAnchor.constraint(equalTo: topAnchor)
            } else {
                top = view.topAnchor.constraint(equalTo: topAnchor, constant: headerViewFrame.height)
            }
            let bottom = view.bottomAnchor.constraint(equalTo: bottomAnchor)
            let left = view.leftAnchor.constraint(equalTo: leftAnchor)
            let right = view.rightAnchor.constraint(equalTo: rightAnchor)
            NSLayoutConstraint.activate([top, bottom, left, right])
        }
    }
    
    private func setupWeekHeaderView(prepareFrame: CGRect) -> WeekHeaderView {
        let view = WeekHeaderView(parameters: .init(style: style), frame: prepareFrame)
        view.backgroundColor = style.week.colorBackground
        return view
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / parameters.monthData.itemsInPage
            let b = indexPath.item / parameters.monthData.rowsInPage - a * parameters.monthData.columnsInPage
            let c = indexPath.item % parameters.monthData.rowsInPage
            let newIdx = (c * parameters.monthData.columnsInPage + b) + a * parameters.monthData.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    private func getActualCachedDay(indexPath: IndexPath) -> MonthData.DayOfMonth {
        if let value = parameters.monthData.days[indexPath] {
            return value
        } else {
            let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
            return parameters.monthData.getDay(indexPath: index)
        }
    }
    
    private func reload(force: Bool = true) {
        if force {
            parameters.monthData.days.removeAll()
        }
        collectionView?.reloadData()
    }
}

// MARK: UICollectionViewDataSource

extension MonthView: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {
            let indexPath = getIndexForDirection(style.month.scrollDirection, indexPath: $0)
            let item = parameters.monthData.getDay(indexPath: indexPath)
            parameters.monthData.days[$0] = item
            
            if let cell = collectionView.cellForItem(at: indexPath) as? MonthCell,
               let day = item.day,
               let date = day.date
            {
                if let customEventsView = dataSource?.dequeueMonthViewEvents(day.events, date: date, frame: cell.customViewFrame) {
                    parameters.monthData.customEventsView[date] = customEventsView
                }
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        parameters.monthData.data.months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        parameters.monthData.data.months[section].days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = getActualCachedDay(indexPath: indexPath)
        guard let day = item.day else { return UICollectionViewCell() }
        
        if let cell = dataSource?.dequeueCell(parameter: .init(date: day.date, type: day.type, events: day.events),
                                              type: .month,
                                              view: collectionView,
                                              indexPath: item.indexPath) as? UICollectionViewCell {
            return cell
        } else {
            return collectionView.kvkDequeueCell(indexPath: item.indexPath) { (cell: MonthCell) in
                cell.setSkeletons(parameters.monthData.isSkeletonVisible)
                
                guard !parameters.monthData.isSkeletonVisible else { return }
                
                cell.delegate = self
                
                let date = day.date ?? Date()
                switch style.month.selectionMode {
                case .multiple:
                    cell.selectDate = parameters.monthData.selectedDates.contains(date) ? date : parameters.monthData.date
                case .single:
                    cell.selectDate = parameters.monthData.date
                case .disabled:
                    break
                }
                
                cell.style = style
                cell.day = day
                cell.events = day.events
                cell.isHidden = item.indexPath.row > parameters.monthData.daysCount
                
                if let date = day.date {
                    cell.isSelected = parameters.monthData.selectedDates.contains(date)
                } else {
                    cell.isSelected = false
                }
            }
        }
    }
}

// MARK: UICollectionViewDelegate

extension MonthView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let objectView = collectionView else { return }
        
        let center = convert(objectView.center, to: objectView)
        guard let index = objectView.indexPathForItem(at: center) else { return }
        
        let month = parameters.monthData.data.months[index.section]
        weekHeaderView.date = month.date
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard !style.month.isPagingEnabled, let objectView = collectionView else { return }

        let center = convert(objectView.center, to: objectView)
        guard let index = objectView.indexPathForItem(at: center) else { return }

        let month = parameters.monthData.data.months[index.section]
        setHeaderTitleAndNotify(month.date)
        guard style.month.autoSelectionDateWhenScrolling else { return }
        let newDate = parameters.monthData.findNextDateInMonth(month)
        guard parameters.monthData.date != newDate else { return }

        parameters.monthData.date = newDate
        willSelectDate?(newDate)
        reload()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard style.month.isPagingEnabled else { return }
        
        let visibleIndex: Int
        switch style.month.scrollDirection {
        case .vertical:
            visibleIndex = Int(targetContentOffset.pointee.y / scrollView.bounds.height)
        case .horizontal:
            visibleIndex = Int(targetContentOffset.pointee.x / scrollView.bounds.width)
        @unknown default:
            fatalError()
        }
        
        let month = parameters.monthData.data.months[visibleIndex]
        setHeaderTitleAndNotify(month.date)
        guard style.month.autoSelectionDateWhenScrolling else { return }
        let newDate = parameters.monthData.findNextDateInMonth(month)
        guard parameters.monthData.date != newDate else { return }
        
        parameters.monthData.date = newDate
        willSelectDate?(newDate)
        reload()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = getActualCachedDay(indexPath: indexPath)
        guard let date = item.day?.date else { return }
        
        switch style.month.selectionMode {
        case .multiple:
            parameters.monthData.selectedDates = parameters.monthData.updateSelectedDates(parameters.monthData.selectedDates,
                                                                                          date: date,
                                                                                          calendar: style.calendar)
            didSelectDates(parameters.monthData.selectedDates.compactMap({ $0 }), indexPath: item.indexPath)
        case .single:
            didSelectDates([date], indexPath: item.indexPath)
        case .disabled:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let item = getActualCachedDay(indexPath: indexPath)
        
        if let day = item.day, let size = delegate?.sizeForCell(day.date, type: .month) {
            return size
        }
        
        let width: CGFloat
        let height: CGFloat
        
        let heightSectionHeader = style.month.heightSectionHeader
        switch style.month.scrollDirection {
        case .horizontal:
            var superViewWidth = collectionView.bounds.width
            if !style.month.isHiddenSectionHeader && superViewWidth >= heightSectionHeader {
                superViewWidth -= heightSectionHeader
            }
            width = superViewWidth / 7
            height = collectionView.frame.height / 6
        case .vertical:
            if collectionView.frame.width > 0 {
                width = collectionView.frame.width / 7 - 0.2
            } else {
                width = 0
            }
            
            var superViewHeight = collectionView.bounds.height
            if !style.month.isHiddenSectionHeader && superViewHeight >= heightSectionHeader {
                superViewHeight -= heightSectionHeader
            }
            
            height = superViewHeight / CGFloat(item.weeks)
        @unknown default:
            fatalError()
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let month = parameters.monthData.data.months[indexPath.section]
        let index = IndexPath(row: 0, section: indexPath.section)
        
        if let headerView = dataSource?.dequeueHeader(date: month.date, type: .month, view: collectionView, indexPath: index) as? UICollectionReusableView {
            return headerView
        } else {
            return collectionView.kvkDequeueView(indexPath: index) { (headerView: MonthHeaderView) in
                headerView.value = (style, month.date)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard !style.month.isHiddenSectionHeader else { return .zero }
        
        let item = getActualCachedDay(indexPath: IndexPath(row: 0, section: section))
        
        if let date = item.day?.date, let size = delegate?.sizeForHeader(date, type: .month) {
            return size
        } else {
            switch style.month.scrollDirection {
            case .horizontal:
                return CGSize(width: style.month.heightSectionHeader, height: collectionView.bounds.height)
            case .vertical:
                return CGSize(width: collectionView.bounds.width, height: style.month.heightSectionHeader)
            @unknown default:
                fatalError()
            }
        }
    }
    
}

// MARK: Month Cell Delegate

extension MonthView: MonthCellDelegate {
    
    func dequeueViewEvents(_ events: [Event], date: Date, frame: CGRect) -> UIView? {
        if let item = parameters.monthData.customEventsView[date] {
            return item
        } else {
            return dataSource?.dequeueMonthViewEvents(events, date: date, frame: frame)
        }
    }
    
    func didSelectEvent(_ event: Event, frame: CGRect?) {
        delegate?.didSelectEvent(event, type: .month, frame: frame)
    }
    
    func didSelectMore(_ date: Date, frame: CGRect?) {
        delegate?.didSelectMore(date, frame: frame)
    }
    
    func didStartMoveEvent(_ event: EventViewGeneral, snapshot: UIView?, gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        
        parameters.monthData.movingEvent = event
        eventPreview = nil
        eventPreview = snapshot
        parameters.monthData.eventPreviewXOffset = (snapshot?.bounds.width ?? parameters.monthData.eventPreviewXOffset) / 2
        eventPreview?.frame.origin = CGPoint(x: point.x - parameters.monthData.eventPreviewXOffset, y: point.y - parameters.monthData.eventPreviewYOffset)
        eventPreview?.alpha = 0.9
        eventPreview?.tag = parameters.monthData.tagEventPagePreview
        eventPreview?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        guard let eventTemp = eventPreview else { return }
        
        collectionView?.addSubview(eventTemp)
        UIView.animate(withDuration: 0.3) {
            self.eventPreview?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        collectionView?.isScrollEnabled = false
    }
    
    func didEndMoveEvent(gesture: UILongPressGestureRecognizer) {
        eventPreview?.removeFromSuperview()
        eventPreview = nil
        
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView?.indexPathForItem(at: point), let event = parameters.monthData.movingEvent?.event else { return }
        
        parameters.monthData.movingEvent = nil
        let index = getIndexForDirection(style.month.scrollDirection, indexPath: indexPath)
        let day = parameters.monthData.data.months[index.section].days[index.row]
        let newDate = day.date ?? event.start
        
        var startComponents = DateComponents()
        startComponents.year = newDate.kvkYear
        startComponents.month = newDate.kvkMonth
        startComponents.day = newDate.kvkDay
        startComponents.hour = event.start.kvkHour
        startComponents.minute = event.start.kvkMinute
        let startDate = style.calendar.date(from: startComponents)
        
        var endComponents = DateComponents()
        endComponents.year = newDate.kvkYear
        endComponents.month = newDate.kvkMonth
        endComponents.day = newDate.kvkDay
        endComponents.hour = event.end.kvkHour
        endComponents.minute = event.end.kvkMinute
        let endDate = style.calendar.date(from: endComponents)
        
        delegate?.didChangeEvent(event, start: startDate, end: endDate)
        scrollToDate(newDate, animated: true)
        didSelectDates([newDate], indexPath: index)
        collectionView?.isScrollEnabled = true
    }
    
    func didChangeMoveEvent(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: collectionView)
        guard (collectionView?.frame.width ?? 0) >= (point.x + 20), (point.x - 20) >= 0 else { return }
        
        var offset = collectionView?.contentOffset ?? .zero
        let contentSize = collectionView?.contentSize ?? .zero
        if (point.y - 80) < offset.y, (point.y - (eventPreview?.bounds.height ?? 50)) >= 0 {
            // scroll up
            offset.y -= 5
            collectionView?.setContentOffset(offset, animated: false)
        } else if (point.y + 80) > (offset.y + (collectionView?.bounds.height ?? 0)), point.y + (eventPreview?.bounds.height ?? 50) <= contentSize.height {
            // scroll down
            offset.y += 5
            collectionView?.setContentOffset(offset, animated: false)
        }
        
        eventPreview?.frame.origin = CGPoint(x: point.x - parameters.monthData.eventPreviewXOffset,
                                             y: point.y - parameters.monthData.eventPreviewYOffset)
    }
}

#endif
