//
//  ListView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 26.12.2020.
//

#if os(iOS)

import SwiftUI

@available(iOS 17.0, *)
public struct ListNewView: View {
    
    private let params: ListView.Parameters
    @Binding private var date: Date
    @Binding private var event: Event?
    
    private var style: Style {
        params.data.style
    }
    @StateObject private var vm: ListViewData
    
    public init(params: ListView.Parameters,
                date: Binding<Date>,
                event: Binding<Event?>,
                events: Binding<[Event]>) {
        self.params = params
        _vm = StateObject(wrappedValue: params.data)
        _date = date
        _event = event
        if params.data.sections.isEmpty {
            vm.reloadEvents(events.wrappedValue)
        }
    }
    
    public var body: some View {
        NavigationStack {
            listBody
        }
    }
    
    private var listBody: some View {
        List(vm.sections) { (section) in
            Section {
                ForEach(section.events) { (event) in
                    Button {
                        self.event = event
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(uiColor: event.backgroundColor))
                                .frame(width: 30, height: 30)
                            Text(event.title.list ?? "")
                                .padding([.top, .bottom, .trailing], 10)
                            Spacer()
                        }
                    }
                }
            } header: {
                Button {
                    date = section.date
                } label: {
                    Text(vm.titleOfHeader(date: section.date, formatter: style.list.headerDateFormatter, locale: style.locale))
                }
                .foregroundColor(.black)
                .padding(5)
            }
        }
        .listStyle(.plain)
    }
    
}

@available(iOS 17.0, *)
#Preview {
    let style = Style()
    return ListNewView(params: ListView.Parameters(data: ListViewData(data: CalendarData(date: Date(), years: 4, style: style))), date: .constant(Date()), event: .constant(nil), events: .constant([.stub(id: "1"), .stub(id: "2"), .stub(id: "3")]))
}

@available(iOS 17.0, *)
#Preview {
    let style = Style()
    return ListNewView(params: ListView.Parameters(data: ListViewData(date: Date(), sections: [ListViewData.SectionListView(date: Date(), events: [Event.stub()])])), date: .constant(Date()), event: .constant(nil), events: .constant([]))
}

open class ListView: UIView, CalendarSettingProtocol {
    
    public struct Parameters {
        let data: ListViewData
        
        public init(data: ListViewData) {
            self.data = data
        }
    }
    
    public weak var dataSource: CalendarDataSource?
    public weak var delegate: CalendarDelegate?
    
    var style: Style {
        get {
            params.data.style
        }
        set {
            params.data.style = newValue
        }
    }
    
    private var params: Parameters
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView()
        table.dataSource = self
        table.delegate = self
        if #available(iOS 15.0, *) {
            table.sectionHeaderTopPadding = 0
        }
        return table
    }()
    
    private var listStyle: ListViewStyle {
        style.list
    }
    
    public init(parameters: Parameters, frame: CGRect? = nil) {
        self.params = parameters
        super.init(frame: frame ?? .zero)
        addSubview(tableView)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        let top = tableView.topAnchor.constraint(equalTo: topAnchor)
        let bottom = tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let left = tableView.leftAnchor.constraint(equalTo: leftAnchor)
        let right = tableView.rightAnchor.constraint(equalTo: rightAnchor)
        NSLayoutConstraint.activate([top, bottom, left, right])
    }
    
    func updateStyle(_ style: Style, force: Bool) {
        self.style = style
        setUI(reload: force)
    }
    
    func setUI(reload: Bool = false) {
        backgroundColor = listStyle.backgroundColor
        tableView.backgroundColor = listStyle.backgroundColor
    }
    
    func reloadFrame(_ frame: CGRect) {
        self.frame = frame
        layoutIfNeeded()
    }
    
    func reloadData(_ events: [Event]) {
        params.data.reloadEvents(events)
        dataSource?.willDisplaySectionsInListView(params.data.sections)
        tableView.reloadData()
    }
    
    func showSkeletonVisible(_ visible: Bool) {
        params.data.isSkeletonVisible = visible
        tableView.reloadData()
    }
    
    func setDate(_ date: Date, animated: Bool) {
        params.data.date = date
        
        guard !params.data.isSkeletonVisible else { return }
        
        if let idx = params.data.sections.firstIndex(where: { $0.date.kvkIsEqual(date) }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: animated)
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.kvkYear == date.kvkYear && $0.date.kvkMonth == date.kvkMonth }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: animated)
        } else if let idx = params.data.sections.firstIndex(where: { $0.date.kvkYear == date.kvkYear }) {
            tableView.scrollToRow(at: IndexPath(row: 0, section: idx), at: .top, animated: animated)
        }
    }
    
}

extension ListView: UITableViewDataSource, UITableViewDelegate {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        params.data.numberOfSection()
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        params.data.numberOfItemsInSection(section)
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !params.data.isSkeletonVisible else {
            return tableView.kvkDequeueCell { (cell: ListViewCell) in
                cell.setSkeletons(params.data.isSkeletonVisible)
            }
        }
        
        let event = params.data.event(indexPath: indexPath)
        if let cell = dataSource?.dequeueCell(parameter: .init(date: event.start, events: [event]), type: .list, view: tableView, indexPath: indexPath) as? UITableViewCell {
            return cell
        } else {
            return tableView.kvkDequeueCell(indexPath: indexPath) { (cell: ListViewCell) in
                cell.txt = event.title.list
                cell.dotColor = event.color?.value
            }
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !params.data.isSkeletonVisible else {
            return tableView.kvkDequeueView { (view: ListViewHeader) in
                view.setSkeletons(params.data.isSkeletonVisible)
            }
        }
        
        let date = params.data.sections[section].date
        if let headerView = dataSource?.dequeueHeader(date: date, type: .list, view: tableView, indexPath: IndexPath(row: 0, section: section)) as? UIView {
            return headerView
        } else {
            return tableView.kvkDequeueView { (view: ListViewHeader) in
                view.title = params.data.titleOfHeader(section: section,
                                                       formatter: listStyle.headerDateFormatter,
                                                       locale: style.locale)
                view.didTap = { [weak self] in
                    self?.delegate?.didSelectDates([date], type: .list, frame: view.frame)
                }
            }
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !params.data.isSkeletonVisible else {
            return 45
        }
        
        let event = params.data.event(indexPath: indexPath)
        if let height = delegate?.sizeForCell(event.start, type: .list)?.height {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard !params.data.isSkeletonVisible else {
            return 50
        }
        
        let date = params.data.sections[section].date
        if let height = delegate?.sizeForHeader(date, type: .list)?.height {
            return height
        } else if let height = listStyle.heightHeaderView {
            return height
        } else {
            return UITableView.automaticDimension
        }
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let event = params.data.event(indexPath: indexPath)
        let frameCell = tableView.cellForRow(at: indexPath)?.frame
        delegate?.didSelectEvent(event, type: .list, frame: frameCell)
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    
}

#endif
