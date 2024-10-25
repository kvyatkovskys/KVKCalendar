//
//  ScrollableWeekView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

struct WeekItem: Identifiable {
    let identifier: Int
    let days: [KVKCalendar.Day]
    
    var id: Int { identifier }
}

@available(iOS 18.0, *)
struct ScrollableWeekNewView: View, ScrollableWeekProtocol {
    @Binding var date: Date
    var weeks: [WeekItem]
    var type: CalendarType
    var style: Style
    @State private var isScrolling: Bool = false
    
    private var daySize: CGSize {
        Platform.currentDevice == .phone ? CGSize(width: 40, height: 40) : CGSize(width: 30, height: 70)
    }
    private var spacing: CGFloat {
        Platform.currentDevice == .phone ? 5 : 0
    }
    private var leftPadding: CGFloat {
        type == .week ? style.timeline.widthTime + style.timeline.offsetTimeX : 0
    }
    private var dayShortFormatter: DateFormatter {
        let format = DateFormatter()
        format.dateFormat = "EEEEE"
        return format
    }
    private var todayTitle: String {
        "Today"
    }
    
    init(
        date: Binding<Date>,
        weeks: [WeekItem],
        type: CalendarType,
        style: Style
    ) {
        _date = date
        self.weeks = weeks
        self.type = type
        self.style = style
    }
    
    var body: some View {
        bodyView
    }
    
    private var bodyView: some View {
        VStack(spacing: spacing) {
            if Platform.currentInterface != .phone {
                HStack {
                    Text(
                        date.titleForLocale(
                            style.locale,
                            formatter: style.headerScroll.titleFormatter
                        )
                    )
                    .foregroundStyle(style.headerScroll.titleDateColor.suiColor)
                    .font(Font(style.headerScroll.titleDateFont))
                    Spacer()
                    Button(todayTitle) {
                        date = .now
                    }
                    .tint(.red)
                }
                .padding([.leading, .trailing])
            } else {
                WeekTitlesView(
                    style: style,
                    formatter: dayShortFormatter,
                    font: style.headerScroll.fontNameDay
                )
                .padding(.leading, leftPadding)
            }
            horizontalUIKitWeeksView
                .padding(.leading, leftPadding)
                .padding(.vertical, 3)
            if Platform.currentInterface == .phone {
                HStack {
                    Spacer()
                    Text(
                        date.titleForLocale(
                            style.locale,
                            formatter: style.headerScroll.titleFormatter
                        )
                    )
                    Spacer()
                }
            }
        }
    }
    
    private var horizontalUIKitWeeksView: some View {
        WeeksHorizontalView(weeks: weeks, style: style, date: $date) { day in
            if let date = day.date {
                getBtnViewFor(date, day: day)
            } else {
                EmptyView()
            }
        }
        .frame(height: 43)
    }
    
    private func getBtnViewFor(
        _ dt: Date,
        day: Day
    ) -> some View {
        Button(action: {
            date = dt
        }, label: {
            HStack(spacing: dt.kvkIsEqual(date) ? nil : 0) {
                if Platform.currentInterface != .phone {
                    Text(dt.titleForLocale(
                        style.locale,
                        formatter: style.month.weekdayFormatter)
                    )
                    .foregroundStyle(getTitleDayColor(dt))
                    .multilineTextAlignment(.trailing)
                }
                Group {
                    if day.date?.kvkIsEqual(date) ?? false {
                        Text("\(dt.kvkDay)")
                            .bold()
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                getBgTxtColor(
                                    day,
                                    selectedDay: date
                                )
                            )
                            .clipShape(Circle())
                    } else {
                        Text("\(dt.kvkDay)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .foregroundStyle(
                    getTxtColor(
                        day,
                        selectedDay: date
                    )
                )
                .multilineTextAlignment(.center)
            }
        })
        .tint(.black)
    }
    
    private func getBgTxtColor(
        _ day: Day,
        selectedDay: Date
    ) -> Color {
        if day.type == .empty {
            return .clear
        }
        
        let date = day.date ?? .now
        if date.kvkIsEqual(selectedDay) && date.kvkIsEqual(.now) {
            return .red
        } else if date.kvkIsEqual(selectedDay) {
            return .black
        } else if date.isWeekend && Platform.currentInterface != .phone {
            return .clear
        } else {
            return .white
        }
    }
    
    private func getTitleDayColor(_ date: Date) -> Color {
        if date.isWeekend {
            style.headerScroll.colorWeekendDate.suiColor
        } else if date.isWeekday {
            style.headerScroll.colorDate.suiColor
        } else {
            .black
        }
    }
    
    private func getTxtColor(
        _ day: Day,
        selectedDay: Date
    ) -> Color {
        if day.type == .empty {
            return .clear
        }
        let date = day.date ?? .now
        if date.kvkIsEqual(.now) && date.kvkIsEqual(selectedDay) {
            return .white
        } else if date.kvkIsEqual(selectedDay) {
            return .white
        } else {
            return getTitleDayColor(date)
        }
    }
}

@available(iOS 18.0, *)
private struct WeekPreviewView: View, ScrollableWeekProtocol {
    var scrollId: Int?
    var type: CalendarType
    @State var date: Date
    var style: Style
    var weeks: [WeekItem] = []
    
    init(type: CalendarType) {
        _date = State(initialValue: Date.now)
        style = Style()
        style.startWeekDay = .sunday
        self.type = type
        let data = CalendarData(date: .now, years: 1, style: style)
        weeks = reloadData(data,
                           type: type,
                           startDay: data.style.startWeekDay,
                           maxDays: data.style.week.maxDays).weeks
    }
    
    var body: some View {
        VStack {
            ScrollableWeekNewView(
                date: $date,
                weeks: weeks,
                type: type,
                style: style
            )
            Divider()
            if Platform.currentInterface == .phone {
                Button("Today") {
                    date = .now
                }
                .padding()
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview("Week") {
    WeekPreviewView(type: .week)
}

@available(iOS 18.0, *)
#Preview("Day") {
    WeekPreviewView(type: .day)
}

@available(iOS 18.0, *)
struct WeeksHorizontalView<Cell: View>: UIViewRepresentable {
    
    typealias UIViewType = UICollectionView
    
    private let weeks: [WeekItem]
    private let style: Style
    @Binding private var date: Date
    private var cellContent: (KVKCalendar.Day) -> Cell
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    let collectionView: UICollectionView
    
    init(
        weeks: [WeekItem],
        style: Style,
        date: Binding<Date>,
        @ViewBuilder cell: @escaping (KVKCalendar.Day) -> Cell
    ) {
        self.weeks = weeks
        self.style = style
        _date = date
        self.cellContent = cell
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: layout)
    }
    
    func makeUIView(
        context: UIViewRepresentableContext<WeeksHorizontalView>
    ) -> UICollectionView {
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = style.headerScroll.isScrollEnabled
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        return collectionView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(
        _ uiView: UICollectionView,
        context: UIViewRepresentableContext<WeeksHorizontalView>
    ) {
        context.coordinator.selectedDate = date
        uiView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.scrollToDate(animated: true)
        }
    }
    
    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        var selectedDate: Date
        private var parent: WeeksHorizontalView
        private var lastContentOffset: CGFloat = 0
        private var trackingTranslation: CGFloat?
        
        private var maxDays: Int {
            parent.style.week.maxDays
        }
        
        private var isFullyWeek: Bool {
            maxDays == 7
        }
        
        init(_ parent: WeeksHorizontalView) {
            self.parent = parent
            self.selectedDate = parent.date
        }
        
        func scrollToDate(animated: Bool, isDelay: Bool = true) {
            Task {
                guard let scrollDate = getScrollDate(selectedDate),
                      let idx = await getIdxByDate(scrollDate) else { return }
                
                if isDelay {
                    try await Task.sleep(seconds: 0.1)
                    await MainActor.run {
                        parent.collectionView.scrollToItem(
                            at: IndexPath(row: 0, section: idx),
                            at: .left,
                            animated: animated
                        )
                    }
                } else {
                    await MainActor.run {
                        parent.collectionView.scrollToItem(
                            at: IndexPath(row: 0, section: idx),
                            at: .left,
                            animated: animated
                        )
                    }
                }
                try await Task.sleep(seconds: 0.5)
                await MainActor.run {
                    lastContentOffset = parent.collectionView.contentOffset.x
                }
            }
        }
        
        private func getIdxByDate(_ date: Date) async -> Int? {
            parent.weeks.firstIndex(where: { week in
                week.days.firstIndex(where: { $0.date?.kvkIsEqual(date) ?? false }) != nil
            })
        }
        
        private func getScrollDate(_ date: Date) -> Date? {
            guard isFullyWeek else {
                return date
            }
            return parent.style.startWeekDay == .sunday ? date.kvkStartSundayOfWeek : date.kvkStartMondayOfWeek
        }
        
        private func calculateDateWithOffset(_ offset: Int) -> Date {
            parent.style.calendar.date(
                byAdding: .day,
                value: offset,
                to: parent.date
            ) ?? parent.date
        }
        
        // MARK: UICollectionViewDataSource
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            parent.weeks.count
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            parent.weeks[section].days.count
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let day = parent.weeks[indexPath.section].days[indexPath.row]
            return collectionView.kvkDequeueCell(
                id: "day.collection.cell",
                indexPath: indexPath
            ) { (cell: UICollectionViewCell) in
                cell.translatesAutoresizingMaskIntoConstraints = false
                cell.contentConfiguration = UIHostingConfiguration { parent.cellContent(day) }
            }
        }
        
        // MARK: UICollectionViewDelegateFlowLayout
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let dateNew = parent.weeks[indexPath.section].days[indexPath.row].date else { return }
            parent.date = dateNew
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            layout collectionViewLayout: UICollectionViewLayout,
            sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
            let width = collectionView.bounds.width / CGFloat(maxDays)
            return CGSize(width: width, height: collectionView.bounds.height)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let translation = scrollView.panGestureRecognizer.translation(in: parent.collectionView)
            
            if trackingTranslation != translation.x {
                trackingTranslation = translation.x
                if parent.style.headerScroll.shouldTimelineTrackScroll {
                    print(translation)
                }
            }
        }
        
        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            let translation = scrollView.panGestureRecognizer.translation(in: parent.collectionView)
            trackingTranslation = translation.x
            
            let targetOffset = targetContentOffset.pointee
            if targetOffset.x == lastContentOffset {
                if parent.style.headerScroll.shouldTimelineTrackScroll {
                    print(translation)
                }
            } else if targetOffset.x < lastContentOffset {
                parent.date = calculateDateWithOffset(-maxDays)
                
            } else if targetOffset.x > lastContentOffset {
                parent.date = calculateDateWithOffset(maxDays)
            }
            lastContentOffset = targetOffset.x
        }
    }
}

final class ScrollableWeekView: UIView {
    
    var didTrackScrollOffset: ((CGFloat?, Bool) -> Void)?
    var didSelectDate: ((Date?, CalendarType) -> Void)?
    var didChangeDay: ((TimelinePageView.SwitchPageType) -> Void)?
    var didUpdateStyle: ((CalendarType) -> Void)?
    
    struct Parameters {
        let frame: CGRect
        var weeks: [WeekItem]
        var date: Date
        let type: CalendarType
        var style: Style
    }
    
    private var params: Parameters
    private var collectionView: UICollectionView!
    private var isAnimate = false
    private var lastContentOffset: CGFloat = 0
    private var trackingTranslation: CGFloat?
    
    private var weeks: [WeekItem] {
        params.weeks
    }
    private var formattedDays: [Day] {
        params.weeks.flatMap { $0.days }
    }
    private var calendar: Calendar {
        params.style.calendar
    }
    private var type: CalendarType {
        params.type
    }
    
    var date: Date {
        get {
            params.date
        }
        set {
            params.date = newValue
            titleView?.date = newValue
        }
    }
    
    private var maxDays: Int {
        switch type {
        case .week:
            return style.week.maxDays
        default:
            return 7
        }
    }
    
    private var isFullyWeek: Bool {
        switch type {
        case .week:
            return maxDays == 7
        default:
            return true
        }
    }
    
    weak var dataSource: DisplayDataSource?
    
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        return layout
    }()
    private let customCornerHeaderViewTag = -1001
    private var titleView: ScrollableWeekHeaderTitleView?
    private let bottomLineView = UIView()
    private let cornerBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.setTitleColor(.lightGray, for: .selected)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        return btn
    }()
    
    init(parameters: Parameters) {
        self.params = parameters
        super.init(frame: parameters.frame)
        setUI()
    }
    
    func updateWeeks(weeks: [WeekItem]) {
        params.weeks = weeks
    }
    
    func getIdxByDate(_ date: Date) -> Int? {
        weeks.firstIndex(where: { week in
            week.days.firstIndex(where: { $0.date?.kvkIsEqual(date) ?? false }) != nil
        })
    }
    
    func getDatesByDate(_ date: Date) -> [Day] {
        guard let idx = getIdxByDate(date) else { return [] }
        
        return weeks[idx].days
    }
    
    func scrollHeaderByTransform(_ transform: CGAffineTransform) {
        guard !transform.isIdentity else {
            guard let scrollDate = getScrollDate(date), let idx = getIdxByDate(scrollDate) else { return }
            
            collectionView.scrollToItem(at: IndexPath(row: 0, section: idx),
                                        at: .left,
                                        animated: true)
            return
        }
        
        collectionView.contentOffset.x = lastContentOffset - transform.tx
    }
    
    func setDate(_ date: Date, isDelay: Bool = true) {
        self.date = date
        scrollToDate(date, animated: isAnimate, isDelay: isDelay)
        collectionView.reloadData()
    }
    
    @discardableResult
    func calculateDateWithOffset(_ offset: Int, needScrollToDate: Bool) -> Date {
        guard let nextDate = calendar.date(byAdding: .day, value: offset, to: date) else { return date }
        
        date = nextDate
        if needScrollToDate {
            scrollToDate(date, animated: true, isDelay: false)
        }
        
        collectionView.reloadData()
        return nextDate
    }
    
    func getDateByPointX(_ pointX: CGFloat) -> Date? {
        let startRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let indexPath = collectionView.indexPathForItem(at: CGPoint(x: startRect.origin.x + pointX, y: startRect.midY)) else { return nil }
        
        let day = weeks[indexPath.section].days[indexPath.row]
        return day.date
    }
    
    private func createCollectionView(frame: CGRect, isScrollEnabled: Bool) -> UICollectionView {
        let collection = UICollectionView(frame: frame, collectionViewLayout: layout)
        collection.isPagingEnabled = true
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = isScrollEnabled
        return collection
    }
    
    private func scrollToDate(_ date: Date, animated: Bool, isDelay: Bool = true) {
        guard let scrollDate = getScrollDate(date), let idx = getIdxByDate(scrollDate) else { return }
        
        if isDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.collectionView.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                 at: .left,
                                                 animated: animated)
            }
        } else {
            collectionView.scrollToItem(at: IndexPath(row: 0, section: idx), at: .left, animated: animated)
        }
        
        if !self.isAnimate {
            self.isAnimate = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScrollableWeekView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            params.style
        }
        set {
            params.style = newValue
        }
    }
    
    func setUI(reload: Bool = false) {
        bottomLineView.backgroundColor = params.style.headerScroll.bottomLineColor
        
        subviews.forEach { $0.removeFromSuperview() }
        var newFrame = frame
        newFrame.origin.y = 0
        setupViews(mainFrame: &newFrame)
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame.size.width = frame.width - self.frame.origin.x
        layoutIfNeeded()
        
        var newFrame = self.frame
        newFrame.origin.y = 0
        
        collectionView.removeFromSuperview()
        setupViews(mainFrame: &newFrame)
        
        guard let scrollDate = getScrollDate(date), let idx = getIdxByDate(scrollDate) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: idx), at: .left, animated: false)
            self.lastContentOffset = self.collectionView.contentOffset.x
        }
        collectionView.reloadData()
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
        scrollToDate(date, animated: true)
    }
    
    func reloadCustomCornerHeaderViewIfNeeded() {
        if let cornerHeader = dataSource?.dequeueCornerHeader(
            date: date,
            frame: CGRect(x: 0, y: 0,
                          width: leftOffsetWithAdditionalTime,
                          height: bounds.height),
            type: type
        ) {
            cornerHeader.tag = customCornerHeaderViewTag
            for subview in subviews where subview.tag == customCornerHeaderViewTag {
                subview.removeFromSuperview()
            }
            addSubview(cornerHeader)
        }
    }
    
    private func setupViews(mainFrame: inout CGRect) {
        if let customView = dataSource?.willDisplayHeaderView(date: date, frame: mainFrame, type: type) {
            params.weeks = []
            collectionView.reloadData()
            addSubview(customView)
        } else {
            if let cornerHeader = dataSource?.dequeueCornerHeader(
                date: date,
                frame: CGRect(x: 0, y: 0,
                              width: leftOffsetWithAdditionalTime,
                              height: bounds.height),
                type: type
            ) {
                cornerHeader.tag = customCornerHeaderViewTag
                addSubview(cornerHeader)
                mainFrame.origin.x = cornerHeader.frame.width
                mainFrame.size.width -= cornerHeader.frame.width
            } else if style.timeline.useDefaultCorderHeader {
                cornerBtn.frame = CGRect(x: 0, y: 0,
                                         width: leftOffsetWithAdditionalTime,
                                         height: bounds.height)
                cornerBtn.setTitle(style.timezone.abbreviation(), for: .normal)
                cornerBtn.titleLabel?.adjustsFontSizeToFitWidth = true
                addSubview(cornerBtn)
                
                if #available(iOS 14.0, *) {
                    cornerBtn.showsMenuAsPrimaryAction = true
                    cornerBtn.menu = createTimeZonesMenu()
                    
                    if style.selectedTimeZones.count > 1 {
                        cornerBtn.frame.size.height -= 35
                        
                        let actions: [UIAction] = style.selectedTimeZones.compactMap { (item) in
                            UIAction(title: item.abbreviation() ?? "-") { [weak self] (_) in
                                self?.style.timezone = item
                                self?.didUpdateStyle?(self?.type ?? .day)
                            }
                        }
                        let sgObject = UISegmentedControl(frame: CGRect(x: 2,
                                                                        y: cornerBtn.frame.height + 5,
                                                                        width: cornerBtn.frame.width - 4,
                                                                        height: 25),
                                                          actions: actions)
                        sgObject.selectedSegmentIndex = style.selectedTimeZones.firstIndex(where: { $0.identifier == style.timezone.identifier }) ?? 0
                        let sizeFont: CGFloat
                        if Platform.currentInterface == .phone {
                            sizeFont = 8
                        } else {
                            sizeFont = 10
                        }
                        let defaultAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: sizeFont)]
                        sgObject.setTitleTextAttributes(defaultAttributes, for: .normal)
                        addSubview(sgObject)
                    }
                } else {
                    // Fallback on earlier versions
                }
                
                mainFrame.origin.x = cornerBtn.frame.width
                mainFrame.size.width -= cornerBtn.frame.width
            } else {
                if type == .week {
                    let spacerView = UIView()
                    spacerView.frame = CGRect(x: 0, y: 0,
                                              width: leftOffsetWithAdditionalTime,
                                              height: bounds.height)
                    spacerView.backgroundColor = .clear
                    addSubview(spacerView)
                    mainFrame.origin.x = spacerView.frame.width
                    mainFrame.size.width -= spacerView.frame.width
                }
            }
            
            if Platform.currentInterface != .phone {
                titleView?.frame.origin.x = 10
            }
            
            calculateFrameForCollectionViewIfNeeded(&mainFrame)
            collectionView = createCollectionView(frame: mainFrame,
                                                  isScrollEnabled: style.headerScroll.isScrollEnabled)
            addSubview(collectionView)
            addTitleHeaderIfNeeded(frame: collectionView.frame)
        }
        
        addSubview(bottomLineView)
        bottomLineView.translatesAutoresizingMaskIntoConstraints = false
        
        let left = bottomLineView.leftAnchor.constraint(equalTo: leftAnchor)
        let right = bottomLineView.rightAnchor.constraint(equalTo: rightAnchor)
        let bottom = bottomLineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let height = bottomLineView.heightAnchor.constraint(equalToConstant: 0.5)
        NSLayoutConstraint.activate([left, right, bottom, height])
    }
    
    private func addTitleHeaderIfNeeded(frame: CGRect) {
        titleView?.removeFromSuperview()
        guard !style.headerScroll.isHiddenSubview else { return }
        
        let titleFrame: CGRect
        switch Platform.currentInterface {
        case .phone:
            titleFrame = CGRect(origin: CGPoint(x: frame.origin.x, y: frame.height),
                                size: CGSize(width: frame.width - 10, height: style.headerScroll.heightSubviewHeader))
        default:
            titleFrame = CGRect(origin: CGPoint(x: frame.origin.x + 10, y: 0),
                                size: CGSize(width: frame.width - 10, height: style.headerScroll.heightSubviewHeader))
        }
        
        titleView = ScrollableWeekHeaderTitleView(frame: titleFrame)
        titleView?.style = style
        titleView?.date = date
        if let view = titleView {
            addSubview(view)
        }
    }
    
    private func calculateFrameForCollectionViewIfNeeded(_ frame: inout CGRect) {
        guard !style.headerScroll.isHiddenSubview else { return }
        
        frame.size.height = style.headerScroll.heightHeaderWeek
        if Platform.currentInterface != .phone {
            frame.origin.y = style.headerScroll.heightSubviewHeader
        }
    }
    
    private func getScrollDate(_ date: Date) -> Date? {
        guard isFullyWeek else {
            return date
        }
        
        return style.startWeekDay == .sunday ? date.kvkStartSundayOfWeek : date.kvkStartMondayOfWeek
    }
}

extension ScrollableWeekView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        weeks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        weeks[section].days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let day = weeks[indexPath.section].days[indexPath.row]
        
        if let cell = dataSource?.dequeueCell(parameter: .init(date: day.date, type: day.type, events: day.events), type: type, view: collectionView, indexPath: indexPath) as? UICollectionViewCell {
            return cell
        } else {
            switch Platform.currentInterface {
            case .phone:
                return collectionView.kvkDequeueCell(indexPath: indexPath) { (cell: DayPhoneCell) in
                    cell.phoneStyle = style
                    cell.day = day
                    cell.selectDate = date
                }
            default:
                return collectionView.kvkDequeueCell(indexPath: indexPath) { (cell: DayPadCell) in
                    cell.padStyle = style
                    cell.day = day
                    cell.selectDate = date
                }
            }
        }
    }
    
}

extension ScrollableWeekView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        
        if trackingTranslation != translation.x {
            trackingTranslation = translation.x
            if style.headerScroll.shouldTimelineTrackScroll {
                didTrackScrollOffset?(translation.x, false)
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let translation = scrollView.panGestureRecognizer.translation(in: collectionView)
        trackingTranslation = translation.x
        
        let targetOffset = targetContentOffset.pointee
        
        if targetOffset.x == lastContentOffset {
            if style.headerScroll.shouldTimelineTrackScroll {
                didTrackScrollOffset?(translation.x, true)
            }
        } else if targetOffset.x < lastContentOffset {
            didChangeDay?(.previous)
            calculateDateWithOffset(-maxDays, needScrollToDate: false)
            didSelectDate?(date, type)
        } else if targetOffset.x > lastContentOffset {
            didChangeDay?(.next)
            calculateDateWithOffset(maxDays, needScrollToDate: false)
            didSelectDate?(date, type)
        }
        
        lastContentOffset = targetOffset.x
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        lastContentOffset = scrollView.contentOffset.x
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dateNew = weeks[indexPath.section].days[indexPath.row].date else { return }
        
        switch type {
        case .day:
            guard date != dateNew else { return }
            date = dateNew
        case .week:
            date = dateNew
        default:
            break
        }
        
        didSelectDate?(date, type)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / CGFloat(maxDays)
        return CGSize(width: width, height: collectionView.bounds.height)
    }
}

extension ScrollableWeekView {
    
    private func createTimeZonesMenu() -> UIMenu {
        let actions = style.timeZoneIds.compactMap { (item) in
            let alreadySelected = style.selectedTimeZones.contains(where: { $0.identifier == item })
            
            return UIAction(title: item, state: alreadySelected ? .on : .off) { [weak self] (_) in
                guard let timeZone = TimeZone(identifier: item) else { return }
                
                if alreadySelected {
                    self?.style.selectedTimeZones.removeAll(where: { $0.identifier == item })
                    if self?.style.timezone.identifier == item {
                        self?.style.timezone = self?.style.selectedTimeZones.last ?? TimeZone.current
                    }
                } else {
                    self?.style.timezone = timeZone
                    self?.style.selectedTimeZones.append(timeZone)
                    if (self?.style.selectedTimeZones.count ?? 0) > 3 {
                        self?.style.selectedTimeZones.removeFirst()
                    }
                }
                self?.didUpdateStyle?(self?.type ?? .day)
            }
        }
        return UIMenu(title: "List of Time zones", children: actions)
    }
    
}

#endif
