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
    var body: some View {
        ZStack {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                     
                    Spacer()
                    ZStack {
                        HStack(spacing: 16) {
//                            MealCard(topLeadingColor: Color("OGT"), bottomTrailingColor: Color("OGB"), backgroundShadow: Color("OGB"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, title: "Breakfast", text: "Bread,\nPeanut butter,\nApple", cal: "525")
                            
                            MealCard(topLeadingColor: Color("OGT"), bottomTrailingColor: Color("OGB"), backgroundShadow: Color("OGB"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, title: "Breakfast", text: fastingManager.theSamples.filter { $0.mealPeriod == "Breakfast" }.map { $0.foodName }.joined(separator: ", "), cal: fastingManager.theSamples.filter { $0.mealPeriod == "Breakfast" }.map { $0.calories }.reduce(0, +))
                                
                            MealCard(topLeadingColor: Color("BGT"), bottomTrailingColor: Color("BGB"), backgroundShadow: Color("Shadowblue"), image: "noodle bowl", imageShadow: "noodleShadow", imageShadowAlpha: 0.4, title: "Lunch", text: fastingManager.theSamples.filter { $0.mealPeriod == "Lunch" }.map { $0.foodName }.joined(separator: ", "), cal: fastingManager.theSamples.filter { $0.mealPeriod == "Lunch" }.map { $0.calories }.reduce(0, +))
                            
//                            MealCard(topLeadingColor: Color("BGT"), bottomTrailingColor: Color("BGB"), backgroundShadow: Color("Shadowblue"), image: "noodle bowl", imageShadow: "noodleShadow", imageShadowAlpha: 0.4, title: "Lunch", text: "Salmon,\nMixed veggies,\nAvocado", cal: "602")
                            
                            SnackCard()
                        }
                        .padding(.leading, 30)
                    }
                    Spacer()
                        
                }
                .frame(height: 300)
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        fastingManager.saveCorrelation(sample: HKSampleWithDescription(foodName: names.randomElement()!, brandName: "", servingQuantity: 1.1, servingUnit: "", servingWeightGrams: 2, calories: Double.random(in: 1..<100), sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, meta: "", mealPeriod: timeOfMeal.randomElement()!))
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("D10"))
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .modifier(Shadow(level: 1))
                }
                .padding(.trailing, 25)
                .padding(.bottom, 85)
            }
            
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 199)
        .padding(.horizontal, -30)
        .padding(.top, 16)
    }
}

struct MealsToday_Previews: PreviewProvider {
    static var previews: some View {
        MealsToday(fastingManager: FastingManager())
    }
}
