//
//  TestView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/15/22.
//

import SwiftUI

struct TestView: View {
    @State var isOn = false
    @State var dragAmount: CGPoint?
    var body: some View {
        GeometryReader { g in
            HStack {
                Button(action: {
                    isOn.toggle()
                }) {
                    Image(systemName: isOn ? "lightbulb.circle.fill" : "lightbulb.circle")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(isOn ? .yellow : .gray)
                        .frame(width: 70, height: 70)
                }
                .animation(.linear, value: dragAmount)
                .position(dragAmount ?? CGPoint(x: g.size.width / 2, y: g.size.height / 2))
                .highPriorityGesture(
                DragGesture()
                    .onChanged { dragAmount = $0.location }
                )
                .offset(y: 150)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
