//
//  MealsToday.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct MealsToday: View {
    @ObservedObject var fastingManager: FastingManager
    @State var names = ["Bread", "Peanut Butter", "Apple"]
    @State var timeOfMeal = ["Lunch", "Breakfast"]
    @Namespace var emptyName
    var namespace: Namespace.ID
    @Binding var show: Bool
    @Binding var showStatusBar: Bool
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                if !show {
                MealCard(namespace: namespace, topLeadingColor: Color("OGT"), bottomTrailingColor: Color("OGB"), backgroundShadow: Color("OGB"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, title: "Breakfast", text: fastingManager.theSamples.filter { $0.mealPeriod == "Breakfast" }.map { $0.foodName }.joined(separator: ", "), cal: fastingManager.theSamples.filter { $0.mealPeriod == "Breakfast" }.map { $0.calories }.reduce(0, +))
                    .onTapGesture {
                        withAnimation(.openCard) {
                            show.toggle()
                            showStatusBar = false
                        }
                    }
                }
                //                                        .onTapGesture {
                //                                            withAnimation(.openCard) {
                //                                                show.toggle()
                //                                                showStatusBar = false
                //                                            }
                //                                        }
                
                NavigationLink(destination: DiaryViewBackground(fastingManager: fastingManager, mealPeriod: .lunch)) {
                MealCard(namespace: emptyName, topLeadingColor: Color("BGT"), bottomTrailingColor: Color("BGB"), backgroundShadow: Color("Shadowblue"), image: "noodle bowl", imageShadow: "noodleShadow", imageShadowAlpha: 0.4, title: "Lunch", text: fastingManager.theSamples.filter { $0.mealPeriod == "Lunch" }.map { $0.foodName }.joined(separator: ", "), cal: fastingManager.theSamples.filter { $0.mealPeriod == "Lunch" }.map { $0.calories }.reduce(0, +))
                }
                .accentColor(.white)
                SnackCard()
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
    @Namespace static var namespace

    static var previews: some View {
        NavigationView {
        MealsToday(fastingManager: FastingManager(), namespace: namespace, show: .constant(true), showStatusBar: .constant(true))
        }
    }
}

extension Animation {
    static let openCard = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let closeCard = Animation.spring(response: 0.6, dampingFraction: 0.9)
}
