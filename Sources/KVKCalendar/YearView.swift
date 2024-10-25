//
//  YearView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 02/01/2019.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
struct YearNewView: View {
    @State private var vm: YearNewData
    
    private var style: Style {
        vm.style
    }
    
    init(monthData: MonthNewData) {
        _vm = State(initialValue: YearNewData(monthData: monthData))
    }
    
    var body: some View {
        bodyView
            .task {
                await vm.getScrollId()
            }
    }
    
    private var bodyView: some View {
        ScrollViewReader { (proxy) in
            ScrollView {
                LazyVStack {
                    let date = Binding(
                        get: { vm.date },
                        set: { vm.handleSelectedDate($0) })
                    ContentGrid(years: vm.sections, style: style, date: date)
                        .padding(.horizontal)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $vm.scrollId, anchor: .top)
        }
    }
    
}

@available(iOS 17.0, *)
private struct ContentGrid: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let years: [KVKCalendar.YearSection]
    let style: KVKCalendar.Style
    @Binding var date: Date
    
    private var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    init(years: [KVKCalendar.YearSection], style: KVKCalendar.Style, date: Binding<Date>) {
        self.years = years
        self.style = style
        _date = date
        if Platform.currentInterface != .phone {
            columns.append(GridItem(.flexible(), spacing: 10))
        }
    }
    
    var body: some View {
        bodyView
    }
    
    private var bodyView: some View {
        LazyVGrid(columns: columns) {
            ForEach(years.indices, id: \.self) { (idx) in
                let year = years[idx]
                Section {
                    ForEach(year.months) { (month) in
                        YearMonthView(month: month, style: style, selectedDate: $date)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(year.date.titleForLocale(style.locale, formatter: style.year.titleFormatter))
                                .foregroundStyle(getYearTxtColor(year.date))
                                .font(Font(style.year.fontTitleHeader))
                                .bold()
                            Spacer()
                        }
                        Divider()
                    }
                    .padding(.vertical)
                }
                .id(idx)
            }
        }
    }
    
    private func getYearTxtColor(_ date: Date) -> Color {
        switch date.kvkYear {
        case Date().kvkYear:
            .red
        default:
            colorScheme == .dark ? .white :  style.year.colorTitleHeader.suiColor
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    let style = Style()
    let monthData = MonthNewData(data: .init(date: .now, years: 4, style: style))
    return YearNewView(monthData: monthData)
}

@available(iOS 17.0, *)
private struct YearMonthView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var month: Month
    var style: Style
    @Binding var selectedDate: Date
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    private var daySize: CGSize {
        Platform.currentInterface == .phone ? CGSize(width: 15, height: 15) : CGSize(width: 30, height: 30)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(month.yearName)
                    .font(Font(style.year.fontTitle))
                    .foregroundStyle(getMonthTxtColor(month.date))
                    .bold()
                Spacer()
            }
            if Platform.currentInterface != .phone {
                WeekTitlesView(style: style)
            }
            LazyVGrid(columns: columns) {
                ForEach(month.days) { (day) in
                    if let date = day.date {
                        if day.type != .empty && (date.kvkIsEqual(.now) || date.kvkIsEqual(selectedDate)) {
                            getDayView(day, date: date)
                                .background(getBgDayTxtColor(date))
                                .clipShape(.circle)
                                .minimumScaleFactor(0.8)
                        } else {
                            getDayView(day, date: date)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            Spacer()
        }
        .onTapGesture {
            selectedDate = month.date
        }
    }
    
    @ViewBuilder
    private func getDayView(_ day: Day, date: Date) -> some View {
        Group {
            if Platform.currentInterface == .phone {
                Text(day.type == .empty ? "" : "\(date.kvkDay)")
                    .font(.caption2)
                    .frame(width: 15, height: 15)
            } else {
                Text(day.type == .empty ? "" : "\(date.kvkDay)")
                    .font(.subheadline)
                    .padding(3)
            }
        }
        .foregroundStyle(getDayTxtColor(date))
    }
    
    private func getMonthTxtColor(_ day: Date) -> Color {
        if day.kvkMonthIsEqual(.now) {
            return .red
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private func getDayTxtColor(_ day: Date) -> Color {
        if day.kvkIsEqual(.now) && day.kvkIsEqual(selectedDate) {
            return .white
        } else if day.kvkIsEqual(selectedDate) {
            return colorScheme == .dark ? .black : .white
        } else if day.isWeekend {
            return .gray
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private func getBgDayTxtColor(_ day: Date) -> Color {
        if day.kvkIsEqual(.now) && day.kvkIsEqual(selectedDate) {
            return .red
        } else if day.kvkIsEqual(selectedDate) {
            return colorScheme == .dark ? .white : .black
        } else {
            return .clear
        }
    }
    
}

@available(iOS 17.0, *)
struct WeekTitlesView: View, WeekPreparing {
    
    @Environment(\.colorScheme) private var colorScheme
    private var days: [Date] = []
    private let style: Style
    private let formatter: DateFormatter
    private let font: UIFont
    
    init(style: Style, formatter: DateFormatter? = nil, font: UIFont? = nil) {
        self.style = style
        self.formatter = formatter ?? style.year.weekdayFormatter
        self.font = font ?? style.year.weekFont
        days = getWeekDays(style: style)
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(days, id: \.self) { (day) in
                Text(day.titleForLocale(style.locale, formatter: formatter))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(getTxtColor(day, style: style))
                    .font(Font(font))
                    .background(getTxtBgColor(day, style: style))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func getTxtColor(_ day: Date, style: Style) -> Color {
        if day.isWeekend {
            return colorScheme == .dark ? .gray : Color(uiColor: style.week.colorWeekendDate)
        } else if day.isWeekday {
            return colorScheme == .dark ? .white : Color(uiColor: style.week.colorDate)
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
#Preview("Week Title View") {
    WeekTitlesView(style: Style())
}

final class YearView: UIView {
    private var data: YearData
    private var collectionView: UICollectionView?
    
    weak var delegate: DisplayDelegate?
    weak var dataSource: DisplayDataSource?
    
    private var layout = UICollectionViewFlowLayout()
    
    private func scrollDirection(month: Int) -> UICollectionView.ScrollPosition {
        switch month {
        case 1...4:
            return .top
        case 5...8:
            return .centeredVertically
        default:
            return .bottom
        }
    }
    
    init(data: YearData, frame: CGRect? = nil) {
        self.data = data
        super.init(frame: frame ?? .zero)
    }
    
    func setDate(_ date: Date, animated: Bool) {
        data.date = date
        scrollToDate(date: date, animated: animated)
        collectionView?.reloadData()
    }
    
    private func createCollectionView(frame: CGRect, style: YearStyle) -> (view: UICollectionView, customView: Bool) {
        if let customCollectionView = dataSource?.willDisplayCollectionView(frame: frame, type: .year) {
            if customCollectionView.delegate == nil {
                customCollectionView.delegate = self
            }
            if customCollectionView.dataSource == nil {
                customCollectionView.dataSource = self
            }
            return (customCollectionView, true)
        }
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = style.colorBackground
        collection.isPagingEnabled = style.isPagingEnabled
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return (collection, false)
    }
    
    private func scrollToDate(date: Date, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.kvkYear == date.kvkYear }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: date.kvkMonth),
                                                  animated: animated)
            }
        }
    }
    
    private func getIndexForDirection(_ direction: UICollectionView.ScrollDirection, indexPath: IndexPath) -> IndexPath {
        switch direction {
        case .horizontal:
            let a = indexPath.item / data.itemsInPage
            let b = indexPath.item / data.rowsInPage - a * data.columnsInPage
            let c = indexPath.item % data.rowsInPage
            let newIdx = (c * data.columnsInPage + b) + a * data.itemsInPage
            return IndexPath(row: newIdx, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension YearView: CalendarSettingProtocol {
    
    var style: Style {
        get {
            data.style
        }
        set {
            data.style = newValue
        }
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let idx = self.data.sections.firstIndex(where: { $0.date.kvkYear == self.data.date.kvkYear }) {
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: idx),
                                                  at: self.scrollDirection(month: self.data.date.kvkMonth),
                                                  animated: false)
            }
        }
        
        collectionView?.reloadData()
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
    }
    
    func setUI(reload: Bool = false) {
        backgroundColor = data.style.year.colorBackground
        subviews.forEach { $0.removeFromSuperview() }
        layout.scrollDirection = data.style.year.scrollDirection
        
        switch data.style.year.scrollDirection {
        case .horizontal:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
        case .vertical:
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 5
        @unknown default:
            fatalError()
        }
        
        collectionView = nil
        let result = createCollectionView(frame: frame, style: data.style.year)
        collectionView = result.view
        
        if let viewTemp = collectionView {
            addSubview(viewTemp)
            
            if !result.customView {
                viewTemp.translatesAutoresizingMaskIntoConstraints = false
                let top = viewTemp.topAnchor.constraint(equalTo: topAnchor)
                let bottom = viewTemp.bottomAnchor.constraint(equalTo: bottomAnchor)
                let left = viewTemp.leftAnchor.constraint(equalTo: leftAnchor)
                let right = viewTemp.rightAnchor.constraint(equalTo: rightAnchor)
                NSLayoutConstraint.activate([top, bottom, left, right])
            }
        }
    }
}

extension YearView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        data.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.sections[section].months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let month = data.sections[index.section].months[index.row]
        
        if let cell = dataSource?.dequeueCell(parameter: .init(date: month.date, type: nil), type: .year, view: collectionView, indexPath: index) as? UICollectionViewCell {
            return cell
        } else {
            return collectionView.kvkDequeueCell(indexPath: index) { (cell: YearCell) in
                cell.style = data.style
                cell.selectDate = data.date
                cell.title = month.name
                cell.date = month.date
                cell.days = month.days
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let date = data.sections[index.section].date
        
        if let headerView = dataSource?.dequeueHeader(date: date, type: .year, view: collectionView, indexPath: index) as? UICollectionReusableView {
            return headerView
        } else {
            return collectionView.kvkDequeueView(indexPath: index) { (headerView: YearHeaderView) in
                headerView.style = data.style
                headerView.date = date
                delegate?.didDisplayHeaderTitle(date, style: style, type: .year)
            }
        }
    }
}

extension YearView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard data.style.year.autoSelectionDateWhenScrolling else { return }
        
        let cells = collectionView?.indexPathsForVisibleItems ?? []
        let dates = cells.compactMap { data.sections[$0.section].months[$0.row].date }
        delegate?.didDisplayEvents([], dates: dates, type: .year)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        let date = data.sections[index.section].months[index.row].date
        let formatter = DateFormatter()
        formatter.locale = style.locale
        formatter.dateFormat = "dd.MM.yyyy"
        let newDate = formatter.date(from: "\(data.date.kvkDay).\(date.kvkMonth).\(date.kvkYear)")
        data.date = newDate ?? Date()
        collectionView.reloadData()
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let frame = collectionView.convert(attributes?.frame ?? .zero, to: collectionView)
        
        delegate?.didSelectDates([newDate].compactMap({ $0 }), type: data.style.year.selectCalendarType, frame: frame)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: indexPath)
        if let size = delegate?.sizeForCell(data.sections[index.section].months[index.row].date, type: .year) {
            return size
        }
        
        var width: CGFloat
        var height = collectionView.frame.height
        
        if height > 0 && height >= data.style.year.heightTitleHeader {
            height -= data.style.year.heightTitleHeader
        }
        
        if Platform.currentInterface != .phone {
            width = collectionView.frame.width / 4
            height /= 3
        } else {
            width = collectionView.frame.width / 3
            height /= 4
        }
        
        if width > 0 {
            width -= layout.minimumInteritemSpacing
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let index = getIndexForDirection(data.style.year.scrollDirection, indexPath: IndexPath(row: 0, section: section))
        let date = data.sections[index.section].date
        
        if let size = delegate?.sizeForHeader(date, type: .year) {
            return size
        } else {
            switch data.style.year.scrollDirection {
            case .horizontal:
                return .zero
            case .vertical:
                return CGSize(width: collectionView.bounds.width, height: data.style.year.heightTitleHeader)
            @unknown default:
                fatalError()
            }
        }
    }
}

#endif
