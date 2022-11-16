//
//  ContentView.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 4/16/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar

@available(iOS 14.0, *)
struct ContentView: View {
    @State private var typeCalendar = CalendarType.day
    @State private var events: [Event] = []
    @State private var updatedDate: Date?
    @State private var orientation: UIInterfaceOrientation = .unknown
    
    var body: some View {
        kvkHadnleNavigationView(calendarView)
    }
    
    private var calendarView: some View {
        CalendarDisplayView(events: $events,
                            type: $typeCalendar,
                            updatedDate: $updatedDate,
                            orientation: $orientation)
        .kvkOnRotate(action: { (newOrientation) in
            orientation = newOrientation
        })
        .navigationBarTitle("", displayMode: .inline)
        .edgesIgnoringSafeArea(.bottom)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Picker("", selection: $typeCalendar, content: {
                        ForEach(CalendarType.allCases,
                                content: { type in
                            Text(type.rawValue.capitalized)
                        })
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer(minLength: 20)
                    
                    Button {
                        updatedDate = Date()
                    } label: {
                        Text("Today")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
