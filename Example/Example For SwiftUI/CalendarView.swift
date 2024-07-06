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
    @State private var date = Date()
    
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
                               date: $vm.date,
                               events: vm.events,
                               event: $vm.selectedEvent,
                               style: vm.style)
            .kvkOnRotate(action: { (newOrientation) in
                vm.orientation = newOrientation
            })
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Picker(vm.type.title, selection: $vm.type) {
                        ForEach(CalendarType.allCases) { (type) in
                            Text(type.title)
                        }
                    }
                    .tint(.red)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button {
                            vm.date = .now
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
