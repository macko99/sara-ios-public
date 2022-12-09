//
//  CustomPopupView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 16/10/2021.
//

import SwiftUI

struct CustomPopupView<T: View>: ViewModifier {
    let popup: T
    let isPresented: Bool
    let alignment: Alignment
    
    init(isPresented: Bool, alignment: Alignment, @ViewBuilder content: () -> T) {
        self.isPresented = isPresented
        self.alignment = alignment
        popup = content()
    }
    
    func body(content: Content) -> some View {
        content.overlay(popupContent())
    }
    
    @ViewBuilder private func popupContent() -> some View {
        GeometryReader { geometry in
            if isPresented {
                popup
                    .animation(.spring())
                    .transition(.offset(x: 0, y: geometry.belowScreenEdge))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
            }
        }
    }
}

private extension GeometryProxy {
    var belowScreenEdge: CGFloat {
        UIScreen.main.bounds.height - frame(in: .global).minY
    }
}

extension View {
    func popup<T: View>(
        isPresented: Bool,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> T
    ) -> some View {
        return modifier(CustomPopupView(isPresented: isPresented, alignment: alignment, content: content))
    }
}
