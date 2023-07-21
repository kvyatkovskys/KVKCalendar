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
        KVKCalendarSwiftUIView(type: $vm.type,
                               date: $vm.date,
                               events: vm.events,
                               style: vm.style)
            .kvkOnRotate(action: { (newOrientation) in
                vm.orientation = newOrientation
            })
            .navigationBarTitle(vm.date.formatted(), displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    HStack(spacing: 0) {
                        Picker(vm.type.title, selection: $vm.type) {
                            ForEach(CalendarType.allCases) { (type) in
                                Text(type.title)
                            }
                        }
                        .tint(.red)
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            Button {
                                vm.date = Date()
                            } label: {
                                Text("Today")
                                    .font(.headline)
                            }
                            .tint(.red)
                        }
                    }
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
