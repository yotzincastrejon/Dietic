//
//  DietCard.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct DietCard: View {
    @ObservedObject var fastingManager: FastingManager
    @State private var hasTimeElapsed = false
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    var body: some View {
        VStack {
            Spacer()
            DietOptionsSegementedControl(dietGoal: $dietGoal, deficitLevel: $deficitLevel)
            HStack {
                VStack(alignment: .leading) {
                    
                    HStack {
                            DietCardEatenLabel(fastingManager: fastingManager, dietGoal: $dietGoal, deficitLevel: $deficitLevel)
                        //Simulation view to show what you have simulated that you've eaten.
                        if fastingManager.simulatedCaloriesBool {
                            SimulatedView(fastingManager: fastingManager)
                        }
                        
                    }
                    
                    DietCardMainLabel(barColor: .red.opacity(0.5), text: "Burned", image: "Burned", amount: $fastingManager.activeCalories)
                }
                Spacer()
                //                VStack(alignment: .leading, spacing: 4) {
                //                    Text("Daily Deficit Goal: \n-\(String(format: "%0.0f",fastingManager.dailyDeficitForGoal))")
                //                    Text("Current Deficit/Surplus: \n\(String(format: "%0.0f",fastingManager.currentDeficitForDay))")
                //                }
                //                .font(.caption2)
                //                Spacer()
                
                        
                        ProgressRingView(progress: $fastingManager.percentageAccomplished,thickness: 12, dotOnTip: false, width: 110,gradient: Gradient(colors: dietGoalColor(dietGoal, deficitLevel)),  backgroundCircleWidth: 12, backgroundCircleColor: Color(hex: "53b7db").opacity(0.1))
                            .overlay(
                                caloriesLeft(bool: hasTimeElapsed)
    
                            )
                            

                    .onTapGesture {
                        withAnimation(.spring()) {
                        fastingManager.isShowingDeficitByMass.toggle()
                        fastingManager.saveIsShowingDeficitByMass()
                        }
                }

                
                
            }
            Divider()
                .padding(.top)
            
            HStack {
                
                MacroLabel(text: "Carbs", backgroundColor: .blue.opacity(0.25), foregroundGradient: [Color.blue, Color.teal], percentage: fastingManager.carbPercentage, remaining: fastingManager.carbRemaining)
                Spacer()
                MacroLabel(text: "Protein", backgroundColor: .red.opacity(0.25), foregroundGradient: [Color.red, Color.pink], percentage: fastingManager.proteinPercentage, remaining: fastingManager.proteinRemaining)
                Spacer()
                MacroLabel(text: "Fat", backgroundColor: .yellow.opacity(0.25), foregroundGradient: [Color.yellow, Color.orange], percentage: fastingManager.fatPercentage, remaining: fastingManager.fatRemaining)
                
            }
            Spacer()
        }
        .padding()
        //        .frame(height: 236)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: dietGoalColor(dietGoal, deficitLevel), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            ))
//        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)

        
        
        
        
    }
    
//    @ViewBuilder
//    func caloriesLeft(bool: Bool) -> some View {
//        if fastingManager.leftToBurn < 0 {
//
//            VStack {
//                if hasTimeElapsed {
//                    ZStack {
//                        VStack {
//                            Text(String(format: "%0.2f", (fastingManager.leftToBurn * -1) / 3500))
//                                .font(.title)
//                                .foregroundColor(.green)
//                            Text("lbs")
//                                .font(.caption)
//                                .foregroundColor(Color(uiColor: .secondaryLabel))
//                        }
//                        .offset(x: 0, y: fastingManager.isShowingDeficitByMass ? 0 : -100)
//
//                        VStack {
//                            Text(String(format: "%0.0f", fastingManager.leftToBurn * -1))
//                                .font(.title)
//                                .foregroundColor(.green)
//                            Text("Deficit")
//                                .font(.caption)
//                                .foregroundColor(Color(uiColor: .secondaryLabel))
//                        }
//                        .offset(x: 0, y: fastingManager.isShowingDeficitByMass ? 100 : 0)
//                    }
//                    .frame(height: 100)
//                    .padding(20)
//                    .clipShape(Circle())
//
//                } else {
//                    //                Image(systemName: "checkmark.seal.fill")
//                    //                    .font(.title)
//                    //                    .foregroundColor(.green)
//                    //                Text("You did it!")
//                    //                    .font(.caption)
//                    //                    .foregroundColor(Color(uiColor: .secondaryLabel))
//                    LottieView(filename: "congrats", loopMode: .playOnce)
//                }
//            }
//            .task {
//                await delayText()
//            }
//            .animation(.easeIn, value: hasTimeElapsed)
//        } else {
//            VStack {
//                Text(String(format: "%0.0f",fastingManager.leftToBurn))
//                    .font(.title)
//                Text("kcal")
//                    .font(.caption)
//                    .foregroundColor(Color(uiColor: .secondaryLabel))
//            }
//        }
//    }

    @ViewBuilder
    func caloriesLeft(bool: Bool) -> some View {
        let calories = calculateCurrentStanding()
        if calories < 0 {

            VStack {
                if hasTimeElapsed {
                    ZStack {
                        VStack {
                            Text(String(format: "%0.2f", (calories * -1) / 3500))
                                .font(.title)
                                .foregroundColor(.green)
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .offset(x: 0, y: fastingManager.isShowingDeficitByMass ? 0 : -100)

                        VStack {
                            Text(String(format: "%0.0f", calories * -1))
                                .font(.title)
                                .foregroundColor(.green)
                            Text("Deficit")
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }
                        .offset(x: 0, y: fastingManager.isShowingDeficitByMass ? 100 : 0)
                    }
                    .frame(height: 100)
                    .padding(20)
                    .clipShape(Circle())

                } else {
                    //                Image(systemName: "checkmark.seal.fill")
                    //                    .font(.title)
                    //                    .foregroundColor(.green)
                    //                Text("You did it!")
                    //                    .font(.caption)
                    //                    .foregroundColor(Color(uiColor: .secondaryLabel))
                    LottieView(filename: "congrats", loopMode: .playOnce)
                }
            }
            .task {
                await delayText()
            }
            .animation(.easeIn, value: hasTimeElapsed)
        } else {
            VStack {
                Text(String(format: "%0.0f",calories))
                    .font(.title)
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }

    func calculateCurrentStanding() ->  Double {
        let bmr = fastingManager.bmr
        let consumedCalories = fastingManager.consumedCalories
        let activeCalories = fastingManager.activeCalories
        let totalNeededToEat = (bmr + activeCalories) * dietMultiplier(dietGoal, deficitLevel)

        return consumedCalories - totalNeededToEat
    }
    
    func delayText() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        hasTimeElapsed = true
    }

    func dietGoalColor(_ goal: DietGoal, _ level: DietDeficitLevel) -> [Color] {
        switch goal {
        case .deficit:
            switch level {
            case .light:
                return [Color(hex: "B9B7E3"), Color(hex: "FFE1E6")]
            case .normal:
                return [Color.purple, Color(hex: "7D7BDB")]
            case .aggressive:
                return [Color.purple, Color(hex: "FF4500")]
            }
        case .maintaining:
            return [Color.green, Color.mint]
        case .gain:
            return [Color.red, Color.orange]
        }
    }

    func dietMultiplier(_ goal: DietGoal, _ level: DietDeficitLevel) -> Double {
        switch goal {
        case .deficit:
            switch level {
            case .light:
                return 0.90
            case .normal:
                return 0.80
            case .aggressive:
                return 0.70
            }
        case .maintaining:
            return 1
        case .gain:
            return 1.10
        }
    }
}

struct DietCard_Previews: PreviewProvider {
    static var previews: some View {
//        DietCard(fastingManager: FastingManager())
//            .background(Color(uiColor: .systemGroupedBackground))
            
        ContentView(fastingManager: FastingManager(), dietGoal: .constant(.maintaining), deficitLevel: .constant(.normal))
    }
}




struct SimulatedView: View {
    @ObservedObject var fastingManager: FastingManager
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .frame(width: 2, height: 42)
                .foregroundColor(.teal.opacity(0.5))
            VStack(alignment: .leading, spacing: 4) {
                Text("Simulated Goal")
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(fastingManager.simulatedCalories)")
                        .font(.title2)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.leading, 2)
                }
            }
        }
    }
}
