//
//  ContentView.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 4/16/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import SwiftUI
import KVKCalendar

@available(iOS 17.0, *)
struct CalendarView: View {

    @State private var vm = CalendarViewModel()
    
    var body: some View {
        NavigationStack {
            calendarView
                .task {
                    await vm.loadEvents()
                }
        }
    }
    
    private var calendarView: some View {
        KVKCalendarSwiftUIView(type: vm.type,
                               date: vm.date,
                               events: vm.events,
                               selectedEvent: vm.selectedEvent,
                               style: vm.style)
            .kvkOnRotate(action: { (newOrientation) in
                vm.orientation = newOrientation
            })
            .navigationBarTitle(vm.date.formatted(date: .abbreviated, time: .omitted), displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Picker(vm.type.title, selection: $vm.type) {
                        ForEach(CalendarType.allCases) { (type) in
                            Text(type.title)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.red)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button {
                            vm.date = Date()
                        } label: {
                            Text("Today")
                                .font(.headline)
                        }
                        .tint(.red)
                    }
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

@available(iOS 17.0, *)
#Preview {
    CalendarView()
}
