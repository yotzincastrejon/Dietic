//
//  DietCardEatenLabel.swift
//  Dietic (iOS)
//
//  Created by Yotzin Castrejon on 8/7/22.
//

import SwiftUI

struct DietCardEatenLabel: View {
    @ObservedObject var fastingManager: FastingManager
    @State var isOnTrack: Bool = true
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .frame(width: 2, height: 42)
                .foregroundColor(.blue.opacity(0.5))
            VStack(alignment: .leading, spacing: 4) {
                Text("Eaten")
                    .font(.subheadline)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Image("Eaten")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, 8)
                    Text(String(format: "%0.0f", fastingManager.consumedCalories))
                        .font(.title2)
                    Text("/")
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Text(String(format: "%0.0f", calculateCurrentNeedToEat()))
                        .font(.title2)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.leading, 2)
                    
                }
            }
//            VStack {
//                
//                Text(String(format: "%0.0f", remainingCalories()))
//                    .font(.caption)
//                .foregroundColor(isOnTrack ? .green : .red)
//                .onChange(of: fastingManager.consumedCalories) { newValue in
//                    let goal = goalBMR()
//                    let eaten = fastingManager.consumedCalories
//                    let remainingCalories = goal - eaten
//                    
//                    if remainingCalories < 0 {
//                        //change color to red and make the number positive
//                        isOnTrack = false
//                    }
//                    if remainingCalories >= 0 && isOnTrack == false {
//                        isOnTrack = true
//                    }
//                }
//            }
        }
    }
    func goalBMR() -> Double {
        let goal = fastingManager.BMR(age: fastingManager.age, weightinPounds: 160, heightinInches: fastingManager.height)
        return goal
    }
    
    func remainingCalories() -> Double {
        let goal = goalBMR()
        let eaten = fastingManager.consumedCalories
        let remainingCalories = goal - eaten
        
        if remainingCalories < 0 {
            //change color to red and make the number positive
            return remainingCalories * -1
        }
        return remainingCalories
    }

    func calculateCurrentNeedToEat() ->  Double {
        let bmr = fastingManager.bmr
        let consumedCalories = fastingManager.consumedCalories
        let activeCalories = fastingManager.activeCalories
        return (bmr + activeCalories) * dietMultiplier(dietGoal, deficitLevel)
    }

    func dietMultiplier(_ goal: DietGoal, _ level: DietDeficitLevel) -> Double {
        switch goal {
        case .deficit(_):
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


struct DietCardEatenLabel_Previews: PreviewProvider {
    static var previews: some View {
        DietCardEatenLabel(fastingManager: FastingManager(), dietGoal: .constant(.maintaining), deficitLevel: .constant(.normal))
    }
}

