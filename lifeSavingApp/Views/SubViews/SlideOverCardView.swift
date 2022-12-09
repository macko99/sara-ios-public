//
//  custom view made to enable slide menu from botton on map view - viw and animations developed withoud any external library
//
//  SlideOverView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 15/06/2021.
//

import SwiftUI

struct SlideOverCardView<Content: View> : View {
    
    @GestureState private var dragState = DragState.inactive
    @State var position = CardPosition.top
    
    //place for injected contect of this card
    var content: () -> Content
    
    var body: some View {
        let drag = DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded(onDragEnded)
        
        return VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 50, height: 5)
                .foregroundColor(Color.gray)
                .padding(5).zIndex(1.0)
            self.content()
            Spacer()
        }
        .frame(width: UIScreen.screenWidth ,height: UIScreen.screenHeight)
        .background(Color("SlideOverCard"))
        .cornerRadius(10.0)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
        .offset(y:
                    (self.position.ValueForScreen + self.dragState.translation.height) > UIScreen.screenHeight*0.25 ?
                (self.position.ValueForScreen + self.dragState.translation.height) :
                    UIScreen.screenHeight*0.25)
        .animation(self.dragState.isDragging ? nil : .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
        .gesture(drag)
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
        let cardTopEdgeLocation = self.position.ValueForScreen + drag.translation.height
        
        let closestPosition: CardPosition
        
        if (cardTopEdgeLocation - CardPosition.top.ValueForScreen) < (CardPosition.bottom.ValueForScreen - cardTopEdgeLocation) {
            closestPosition = .top
        } else {
            closestPosition = .bottom
        }
        
        if verticalDirection > 0 {
            self.position = .bottom
        } else if verticalDirection < 0 {
            self.position = .top
        } else {
            self.position = closestPosition
        }
    }
}
