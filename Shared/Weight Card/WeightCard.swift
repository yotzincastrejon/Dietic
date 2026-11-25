//
//  WeightCard.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct WeightCard: View {
    @ObservedObject var fastingManager: FastingManager
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body measurement").font(.system(.title2, design: .serif))
            LabeledContent("Weight") {
                Text("\(fastingManager.weight.formatted(.number.precision(.fractionLength(1)))) lb")
                    .monospacedDigit()
            }
            if fastingManager.height > 0 {
                LabeledContent("Height", value: "\(fastingManager.height.formatted()) in")
                LabeledContent("BMI", value: [BMICalculation(), BMIWeightStatus()].filter { !$0.isEmpty }.joined(separator: " · "))
            }
            if fastingManager.bodyFat > 0 {
                LabeledContent("Body fat", value: fastingManager.bodyFat.formatted(.percent.precision(.fractionLength(1))))
            }
            Text("\(fastingManager.sampleSourceName) · \(fastingManager.sampleSourceDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(WarmInk.muted)
        }
        .foregroundStyle(WarmInk.text)
    }

    func BMICalculation() -> String {
        let BMI = 703 * fastingManager.weight/(fastingManager.height * fastingManager.height)
        return "\(String(format: "%0.01f", BMI))"
    }
    
    func BMIWeightStatus() -> String {
        let BMI = 703 * fastingManager.weight/(fastingManager.height * fastingManager.height)
        //Write a switch statement that changes with bmi status
        switch BMI {
        case 18.5..<24.9:
            return "Normal"
        case 25.0..<29.9:
            return "Overweight"
        case 23.0..<34.9:
            return "Obesity Class 1"
        case 35.0..<39.9:
            return "Obesity Class 2"
        default:
            return ""
        }
        
        
    }
    
}
