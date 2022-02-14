//
//  DiaryView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/10/22.
//

import SwiftUI

struct DiaryViewBackground: View {
    
    
    @State var resize = false
    var body: some View {
        GeometryReader { g in
            ZStack {
                ZStack {
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [Color("B10"), Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: g.size.height / 3)
                        Spacer()
                    }
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [Color("B00").opacity(0), Color(#colorLiteral(red: 0, green: 0.02745098039, blue: 0.1647058824, alpha: 1))], startPoint: .center, endPoint: .bottom)).opacity(0.5)
                            .frame(height: g.size.height / 3)
                        Spacer()
                    }
                    
                    VStack {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.white).opacity(0.10)
                                    .frame(width: 64)
                                Image("Camera")
                                    .renderingMode(.template)
                                    .foregroundColor(Color.white.opacity(0.30))
                                    .frame(width: 40, height: 40)
                            }
                        }
                        .frame(height: g.size.height / 3)
                        Spacer()
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    DiaryView()
                        .frame(height: g.size.height / 1.25)
                    
                }
            }
        }
    }
}

struct DiaryViewBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DiaryViewBackground()
            DiaryViewBackground()
                .preferredColorScheme(.dark)
            //            DiaryView()
            //                .preferredColorScheme(.dark)
        }
    }
}

struct DiaryView: View {
    let strings: [String] = ["Salmon", "Mixed Veggies", "Avocado"]
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    var body: some View {
        GeometryReader { g in
        VStack {
            Spacer()
            ZStack {
                RoundedCorners(color: [Color(uiColor: .systemBackground)], tl: 0, tr: 64, bl: 0, br: 0)
                ScrollView {
                    VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Lunch")
                                .font(.largeTitle)
                                .bold()
                            Text("Today")
                            
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.subheadline)
                            HStack(alignment: .firstTextBaseline,spacing: 2) {
                                Text("540").monospacedDigit()
                                    .font(.title2)
                                
                                Text("kcal")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(Color("B00"))
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 30)
                    
                    List {
                        ForEach(strings, id: \.self) { item in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                    Text(item)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        Text("Toasted • 100g")
                                            .font(.caption2)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    Spacer()
                                    Text("540 kcal")
                                        .font(.subheadline)
                                        .foregroundColor(Color("B10"))
                                }
                           
                            }
                        }
                        .onDelete {_ in
                            
                        }
                    }
                    .environment(\.defaultMinListRowHeight, 52)
                    .frame(minHeight: 52 * CGFloat(strings.count))
                    .listStyle(.plain)
                    .padding(.top, 32)
                    .padding(.leading, 10)
                    
                    Button(action: {
                        
                    }) {
                        ZStack {
                            Capsule()
                                .fill(LinearGradient(colors: [Color("B10"), Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text("Add More Food")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(width: 175, height: 48)
                    }
                    .padding(.top, 32)
                    
                    NutritionFacts()
                        .padding(.top, 48)
                        .padding(.horizontal, 30)
                }
                }
                .mask {
                    RoundedCorners(color: [Color(uiColor: .green)], tl: 0, tr: 64, bl: 0, br: 0)
                }
//                Rectangle()
//                    .fill(.blue)
//                    .frame(width: 2, height: 300)
//                    .offset(x: -183, y: -200)
            }
            
            
        }
        }
    }
}

struct NutritionFacts: View {
    var heading: Color = Color(uiColor: .systemGray4)
    var subheading: Color = Color(uiColor: .secondarySystemBackground)
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nutrition facts: Lunch")
                    .fontWeight(.medium)
                Spacer()
            }
            NutritionFactsHeading(title: "Energy", amount: "540 kcal", heading: heading)
            
            Group {
            NutritionFactsHeading(title: "Fat", amount: "32 g", heading: heading)
            NutritionFactsSubHeading(title: "Saturated fat", amount: "30 g", subheading: subheading)
            NutritionFactsSubHeading(title: "Monounsaturated fat", amount: "2 g", subheading: subheading)
            NutritionFactsSubHeading(title: "Polyunsaturated fat", amount: "0 g", subheading: subheading)
            }
            NutritionFactsHeading(title: "Protein", amount: "24 g", heading: heading)
            
            Group {
            NutritionFactsHeading(title: "Carbs", amount: "130 g", heading: heading)
            NutritionFactsSubHeading(title: "Dietary Fiber", amount: "100 g", subheading: subheading)
            NutritionFactsSubHeading(title: "Sugar", amount: "30 g", subheading: subheading)
            }
            
            Group {
            NutritionFactsHeading(title: "Other", amount: "", heading: heading)
            NutritionFactsSubHeading(title: "Cholesterol", amount: "0 g", subheading: subheading)
            NutritionFactsSubHeading(title: "Sodium", amount: "0 g", subheading: subheading)
            NutritionFactsSubHeading(title: "Potassium", amount: "0 g", subheading: subheading)
            }
        }
    }
}

struct NutritionFactsHeading: View {
    var title: String
    var amount: String
    var heading: Color
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .bold()
            Spacer()
            Text(amount)
                .font(.callout)
                .bold()
        }
        .padding(.horizontal, 24)
        .frame(height: 32)
        .background(heading)
        .padding(.top, 16)
    }
}

struct NutritionFactsSubHeading: View {
    var title: String
    var amount: String
    var subheading: Color
    var body: some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Text(amount)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.trailing, 24)
        .padding(.leading, 40)
        .frame(height: 32)
        .background(subheading)
    }
}
