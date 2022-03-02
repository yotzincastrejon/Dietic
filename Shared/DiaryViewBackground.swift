//
//  DiaryView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/10/22.
//

import SwiftUI

struct DiaryViewBackground: View {
    @ObservedObject var fastingManager: FastingManager
    @State var mealPeriod: EatingTime
    @State var resize = false
    var body: some View {
        GeometryReader { g in
            ZStack {
                ZStack {
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [Color("B10"), Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: g.size.height / 2.5)
                        Spacer()
                    }
                    VStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [Color("B00").opacity(0), Color(#colorLiteral(red: 0, green: 0.02745098039, blue: 0.1647058824, alpha: 1))], startPoint: .center, endPoint: .bottom)).opacity(0.5)
                            .frame(height: g.size.height / 2.5)
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
                        .frame(height: g.size.height / 2.5)
                        Spacer()
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    DiaryView(fastingManager: fastingManager, mealPeriod: mealPeriod)
                        .frame(height: g.size.height / 1.1)
                    
                }
            }
        }
        
    }
}

struct DiaryViewBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DiaryViewBackground(fastingManager: FastingManager(), mealPeriod: .lunch)
            }
            DiaryViewBackground(fastingManager: FastingManager(), mealPeriod: .lunch)
                .preferredColorScheme(.dark)
            //            DiaryView()
            //                .preferredColorScheme(.dark)
        }
    }
}

struct DiaryView: View {
    let strings: [String] = ["Salmon", "Mixed Veggies", "Avocado"]
    @ObservedObject var fastingManager: FastingManager
    @State var mealPeriod: EatingTime
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
                                    Text(mealPeriod.description)
                                        .font(.largeTitle)
                                        .bold()
                                    Text(fastingManager.todaysDate.formatted(.dateTime.month(.wide).day()))
                                    
                                }
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.subheadline)
                                    HStack(alignment: .firstTextBaseline,spacing: 2) {
                                        Text("\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.calories }.reduce(0, +)))").monospacedDigit()
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
                                ForEach(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }) { sample in
                                    //                            VStack {
                                    //                                HStack {
                                    //                                    VStack(alignment: .leading) {
                                    //                                        Text(item)
                                    //                                        .font(.subheadline)
                                    //                                        .fontWeight(.semibold)
                                    //                                        Text("Toasted • 100g")
                                    //                                            .font(.caption2)
                                    //                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    //                                    }
                                    //                                    Spacer()
                                    //                                    Text("540 kcal")
                                    //                                        .font(.subheadline)
                                    //                                        .foregroundColor(Color("B10"))
                                    //                                }
                                    //
                                    //                            }
                                    NavigationLink(destination: EditingResultsView(fastingManager: fastingManager, isShowing: .constant(false), sample: sample)) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(sample.foodName)")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text("\(sample.brandName)")
                                                    .font(.caption2)
                                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                                            }
                                            Spacer()
                                            Text("\(Int(sample.calories)) kcal")
                                                .font(.subheadline)
                                                .foregroundColor(Color("B10"))
                                            
                                        }
                                    }
                                    
                                }
                                .onDelete(perform: delete)
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
                            
                            NutritionFacts(fastingManager: fastingManager, mealPeriod: mealPeriod)
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
    
    func delete(at offsets: IndexSet) {
        print("Deleting sample")
        let index = offsets.first
        fastingManager.deleteTheCorrelationObject(uuid: fastingManager.theSamples[index!].meta)
        //        healthkitManager.correlationArray.remove(atOffsets: offsets)
        //        healthkitManager.deleteIT(uuid: healthkitManager.theSamples[index!].meta["HKMetadataKeySyncIdentifier"] as! String)
        fastingManager.theSamples.remove(atOffsets: offsets)
        Task {
            await fastingManager.requestAuthorization()
        }
    }
}

struct NutritionFacts: View {
    var heading: Color = Color(uiColor: .systemGray4)
    var subheading: Color = Color(uiColor: .secondarySystemBackground)
    @ObservedObject var fastingManager: FastingManager
    @State var mealPeriod: EatingTime
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nutrition facts: \(mealPeriod.description)")
                    .fontWeight(.medium)
                Spacer()
            }
            NutritionFactsHeading(title: "Energy", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.calories }.reduce(0, +))) kcal", heading: heading)
            
            Group {
                NutritionFactsHeading(title: "Fat", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.totalFat }.reduce(0, +))) g", heading: heading)
                NutritionFactsSubHeading(title: "Saturated fat", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.saturatedFat }.reduce(0, +))) g", subheading: subheading)
                NutritionFactsSubHeading(title: "Monounsaturated fat", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.monounsaturatedFat }.reduce(0, +))) g", subheading: subheading)
                NutritionFactsSubHeading(title: "Polyunsaturated fat", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.polyunsaturatedFat }.reduce(0, +))) g", subheading: subheading)
            }
            NutritionFactsHeading(title: "Protein", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.protein }.reduce(0, +))) g", heading: heading)
            
            Group {
                NutritionFactsHeading(title: "Carbs", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.totalCarbohydrate }.reduce(0, +))) g", heading: heading)
                NutritionFactsSubHeading(title: "Dietary Fiber", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.dietaryFiber }.reduce(0, +))) g", subheading: subheading)
                NutritionFactsSubHeading(title: "Sugar", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.sugars }.reduce(0, +))) g", subheading: subheading)
            }
            
            Group {
                NutritionFactsHeading(title: "Other", amount: "", heading: heading)
                NutritionFactsSubHeading(title: "Cholesterol", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.cholesterol }.reduce(0, +))) mg", subheading: subheading)
                NutritionFactsSubHeading(title: "Sodium", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.sodium }.reduce(0, +))) mg", subheading: subheading)
                NutritionFactsSubHeading(title: "Potassium", amount: "\(Int(fastingManager.theSamples.filter { $0.mealPeriod == mealPeriod.description }.map { $0.potassium }.reduce(0, +))) mg", subheading: subheading)
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
