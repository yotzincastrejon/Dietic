//
//  JsonResponseView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/9/22.
//

import SwiftUI

struct JsonResponseView: View {
    @Binding var isShowing: Bool
    @ObservedObject var fastingManager: FastingManager
    @State var selection = EatingTime.breakfast
    var body: some View {
        NavigationView {
           
            if fastingManager.currentScannedItem != nil {
                AddingFromJSONResultView(selection: $selection, fastingManager: fastingManager, isShowing: $isShowing)
            } else {
                ProgressView()
            }
        }
    }
}

struct JsonResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            JsonResponseView(isShowing: Binding.constant(true), fastingManager: FastingManager())
            AddingFromJSONResultView(selection: Binding.constant(.breakfast), fastingManager: FastingManager(), isShowing: Binding.constant(true))
            AddingFromJSONResultView(selection: Binding.constant(.breakfast), fastingManager: FastingManager(), isShowing: Binding.constant(true))
                .preferredColorScheme(.dark)

//            JsonResponseView(isShowing: Binding.constant(true), fastingManager: FastingManager())
//                .preferredColorScheme(.dark)
        }
    }
}

struct AddingFromJSONResultView: View {
    @Binding var selection: EatingTime
    @ObservedObject var fastingManager: FastingManager
    @Binding var isShowing: Bool
    @State var text = "1"
    @State var numberOfServings = 1
    var body: some View {
        VStack {
            Picker("Something", selection: $selection) {
                ForEach(EatingTime.allCases, id: \.self) { value in
                    Text(value.description)
                }
            }
            .pickerStyle(.segmented)
//            Spacer()
//            Text(fastingManager.currentScannedItem?.foodName ?? "")
//            Text("Calories:\(String(fastingManager.currentScannedItem?.calories ?? 0))cal")
            
//            Spacer()
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    HStack {
                        Text(fastingManager.currentScannedItem?.foodName ?? "Placeholder")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(Int(fastingManager.currentScannedItem?.servingQuantity ?? 0)) \(fastingManager.currentScannedItem?.servingUnit ?? "g")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                HStack(spacing: 15) {
                    Text("Number of Servings")
                    TextField("Text", text: $text)
                        .padding(.leading)
                        .frame(width: 105, height: 44)
                        .background(Capsule().stroke())
                        .keyboardType(.decimalPad)
                    Spacer()
                        
//                    Text("\(String(format: "%.2f",fastingManager.currentScannedItem?.servingQuantity ?? 0))")
                        
//                    Text("\(fastingManager.currentScannedItem?.servingUnit ?? "")")
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 44)
//                        .background(Capsule().stroke())
                }
                .padding(.top, 40)
                Divider()
                    .padding(.top, 24)
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(Double(fastingManager.currentScannedItem?.calories ?? 0) * Double(Double(text) ?? 0)) ) kcal")
                            .font(.callout).bold()
                        
                    }
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(fastingManager.currentScannedItem?.totalCarbohydrate ?? 0) * (Double(text) ?? 0)))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(fastingManager.currentScannedItem?.protein ?? 0) * (Double(text) ?? 0)))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(fastingManager.currentScannedItem?.totalFat ?? 0) * (Double(text) ?? 0)))g")
                                .font(.callout)
                        }
                        Spacer()
                    }
                }
                .padding(.top, 24)
                
                Text("This fruit provides health benefits, high in monounsaturated fat - a \"good\" fat and fiber, that can help you to feel fuller and more satisfied")
                    .padding(16)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .frame(height: 66)
                    .frame(maxWidth: .infinity)
                    .background(Color("B40"))
                    .cornerRadius(8)
                    .padding(.top, 24)
                
                
                HStack(spacing: 15) {
                    Button(action: {
                        
                    }){
                        Text("Delete")
                            .fontWeight(.medium)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 48)
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                    .tint(.pink)
                    .background(Capsule().stroke().foregroundColor(.pink))
                    
                    
                    Button(action: {
                        
                    }){
                        Text("Add")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color("B10"),Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                    }
                    
                    
                }
                .padding(.top, 33)
                
            }
            .padding(.horizontal)
            Spacer()
            
            
        }
        
        .navigationTitle("We fucking did it!")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading){
                Button(action: {
                    isShowing = false
                    fastingManager.currentScannedItem = nil
                }){
                    Text("Cancel")
                    
                }
                
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    //We'll have to manually adjust every single nutrient by either multiplying by number of servings or the number of grams.
//                    fastingManager.currentScannedItem?.calories = Int(Double(fastingManager.currentScannedItem?.calories ?? 0) * (Double(text) ?? 0))
                    
                    saveNewValue()
                    
                    fastingManager.currentScannedItem?.mealPeriod = selection.description
                    fastingManager.saveCorrelation(sample: fastingManager.currentScannedItem!)
                    Task {
                        await fastingManager.requestAuthorization()
                    }
                    isShowing = false
                }){
                    Text("Add").bold()
                }
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func saveNewValue() {
        fastingManager.currentScannedItem?.calories = Int(Double(fastingManager.currentScannedItem?.calories ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.sugars = (fastingManager.currentScannedItem?.sugars ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.totalFat = Double(fastingManager.currentScannedItem?.totalFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.saturatedFat = (fastingManager.currentScannedItem?.saturatedFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.cholesterol = Int(Double(fastingManager.currentScannedItem?.cholesterol ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.sodium = Int(Double(fastingManager.currentScannedItem?.sodium ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.totalCarbohydrate = Int(Double(fastingManager.currentScannedItem?.totalCarbohydrate ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.dietaryFiber = Int(Double(fastingManager.currentScannedItem?.dietaryFiber ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.protein = Int(Double(fastingManager.currentScannedItem?.protein ?? 0) * (Double(text) ?? 0))
        fastingManager.currentScannedItem?.potassium = Int(Double(fastingManager.currentScannedItem?.potassium ?? 0) * (Double(text) ?? 0))
    }
    
    
}
