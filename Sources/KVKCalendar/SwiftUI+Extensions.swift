//
//  SwiftUI+Extensions.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 11/16/22.
//

import SwiftUI

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

public extension View {
    
    func kvkOnRotate(action: @escaping (UIInterfaceOrientation) -> Void) -> some View {
        modifier(DeviceRotationViewModifier(action: action))
    }
    
    func kvkHandleNavigationView(_ view: some View) -> some View {
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

public protocol ItemsMenuProxy: Identifiable, Equatable {
    
    var title: String { get }
    
}

@available(iOS 14.0, *)
public struct ItemsMenu<T: ItemsMenuProxy>: View {
    
    @Binding var type: T
    @State var items: [T]
    private var showCheckmark: Bool
    private var color: Color
    private var showDropDownIcon: Bool
    
    public init(type: Binding<T>,
                items: [T],
                showCheckmark: Bool = false,
                color: Color = .red,
                showDropDownIcon: Bool = false) {
        _type = type
        _items = State(initialValue: items)
        self.showCheckmark = showCheckmark
        self.color = color
        self.showDropDownIcon = showDropDownIcon
    }
        
    public var body: some View {
        Menu {
            ForEach(items) { (btn) in
                Button {
                    type = btn
                } label: {
                    HStack {
                        if type == btn && showCheckmark {
                            Image(systemName: "checkmark")
                        }
                        Text(btn.title)
                    }
                }
            }
        } label: {
            HStack {
                Text(type.title)
                    .foregroundColor(color)
                    .font(.headline)
                if showDropDownIcon {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .frame(width: 12, height: 7)
                        .foregroundColor(color)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
                }
            }
        }
    }
    
}

@available(iOS 14.0, *)
struct ItemsMenu_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(CalendarType.day) { ItemsMenu<CalendarType>(type: $0, items: CalendarType.allCases.reversed(), showCheckmark: true, showDropDownIcon: true) }
    }
}

public struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    public var body: some View {
        content($value)
    }
    
    public init(_ value: Value,
                content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}
