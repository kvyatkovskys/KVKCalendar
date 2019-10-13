<pre>
<img src="https://i.postimg.cc/PNsT9nKV/Simulator-Screen-Shot-i-Phone-Xs-2019-05-04-at-11-11-07-iphon.png" height="400" width="380">   <img src="https://i.postimg.cc/VvMddRVT/Screenshot-2019-05-04-at-11-42-20.png" height="320" width="430">
</pre>

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

## Usage
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
