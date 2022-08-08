//
//  DietCardEatenLabel.swift
//  Dietic (iOS)
//
//  Created by Yotzin Castrejon on 8/7/22.
//

import SwiftUI

struct DietCardEatenLabel: View {
    @ObservedObject var fastingManager: FastingManager
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
                    Text(String(format: "%0.0f", goalBMR()))
                        .font(.title2)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        .padding(.leading, 2)
                    
                }
            }
        }
    }
    func goalBMR() -> Double {
        let goal = fastingManager.BMR(age: fastingManager.age, weightinPounds: 160, heightinInches: fastingManager.height)
        return goal
    }
}


struct DietCardEatenLabel_Previews: PreviewProvider {
    static var previews: some View {
        DietCardEatenLabel(fastingManager: FastingManager())
    }
}

