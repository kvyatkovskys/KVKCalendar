//
//  ContentView.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 4/16/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar

@available(iOS 16.0, *)
struct CalendarView: View {
    
    @State private var typeCalendar = CalendarType.week
    @State private var orientation: UIInterfaceOrientation = .unknown
    @ObservedObject private var vm: CalendarViewModel
    @ObservedObject private var calendarVM: KVKCalendarViewModel
    
    init() {
        vm = CalendarViewModel()
        calendarVM = KVKCalendarViewModel(date: Date(), style: Style())
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                calendarView
            }
        }
    }
    
    private var calendarView: some View {
        KVKCalendarSwiftUIView(vm: calendarVM)
            .kvkOnRotate(action: { (newOrientation) in
                orientation = newOrientation
            })
            .navigationBarTitle(calendarVM.date.formatted(), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Picker(typeCalendar.title, selection: $typeCalendar) {
                            ForEach(CalendarType.allCases) { (type) in
                                Text(type.title)
                            }
                        }
                        Button {
                            calendarVM.setDate(Date())
                        } label: {
                            Text("Today")
                                .font(.headline)
                        }
                    }
                    .tint(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if let event = vm.addNewEvent() {
                            vm.events.append(event)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.red)
                }
            }
    }
    
}

@available(iOS 16.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
