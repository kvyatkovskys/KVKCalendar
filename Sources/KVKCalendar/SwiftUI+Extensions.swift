//
//  SwiftUI+Extensions.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/16/22.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct DeviceRotationViewModifier: ViewModifier {
    
    let action: (UIInterfaceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { (_) in
                action(UIApplication.shared.orientation)
            }
    }
    
}

@available(iOS 13.0, *)
public extension View {
    
    func kvkOnRotate(action: @escaping (UIInterfaceOrientation) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
    
    func kvkHadnleNavigationView(_ view: some View) -> some View {
        if #available(iOS 16.0, *) {
            return NavigationStack {
                view
            }
        } else {
            return NavigationView {
                view
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
}
