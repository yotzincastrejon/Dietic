//
//  GoalSettings.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct GoalSettings: View {
    @ObservedObject var fastingManager: FastingManager
    @State private var progress = 0.0
    @State var showProgressView = false
    @State var everythingwasSaved = false
    @FocusState var weightIsFocused: Bool
    @FocusState var bodyFatisFocused: Bool
    @FocusState private var focusedField: Field?
    
    enum Field {
        case goalWeight
        case goalBodyFatPercentage
    }
    var body: some View {
        VStack {
            Toggle("Simulate Calories", isOn: $fastingManager.simulatedCaloriesBool)
            if fastingManager.simulatedCaloriesBool {
            HStack {
                Text("Simulated Calories")
                Spacer()
                TextField("Simulated Calories", value: $fastingManager.simulatedCalories, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                .padding()
            .keyboardType(.numberPad)
            }
            }
//            Text("\(fastingManager.futureDate)")
            DatePicker(
                    "Goal Date",
                    selection: $fastingManager.futureDate,
                    displayedComponents: [.date]
                )
//            TextField("Goal Weight", text: $fastingManager.goalWeight)
//                .keyboardType(.decimalPad)
            VStack {
            HStack {
                Text("Goal Weight")
                Spacer()
                TextField("Goal Weight", value: $fastingManager.goalWeight, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                .padding()
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .goalWeight)
                .submitLabel(.next)
            }
            
            HStack {
                Text("Goal Body Fat Percentage")
                Spacer()
                HStack(spacing: 0) {
                TextField("Goal", value: $fastingManager.goalBodyFatPercentage, format: .number)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .goalBodyFatPercentage)
                .submitLabel(.done)
                Text("%")
                }
            }
            }
            .onSubmit {
                switch focusedField {
                case .goalWeight:
                    focusedField = .goalBodyFatPercentage
                default:
                    print("Finished")
                }
            }
            
            HStack {
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    everythingwasSaved = false
                    showProgressView = true
                    fastingManager.saveNewFutureDate()
                    progress += 0.33
                    fastingManager.saveGoalWeight()
                    progress += 0.33
                    fastingManager.saveGoalBodyFat()
                    progress += 0.34
                    showProgressView = false
                    everythingwasSaved = true
                }) {
                    Text("Save")
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.regular)
            .tint(.green)
            .onAppear {
                everythingwasSaved = false
            }
                if everythingwasSaved {
                HStack {
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    .font(.largeTitle)
                    Text("Saved!")
                        .font(.headline)
                }
                }
            }
            if showProgressView {
            ProgressView(value: progress)
                .tint(.green)
                .animation(.default, value: progress)
            }
            
            
        }
    }
}

struct GoalSettings_Previews: PreviewProvider {
    static var previews: some View {
        GoalSettings(fastingManager: FastingManager())
    }
}
