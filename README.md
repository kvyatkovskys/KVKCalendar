<a href="https://postimg.cc/BLBC07wH" target="_blank"><img src="https://i.postimg.cc/BLBC07wH/Screenshot-2019-10-29-at-11-07-07.png" alt="Screenshot-2019-10-29-at-11-07-07"/></a> <a href="https://postimg.cc/QKNJxgRP" target="_blank"><img src="https://i.postimg.cc/QKNJxgRP/Screenshot-2019-10-29-at-11-58-44.png" alt="Screenshot-2019-10-29-at-11-58-44"/></a> <a href="https://postimg.cc/f30wpxFc" target="_blank"><img src="https://i.postimg.cc/f30wpxFc/Screenshot-2019-10-29-at-12-00-35.png" alt="Screenshot-2019-10-29-at-12-00-35"/></a> <a href="https://postimg.cc/tZQXjsQL" target="_blank"><img src="https://i.postimg.cc/tZQXjsQL/Screenshot-2019-10-29-at-12-00-59.png" alt="Screenshot-2019-10-29-at-12-00-59"/></a><br/><br/>

[![CI Status](https://img.shields.io/travis/kvyatkovskys/KVKCalendar.svg?style=flat)](https://travis-ci.org/kvyatkovskys/KVKCalendar)
[![Version](https://img.shields.io/cocoapods/v/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)
[![License](https://img.shields.io/cocoapods/l/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)
[![Platform](https://img.shields.io/cocoapods/p/KVKCalendar.svg?style=flat)](https://cocoapods.org/pods/KVKCalendar)

# KVKCalendar

**KVKCalendar** is a most fully customization calendar library. Library consists of four modules for displaying various types of calendar (*day*, *week*, *month*, *year*). You can choose any module or use all. It is designed based on a standard iOS calendar, but with additional features. Timeline displays the schedule for the day and week.

## Requirements

- iOS 10.0+
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
        var events = [Event]()
        
        for model in models {
            var event = Event()
            event.id = model.id
            event.start = model.startDate // start date event
            event.end = model.endDate // end date event
            event.color = model.color
            event.isAllDay = model.allDay
            event.isContainsFile = !model.files.isEmpty
        
            // Add text event (title, info, location, time)
            if model.allDay {
                event.text = "\(model.title)"
            } else {
                event.text = "\(startTime) - \(endTime)\n\(model.title)"
            }
            events.append(event)
        }
        completion(events)
    }
}

extension ViewController: CalendarDataSource {
    func eventsForCalendar() -> [Event] {
        return events
    }
}
```

Implement `CalendarDelegate` to handle user action.

```swift
calendar.delegate = self

extension ViewController: CalendarDelegate {
    func didSelectDate(date: Date?, type: CalendarType) {
        print(date, type)
    }

    func didSelectEvent(_ event: Event, type: CalendarType, frame: CGRect?) {
        print(event)
    }
}
```

## Usage for SwiftUI
Create a new `SwiftUI` file => import `KVKCalendar`.
Create a struct `CalendarDisplayView` with declare the protocol `UIViewRepresentable` to connect `UIKit` with `SwiftUI`.

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
        
        func eventsForCalendar() -> [Event] {
            return events
        }
    }
}

struct CalendarContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarDisplayView()
    }
}
```

Create a new `SwiftUI` file and implement `CalendarDisplayView`.

```swift
import SwiftUI

struct CalendarContentView: View {    
    var body: some View {
        CalendarDisplayView()
    }
}

struct CalendarDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarContentView()
    }
}
```

## Styles
To customize calendar create an object `Style` and add to `init` class `CalendarView`.

```swift
var style = Style()
style.monthStyle.isHiddenSeporator = false
style.timelineStyle.offsetTimeY = 80
style.timelineStyle.offsetEvent = 3
style.allDayStyle.isPinned = true
style.timelineStyle.widthEventViewer = 500
let calendar = CalendarView(frame: frame, style: style)
```

If needed to customize `Locale`, `TimeZone`.

```swift
style.locale = Locale // create any
style.timezone = TimeZone //create any
```

## Author

[Sergei Kviatkovskii](https://github.com/kvyatkovskys)

## License

KVKCalendar is available under the [MIT license](https://github.com/kvyatkovskys/KVKCalendar/blob/master/LICENSE.md)
