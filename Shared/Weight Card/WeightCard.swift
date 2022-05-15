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
        
        
     
            
            
            
            VStack(spacing: 0) {
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack(alignment: .center) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%0.01f", fastingManager.weight))
                            .font(.largeTitle).monospacedDigit()
                            .fontWeight(.medium)
                        Text("lbs")
                            .font(.callout)
                    }
                    .foregroundColor(Color.indigo)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            //                            Text("\(fastingManager.sampleSourceDate.formatted(.dateTime.month().day().hour().minute()))")
                            Text("\(dateFormat(date: fastingManager.sampleSourceDate))")
                        }
                        .font(.caption2)
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                        Text(fastingManager.sampleSourceName)
                            .font(.caption2)
                            .foregroundColor(Color.indigo)
                        
                        
                    }
                }
                .padding(.top, 7)
                
                Divider()
                    .padding(.top, 16)
                
                HStack {
                    WeightCardText(topText: "\(String(format: "%0.01f", fastingManager.height)) in", bottomText: "Height")
                    Spacer()
                    WeightCardText(topText: BMICalculation(), bottomText: BMIWeightStatus())
                    Spacer()
                    WeightCardText(topText: "\(String(format: "%0.01f", fastingManager.bodyFat * 100))%", bottomText: "Body fat")
                }
                .padding(.top, 18)
                
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
            
          
        
        
        
        
    }
    
    
    func BMICalculation() -> String {
        let BMI = 703 * fastingManager.weight/(fastingManager.height * fastingManager.height)
        return "\(String(format: "%0.01f", BMI)) BMI"
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
    
    func dateFormat(date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date){
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            return df.string(from: date)
            
        }
        else if calendar.isDateInYesterday(date){
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            return df.string(from: date)
        }
        else if calendar.isDateInTomorrow(date){
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            return df.string(from: date)
        } else {
            let df = DateFormatter()
            df.dateFormat = "MMM d h:mm a"
            return df.string(from: date)
        }
        
    }
}

struct WeightCard_Previews: PreviewProvider {
    static var previews: some View {
        WeightCard(fastingManager: FastingManager())
            .frame(height: 300)
            .background(.blue)
            
        
    }
}

struct WeightCardText: View {
    let topText: String
    let bottomText: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(topText)
                .font(.callout)
            
            Text(bottomText)
                .font(.caption2)
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}
