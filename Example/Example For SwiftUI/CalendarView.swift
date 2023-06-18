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
    @ObservedObject private var vm = CalendarViewModel()
    
    var body: some View {
        NavigationStack {
            calendarView
                .task {
                    vm.loadEvents()
                }
        }
    }
    
    private var calendarView: some View {
        KVKCalendarSwiftUIView(type: $typeCalendar,
                               date: vm.initialDate,
                               events: vm.events,
                               selectedDate: $vm.selectedDate)
            .kvkOnRotate(action: { (newOrientation) in
                orientation = newOrientation
            })
            .navigationBarTitle(vm.selectedDate.formatted(), displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    HStack(spacing: 0) {
                        Picker(typeCalendar.title, selection: $typeCalendar) {
                            ForEach(CalendarType.allCases) { (type) in
                                Text(type.title)
                            }
                        }
                        .frame(width: 80)
                        Button {
                            vm.selectedDate = Date()
                        } label: {
                            Text("Today")
                                .font(.headline)
                        }
                    }
                    .tint(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.addNewEvent()
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
