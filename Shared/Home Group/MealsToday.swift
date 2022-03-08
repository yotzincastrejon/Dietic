//
//  MealsToday.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct MealsToday: View {
    @ObservedObject var fastingManager: FastingManager
    @Binding var accentColor: Color
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .breakfast, themeColor: [Color("OGT"), Color("OGB")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }){
                    MealCard(fastingManager: fastingManager, topLeadingColor: Color("OGT"), bottomTrailingColor: Color("OGB"), backgroundShadow: Color("OGB"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, mealPeriod: .breakfast)
                }
                
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .lunch, themeColor: [Color("B10"), Color("B00")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }) {
                    MealCard(fastingManager: fastingManager, topLeadingColor: Color("BGT"), bottomTrailingColor: Color("BGB"), backgroundShadow: Color("Shadowblue"), image: "noodle bowl", imageShadow: "noodleShadow", imageShadowAlpha: 0.4, mealPeriod: .lunch)
                }
                
                SnackCard()
                
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .dinner, themeColor: [Color("PurpleTop"), Color("PurpleBottom")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }) {
                    MealCard(fastingManager: fastingManager, topLeadingColor: Color("PurpleTop"), bottomTrailingColor: Color("PurpleBottom"), backgroundShadow: Color("Shadowblue"), image: "steak", imageShadow: "steakShadow", imageShadowAlpha: 0.4, mealPeriod: .dinner)
                }
            }
            .padding(.leading, 30)
            .padding(.vertical, 80)
            .padding(.trailing, 50)
            
        }
        .frame(height: 200)
        .padding(.horizontal, -30)
        
        
    }
}

struct MealsToday_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            MealsToday(fastingManager: FastingManager(), accentColor: Binding.constant(.blue))
        }
    }
}

extension Animation {
    static let openCard = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let closeCard = Animation.spring(response: 0.6, dampingFraction: 0.9)
}
