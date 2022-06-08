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
    var body: some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    
                    HStack {
                        DietCardMainLabel(barColor: .blue.opacity(0.5), text: "Eaten", image: "Eaten", amount: $fastingManager.consumedCalories)
                        
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
                
                ProgressRingView(progress: $fastingManager.percentageAccomplished,thickness: 12, dotOnTip: false, width: 110,gradient: Gradient(colors: [Color(hex: "53b7db"),Color(hex: "75f9d1")]),  backgroundCircleWidth: 12, backgroundCircleColor: Color(hex: "53b7db").opacity(0.1))
                    .overlay(
                        caloriesLeft(bool: hasTimeElapsed)
                            
                    )
                    .onTapGesture {
                        fastingManager.isShowingDeficitByMass.toggle()
                        fastingManager.saveIsShowingDeficitByMass()
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
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        
        
        
        
    }
    
    @ViewBuilder
    func caloriesLeft(bool: Bool) -> some View {
        if fastingManager.leftToBurn < 0 {
            
            VStack {
                if hasTimeElapsed {
                    if fastingManager.isShowingDeficitByMass {
                        Text(String(format: "%0.2f", (fastingManager.leftToBurn * -1) / 3500))
                            .font(.title)
                            .foregroundColor(.green)
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    } else {
                    Text(String(format: "%0.0f", fastingManager.leftToBurn * -1))
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Deficit")
                        .font(.caption)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
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
                Text(String(format: "%0.0f",fastingManager.leftToBurn))
                    .font(.title)
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
    }
    
    
    func delayText() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        hasTimeElapsed = true
    }
    
}

struct DietCard_Previews: PreviewProvider {
    static var previews: some View {
        DietCard(fastingManager: FastingManager())
        ContentView(fastingManager: FastingManager())
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
