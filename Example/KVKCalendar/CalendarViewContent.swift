//
//  CalendarViewContent.swift
//  KVKCalendar_Example
//
//  Created by Sergei Kviatkovskii on 31.10.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct CalendarViewContent: View {
    var body: some View {
        CalendarDisplayView().edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle("", displayMode: .inline)
    }
}

@available(iOS 13.0.0, *)
struct CalendarViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalendarViewContent()
        }
    }
}
