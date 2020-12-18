<img src="Screenshots/iphone.png" width="280"> <img src="Screenshots/ipad.png" width="530">

[![CI Status](https://img.shields.io/travis/kvyatkovskys/KVKCalendar.svg?style=flat)](https://travis-ci.org/kvyatkovskys/KVKCalendar)
[![Version](https://img.shields.io/cocoapods/v/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=fla)](https://github.com/Carthage/Carthage/)
[![License](https://img.shields.io/cocoapods/l/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)
[![Platform](https://img.shields.io/cocoapods/p/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)

# KVKCalendar

**KVKCalendar** is a most fully customization calendar and timleline library. Library consists of four modules for displaying various types of calendar (*day*, *week*, *month*, *year*). You can choose any module or use all. It is designed based on a standard iOS calendar, but with additional features. Timeline displays the schedule for the day and week.

## Need Help?
If you have a **question** about how to use KVKCalendar in your application, ask it on StackOverflow using the [KVKCalendar](https://stackoverflow.com/questions/tagged/kvkcalendar) tag.

Please, use [Issues](https://github.com/kvyatkovskys/KVKCalendar/issues) only for reporting **bugs** or requesting a new **features** in the library.

## Requirements

- iOS 10.0+
- MacOS 10.15+ (Supports Mac Catalyst)
- Swift 5.0+

## Installation

**KVKCalendar** is available through [CocoaPods](https://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods
~~~bash
pod 'KVKCalendar'
~~~

### Carthage
~~~bash
github "kvyatkovskys/KVKCalendar"
~~~

## Usage for UIKit
Import `KVKCalendar`.
Create a subclass view `CalendarView` and implement `CalendarDataSource` protocol. Create an array of class `[Event]` and return this array in the function.

```swift
import KVKCalendar

class ViewController: UIViewController {
    var events = [Event]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let calendar = CalendarView(frame: frame)
        calendar.dataSource = self
        view.addSubview(calendar)
        
        createEvents { (events) in
            self.events = events
            self.calendarView.reloadData()
        }
    }
}

extension ViewController {
    func createEvents(completion: ([Event]) -> Void) {
        let models = // Get events from storage / API
        
        let events = models.compactMap({ (item) in
            var event = Event()
            event.ID = item.id
            event.start = item.startDate // start date event
            event.end = item.endDate // end date event
            event.color = item.color
            event.isAllDay = item.allDay
            event.isContainsFile = !item.files.isEmpty
            event.recurringType = // recurring event type - .everyDay, .everyWeek
        
            // Add text event (title, info, location, time)
            if item.allDay {
                event.text = "\(item.title)"
            } else {
                event.text = "\(startTime) - \(endTime)\n\(item.title)"
            }
            return event
        })
        completion(events)
    }
}

extension ViewController: CalendarDataSource {
    func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
        // if you want to get events from iOS calendars
        // set calendars name to style.systemCalendars = ["Test"]
        let mappedEvents = systemEvents.compactMap({ $0.transform() })
        return events + mappedEvents
    }
}
```

Implement `CalendarDelegate` to handle user action and control calenadr behavior.

```swift
calendar.delegate = self
```

To use a custom view for specific event or date you need to create a new view of class `EventViewGeneral` and return the view in function.

```swift
class CustomViewEvent: EventViewGeneral {
    override init(style: Style, event: Event, frame: CGRect) {
        super.init(style: style, event: event, frame: frame)
    }
}

// optional function from CalendarDataSource
func willDisplayEventView(_ event: Event, frame: CGRect, date: Date?) -> EventViewGeneral? {
    guard event.ID == id else { return nil }
    
    return customEventView
}
```

<img src="Screenshots/custom_event_view.png" width="300">

To use a custom date cell, just subscribe on this optional method from `CalendarDataSourcse` (works for Day/Week/Month/Year views).
```swift
func dequeueDateCell(date: Date?, type: CalendarType, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {    
    return collectionView.dequeueCell(indexPath: indexPath) { (cell: CustomDayCell) in
        configurate a cell
    }
}
```

<img src="Screenshots/custom_day_cell.png" width="300">

## Usage for SwiftUI
Add a new `SwiftUI` file and import `KVKCalendar`.
Create a struct `CalendarDisplayView` and declare the protocol `UIViewRepresentable` for connection `UIKit` with `SwiftUI`.

```swift
import SwiftUI
import KVKCalendar

struct CalendarDisplayView: UIViewRepresentable {
    
    private var calendar: CalendarView = {
        return CalendarView(frame: frame, style: style)
    }()
        
    func makeUIView(context: UIViewRepresentableContext<CalendarDisplayView>) -> CalendarView {
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        calendar.reloadData()
        return calendar
    }
    
    func updateUIView(_ uiView: CalendarView, context: UIViewRepresentableContext<CalendarDisplayView>) {
        
    }
    
    func makeCoordinator() -> CalendarDisplayView.Coordinator {
        Coordinator(self)
    }
    
    // MARK: Calendar DataSource and Delegate
    class Coordinator: NSObject, CalendarDataSource, CalendarDelegate {
        private let view: CalendarDisplayView
        
        init(_ view: CalendarDisplayView) {
            self.view = view
            super.init()
        }
        
        func eventsForCalendar(systemEvents: [EKEvent]) -> [Event] {
            return events
        }
    }
}

struct CalendarDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarDisplayView()
    }
}
```

Create a new `SwiftUI` file and add `CalendarDisplayView` to `body`.

```swift
import SwiftUI

struct CalendarContentView: View {    
    var body: some View {
        NavigationView {
            CalendarDisplayView()
        }
    }
}

struct CalendarContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarContentView()
    }
}
```

## Styles
To customize calendar create an object `Style` and add to `init` class `CalendarView`.

```swift
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
    public var systemCalendars: Set<String> = []
}
```

## Author

[Sergei Kviatkovskii](https://github.com/kvyatkovskys)

## License

KVKCalendar is available under the [MIT license](https://github.com/kvyatkovskys/KVKCalendar/blob/master/LICENSE.md)
