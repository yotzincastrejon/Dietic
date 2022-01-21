//
//  CapsuleMacroView.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct CapsuleMacroView: View {
    @Binding var percentage: Double
    var body: some View {
            ZStack {
                Capsule()
                    .frame(width: 148, height: 8)
                    .foregroundColor(Color("L20"))
                
                Capsule()
                    .fill(LinearGradient(colors: [Color("B30"), Color("B20")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 148, height: 8)
                    .foregroundColor(Color.blue)
                    .offset(x: -148 * (1 - maxPercent(percent: percentage)))
                    .clipShape(Capsule())
                
            }
        .animation(.easeInOut, value: maxPercent(percent: percentage))
        
    }
    func maxPercent(percent: Double) -> Double {
        if percent < 0 {
            return 0.0
        } else {
            if percent > 1 {
                return 1.0
            } else {
                return percent
            }
        }
    }
}

struct CapsuleMacroView_Previews: PreviewProvider {
    static var previews: some View {
        CapsuleMacroView(percentage: Binding.constant(0.45))
    }
}
