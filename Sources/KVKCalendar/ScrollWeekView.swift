//
//  ScrollWeekView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 6/4/25.
//

import SwiftUI
import EventKit

@available(iOS 16.0, *)

public struct ScrollWeekWrapper<Cell: View>: UIViewControllerRepresentable {
    @Binding private var date: Date
    @Binding private var style: Style
    @ViewBuilder private var content: (_ date: Date?, _ type: DayType?) -> Cell
    private let view: ScrollWeekView

    public init(
        date: Binding<Date>,
        style: Binding<Style>,
        @ViewBuilder cellContent: @escaping (
            _ date: Date?,
            _ type: DayType?
        ) -> Cell = { _, _ in EmptyView() }
    ) {
        _date = date
        _style = style
        self.content = cellContent
        view = ScrollWeekView(
            date: date.wrappedValue,
            style: style.wrappedValue
        )
    }
    
    public func makeUIViewController(context: Context) -> some UIViewController {
        view.delegate = context.coordinator
        view.dataSource = context.coordinator
        return view
    }
    
    public func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        view.setDate(date)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    @available(iOS 16.0, *)
    public class Coordinator: NSObject, CalendarDelegate, CalendarDataSource {
        private let parent: ScrollWeekWrapper
        
        init(parent: ScrollWeekWrapper) {
            self.parent = parent
            super.init()
        }
        
        public func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
            []
        }
        
        public func didSelectDates(
            _ dates: [Date],
            type: CalendarType,
            frame: CGRect?
        ) {
            parent.date = dates.first ?? Date()
        }
        
        public func didUpdateStyle(
            _ style: Style,
            type: CalendarType
        ) {
            parent.style = style
        }
        
        public func dequeueCell<T>(
            parameter: CellParameter,
            type: CalendarType,
            view: T,
            indexPath: IndexPath
        ) -> (any KVKCalendarCellProtocol)? where T: UIScrollView {
            if parent.content(parameter.date, parameter.type) is EmptyView {
                nil
            } else {
                (view as? UICollectionView)?.kvkDequeueCell(
                    indexPath: indexPath) { (cell: UICollectionViewCell) in
                        cell.contentConfiguration = UIHostingConfiguration {
                            parent.content(parameter.date, parameter.type)
                        }
                    }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var date = Date()
    ScrollWeekWrapper(date: $date, style: .constant(Style()))
}

open class ScrollWeekView: UIViewController {
    private var style: Style
    private var dayData: DayData
    private var scrollView: ScrollableWeekView
    
    public weak var delegate: CalendarDelegate?
    public weak var dataSource: CalendarDataSource?
    
    public init(date: Date, style: Style) {
        var styleProxy = style
        styleProxy.timeline.widthTime = 0
        styleProxy.timeline.offsetTimeX = 0
        styleProxy.timeline.offsetLineLeft = 0
        let data = CalendarData(date: date, years: 1, style: styleProxy)
        self.style = styleProxy
        dayData = DayData(data: data, startDay: styleProxy.startWeekDay)
        scrollView = ScrollableWeekView(
            parameters: .init(
                weeks: dayData.daysBySection,
                date: dayData.date,
                type: .week,
                style: styleProxy
            )
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let top = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        let leading = scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bottom = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
        setupScrollableWeekView()
        scrollView.setDate(dayData.date)
    }
    
    open override func viewDidLayoutSubviews() {
        scrollView.setUI(reload: true)
    }
    
    public func setDate(_ date: Date) {
        guard !dayData.date.kvkIsEqual(date) else { return }
        dayData.date = date
        scrollView.setDate(dayData.date)
    }
    
    // MARK: - Private
    private func setupScrollableWeekView() {
        scrollView.dataSource = self
        scrollView.didSelectDate = { [weak self] (date, type) in
            guard let self else { return }
            if let date {
                dayData.date = date
                delegate?.didSelectDates([date], type: type, frame: nil)
            }
        }
        scrollView.didUpdateStyle = { [weak self] (type) in
            guard let self else { return }
            delegate?.didUpdateStyle(style, type: type)
        }
    }
}

extension ScrollWeekView: DisplayDataSource {
    public func dequeueCell<T>(
        parameter: CellParameter,
        type: CalendarType,
        view: T,
        indexPath: IndexPath
    ) -> (any KVKCalendarCellProtocol)? where T: UIScrollView {
        dataSource?.dequeueCell(
            parameter: parameter,
            type: type,
            view: view,
            indexPath: indexPath
        )
    }
}
