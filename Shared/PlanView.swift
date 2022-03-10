//
//  PlanView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/9/22.
//

import SwiftUI

struct PlanView: View {
    
    var body: some View {
        HStack {
            Text("Plan: ")
                .font(.headline)
            Button(action: {
                
            }) {
                ZStack {
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(height: 58)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "6F8FEA").opacity(0.08), radius: 2, x: 0, y: 2)
                        .shadow(color: Color(hex: "6F8FEA").opacity(0.16), radius: 12, x: 4, y: 12)
                    
                        HStack {
//                            Image("weight-loss")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(height: 38)
                            
                            Text("Weight Loss")
                                .font(.headline)
                            .foregroundColor(Color(uiColor: .label))
                            
                        }
                        
                    
                }
        }
        }
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                PlanView()
                    .padding(.horizontal)
            }
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                PlanView()
                    .padding(.horizontal)
            }
            .preferredColorScheme(.dark)
        }
    }
}
