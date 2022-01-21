//
//  DietCard.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct DietCard: View {
    @ObservedObject var fastingManager: FastingManager
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    DietCardMainLabel(barColor: .blue.opacity(0.5), text: "Eaten", image: "Eaten", amount: $fastingManager.consumedCalories)
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
                        caloriesLeft()
                    )
                
            }
            Divider()
                .padding(.top)
            Spacer()
            HStack {
                MacroLabel(text: "Carbs", backgroundColor: .blue.opacity(0.25), foregroundGradient: [Color.blue, Color.teal], percentage: fastingManager.carbPercentage, remaining: fastingManager.carbRemaining)
                Spacer()
                MacroLabel(text: "Protein", backgroundColor: .red.opacity(0.25), foregroundGradient: [Color.red, Color.pink], percentage: fastingManager.proteinPercentage, remaining: fastingManager.proteinRemaining)
                Spacer()
                MacroLabel(text: "Fat", backgroundColor: .yellow.opacity(0.25), foregroundGradient: [Color.yellow, Color.orange], percentage: fastingManager.fatPercentage, remaining: fastingManager.fatRemaining)
            }
        }
        .padding()
        //        .frame(height: 236)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
    
    @ViewBuilder
    func caloriesLeft() -> some View {
        if fastingManager.leftToBurn < 0 {
            VStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title)
                Text("You did it!")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
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
    
    }

struct DietCard_Previews: PreviewProvider {
    static var previews: some View {
        DietCard(fastingManager: FastingManager())
    }
}
