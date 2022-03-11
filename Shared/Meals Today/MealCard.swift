//
//  MealCard.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct MealCard: View {
    @ObservedObject var fastingManager: FastingManager
//    let topLeadingColor: Color
//    let bottomTrailingColor: Color
    let color: [Color]
    let backgroundShadow: Color
    let image: String
    let imageShadow: String
    let imageShadowAlpha: Double
    let mealPeriod: EatingTime
    var body: some View {
        ZStack {
            
            //This is a gradient behind the original shape. Since SwiftUI doesn't have a spread feature in shadow the way I calculate it is by scaling down a duplicate view. The Formula that I'm using goes like this (Original Length - spread - spread) / Original Length = Scale Effect
            //That formula works for any spread that is negative. It works also because its pulling from all directions.
            //Duplicate View with shadow
            LinearGradient(colors: color, startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
                .shadow(color: backgroundShadow.opacity(0.8), radius: 30, x: 4, y: 12)
                .scaleEffect(0.86)
            
            //Visibile View without shadow.
            LinearGradient(colors: color, startPoint: .topLeading, endPoint: .bottomTrailing)
                .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
                
            
            
            
            VStack {
                HStack {
                    Circle()
                        .fill(.white).opacity(0.2)
                        .frame(width: 88,height: 88)
                        
                    Spacer()
                }
                Spacer()
            }
            .offset(x: -13, y: -39)
            .mask(RoundedCorners(color: [.blue], tl: 8, tr: 100, bl: 8, br: 8))
            
            
            VStack {
                HStack {
                    Image(image)
                        .frame(width: 64, height: 64)
                        
                    Spacer()
                }
                .padding(.leading, 4)
                Spacer()
            }
            .offset(x: 0, y: -21)
            .shadow(color: Color(imageShadow).opacity(imageShadowAlpha), radius: 16, x: 6, y: 10)
            
            
            
            GeometryReader { g in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Text(mealPeriod.description)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
    //                        .padding(.bottom, 9)
                            .padding(.top, 47)
                            
                        Spacer()
                        Text(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.foodName }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.white)
    //                        .padding(.bottom, 15)
    //                        .fixedSize(horizontal: false, vertical: true)
                            
                            
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.calories }.reduce(0, +)))")
                                .font(.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.005)
                                .foregroundColor(.white)
                                

                                
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.white)
                                
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
                
            }
//            .fixedSize(horizontal: true, vertical: false)
            
        }
        .frame(width: 116, height: 178)
        
        
    }
}

struct MealCard_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        MealCard(fastingManager: FastingManager(), color: [Color.red], backgroundShadow: Color("OGB"), image: "bread", imageShadow: "EggSandwichShadow", imageShadowAlpha: 0.3, mealPeriod: .breakfast)
            .fixedSize(horizontal: true, vertical: false)
    }
}


