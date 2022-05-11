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
    @State var events: [Event] = []
    
    var body: some View {
        NavigationView {
            CalendarDisplayView(events: $events, type: $typeCalendar)
                .navigationBarTitle("", displayMode: .inline)
                .edgesIgnoringSafeArea(.bottom)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack(alignment: .center) {
                            Picker("", selection: $typeCalendar, content: {
                                ForEach(CalendarType.allCases,
                                        content: { type in
                                    Text(type.rawValue.capitalized)
                                })
                            })
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
