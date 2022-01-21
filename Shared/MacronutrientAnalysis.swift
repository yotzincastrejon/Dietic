//
//  MacronutrientAnalysis.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/22/21.
//

import SwiftUI

struct MacronutrientAnalysis: View {
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ProgressRingView(progress: Binding.constant(0.25), thickness: 10, dotOnTip: false, width: 48, gradient: Gradient(colors: [Color("Shadowblue"), Color("B10")]), backgroundCircleWidth: 10, backgroundCircleColor: .blue.opacity(0.10))
                    .overlay(
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color("B40"))
                            .font(Font.system(size: 22))
                            .rotationEffect(Angle(degrees: 7))
                    )
                
                VStack(alignment: .leading) {
                    Text("623 kcal")
                        .font(Font.custom("Inter", size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(Color("D00"))
                    Text("25% of 2528 kcal daily goal")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color("D10"))
                }
                .padding(.leading, 20)
                Spacer()
            }
            Spacer()
            
            HStack(spacing: 0) {
                VStack(spacing: 20) {
                    CapsuleMacroView(percentage: Binding.constant(0.45))
                        .frame(height: 16)
                    CapsuleMacroView(percentage: Binding.constant(0.45))
                        .frame(height: 16)
                    CapsuleMacroView(percentage: Binding.constant(0.80))
                        .frame(height: 16)
                }
                
                VStack(alignment: .trailing, spacing: 20) {
                    Text("130 / 142 g")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("B10"))
                        .frame(height: 16)
                    Text("34 / 64 g")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("B10"))
                        .frame(height: 16)
                    Text("32 / 42 g")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("B10"))
                        .frame(height: 16)
                }
                .padding(.leading, 7)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Carbs")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("D00"))
                        .frame(height: 16)
                    Text("Protein")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("D00"))
                        .frame(height: 16)
                    Text("Fat")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color("D00"))
                        .frame(height: 16)
                }
                .padding(.leading, 8)
                Spacer()
            }
        }
        .padding(24)
        .frame(height: 224)
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(8)
        .modifier(Shadow(level: 3))
    }
}

struct MacronutrientAnalysis_Previews: PreviewProvider {
    static var previews: some View {
        MacronutrientAnalysis()
    }
}
