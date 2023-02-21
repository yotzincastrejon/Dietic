//
//  CustomSegementedControl.swift
//  Dietic (iOS)
//
//  Created by Yotzin Castrejon on 2/20/23.
//

import SwiftUI

struct CustomSegmentedControl: View {
    @State var preselectedIndex: Int = 0
    var options: [String]
    let color = Color.red

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id:\.self) { index in
                let isSelected = preselectedIndex == index
                ZStack {
                    Rectangle()
                        .fill(color.opacity(0.2))

                    Rectangle()
                        .fill(color)
                        .cornerRadius(20)
                        .padding(2)
                        .opacity(isSelected ? 1 : 0.01)
                        .onTapGesture {
                            withAnimation(.interactiveSpring(response: 0.2,
                                                             dampingFraction: 2,
                                                             blendDuration: 0.5)) {
                                preselectedIndex = index
                            }
                        }
                }
                .overlay(
                    Text(options[index])
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundColor(isSelected ? .black : .gray)
                )
            }
        }
        .frame(height: 40)
        .cornerRadius(20)
    }
}


struct CustomSegmentedControl_Previews: PreviewProvider {
    @State var preselectedIndex = 0
    static var previews: some View {
        CustomSegmentedControl(options: ["Berlin", "Munich", "Hamburg"])
    }
}




