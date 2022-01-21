//
//  DietDetailView.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI

struct DietDetailView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Net calorie overview")
                                .font(.headline)
                    
                            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()).uppercased())
                                .font(.caption2)
                                .foregroundColor(Color.blue)
                        }
                        Spacer()
                    }
                }.padding(.horizontal, 30)
                
                HStack {
                    CompleteGraph()
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text("Macronutrient analysis")
                            .font(Font.custom("Inter", size: 17))
                            .fontWeight(.medium)
                            .foregroundColor(Color("D00"))
                        Spacer()
                    }
                    
                    ZStack {
                        MacronutrientAnalysis()
                        
                     
                    }
                       
                    
                    Rectangle()
                        .frame(height: 244)
                        .cornerRadius(8)
                    
                    HStack {
                        Text("Nutrition facts")
                            .font(Font.custom("Inter", size: 17))
                            .fontWeight(.medium)
                            .foregroundColor(Color("D00"))
                        Spacer()
                    }
                    
                    Rectangle()
                        .frame(height: 480)
                        .cornerRadius(8)
                    
                }
                .padding(.horizontal, 30)
            }
        }
    }
}

struct DietDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DietDetailView()
    }
}






