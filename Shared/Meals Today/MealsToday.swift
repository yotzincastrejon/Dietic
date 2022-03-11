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
    @State var isActive = false
//    @State var firstColor = Color(hex: "b06e40")
//    @State var secondColor = Color(hex: "88292f")
    
    @State var firstColor = Color(hex: "f4a261")
    @State var secondColor = Color(hex: "e76f51")
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .breakfast, themeColor: [Color("OGT"), Color("OGB")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }){
                    MealCard(fastingManager: fastingManager, color: [Color("OGT"), Color("OGB")], backgroundShadow: Color("Shadowblue"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, mealPeriod: .breakfast)
                }
                
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .lunch, themeColor: [Color("B10"), Color("B00")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }) {
                    MealCard(fastingManager: fastingManager, color: [Color("BGT"), Color("BGB")], backgroundShadow: Color("Shadowblue"), image: "noodle bowl", imageShadow: "noodleShadow", imageShadowAlpha: 0.4, mealPeriod: .lunch)
                }
                
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .dinner, themeColor: [Color(hex: "e9c46a"),Color(hex: "f4a261"),Color(hex: "e76f51")], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }) {
                    MealCard(fastingManager: fastingManager,
                             color: [Color(hex: "e9c46a"),Color(hex: "f4a261"),Color(hex: "e76f51")], backgroundShadow: Color("Shadowblue"), image: "steak", imageShadow: "steakShadow", imageShadowAlpha: 0.4, mealPeriod: .dinner)
                }
//                SnackCard()
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .snack, themeColor: [Color(#colorLiteral(red: 1, green: 0.6745098039, blue: 0.7764705882, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2862745098, blue: 0.5058823529, alpha: 1))], accentColor: $accentColor).onAppear {
                    accentColor = .white
                }) {
                    MealCard(fastingManager: fastingManager, color: [Color(#colorLiteral(red: 1, green: 0.6745098039, blue: 0.7764705882, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.2862745098, blue: 0.5058823529, alpha: 1))],  backgroundShadow: Color("Shadowblue"), image: "melon", imageShadow: "steakShadow", imageShadowAlpha: 0.4, mealPeriod: .snack)
                }
                
            }
            .padding(.leading, 30)
            .padding(.vertical, 80)
            .padding(.trailing, 50)
            
        }
        .frame(height: 200)
        .padding(.horizontal, -30)
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: AddMoreFoodView(fastingManager: fastingManager, mealPeriod: .snack, topHeaderColors: [Color.cyan, Color.blue], rootIsActive: $isActive).onAppear {
                        accentColor = .white
                    }, isActive: $isActive) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("D10"))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .modifier(Shadow(level: 1))
                        
                    }
                    
                    
                }
                .padding(.trailing, 10)
                .padding(.bottom, 50)
            }
        )
        
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


