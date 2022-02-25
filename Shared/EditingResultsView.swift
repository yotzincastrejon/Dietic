//
//  EditingResultsView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/18/22.
//

import SwiftUI

struct EditingResultsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
//    @Binding var selection: EatingTime
    @State var selection: EatingTime = .breakfast
    @ObservedObject var fastingManager: FastingManager
    @Binding var isShowing: Bool
    @State var text = "1"
    @State var numberOfServings: Double = 1
    @State var sample: HKSampleWithDescription?
    @State var oldDate: Date?
    var body: some View {
        VStack {
            Picker("Something", selection: $selection) {
                ForEach(EatingTime.allCases, id: \.self) { value in
                    Text(value.description)
                }
            }
            .pickerStyle(.segmented)
            .onAppear {
                text = sample?.numberOfServings.description ?? 0.description
                numberOfServings = sample?.numberOfServings ?? 0
                oldDate = sample?.date ?? Date.now
                switch sample?.mealPeriod {
                    case "Breakfast":
                        selection = .breakfast
                    case "Lunch":
                        selection = .lunch
                    case "Dinner":
                        selection = .dinner
                    case "Snack":
                        selection = .snack
                    default:
                        selection = .breakfast
                }
            }
//            Spacer()
//            Text(sample?.foodName ?? "")
//            Text("Calories:\(String(sample?.calories ?? 0))cal")
            
//            Spacer()
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    HStack {
                        Text(sample?.foodName ?? "Placeholder")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                        
                    }
                    
                    HStack {
                        Text("\(Int(sample?.servingQuantity ?? 0)) \(sample?.servingUnit ?? "g")")
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
                        
//                    Text("\(String(format: "%.2f",sample?.servingQuantity ?? 0))")
                        
//                    Text("\(sample?.servingUnit ?? "")")
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
                        Text("\(Int(Double(Double(sample?.calories ?? 0 ) / numberOfServings) * Double(Double(text) ?? 0)) ) kcal")
                            .font(.callout).bold()
                        
                    }
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(sample?.totalCarbohydrate ?? 0)/numberOfServings * (Double(text) ?? 0)))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(sample?.protein ?? 0)/numberOfServings * (Double(text) ?? 0)))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(Double(sample?.totalFat ?? 0)/numberOfServings * (Double(text) ?? 0)))g")
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
                        fastingManager.deleteTheCorrelationObject(uuid: sample?.uuid ?? "")
                        presentationMode.wrappedValue.dismiss()
                        Task {
                            await fastingManager.requestAuthorization()
                        }
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
                        fastingManager.deleteTheCorrelationObject(uuid: sample?.uuid ?? "")
                        saveNewValue()
                        sample?.mealPeriod = selection.description
                        fastingManager.saveCorrelation(sample: sample!, editing: true)
                        presentationMode.wrappedValue.dismiss()
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                    }){
                        Text("Save")
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
        
        .navigationTitle("Edit Entry")
        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading){
//                Button(action: {
//                    isShowing = false
//                    fastingManager.currentScannedItem = nil
//                }){
//                    Text("Cancel")
//
//                }
//
//            }
            
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    //We'll have to manually adjust every single nutrient by either multiplying by number of servings or the number of grams.
////                    sample?.calories = Int(Double(sample?.calories ?? 0) * (Double(text) ?? 0))
//
//                    saveNewValue()
//
//                    sample?.mealPeriod = selection.description
//                    fastingManager.saveCorrelation(sample: sample!)
//                    Task {
//                        await fastingManager.requestAuthorization()
//                    }
//                    isShowing = false
//                }){
//                    Text("Add").bold()
//                }
//
//            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func saveNewValue() {
        sample?.calories = Double(Double(sample?.calories ?? 0)/numberOfServings) * (Double(text) ?? 0)
        sample?.sugars = (sample?.sugars ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.totalFat = Double(sample?.totalFat ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.saturatedFat = (sample?.saturatedFat ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.cholesterol = Double(sample?.cholesterol ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.sodium = Double(sample?.sodium ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.totalCarbohydrate = Double(sample?.totalCarbohydrate ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.dietaryFiber = Double(sample?.dietaryFiber ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.protein = Double(sample?.protein ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.potassium = Double(sample?.potassium ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.calcium = Double(sample?.calcium ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.iron = Double(sample?.iron ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.monounsaturatedFat = Double(sample?.monounsaturatedFat ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.polyunsaturatedFat = Double(sample?.polyunsaturatedFat ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.caffeine = Double(sample?.caffeine ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.copper = Double(sample?.copper ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.folate = Double(sample?.folate ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.magnesium = Double(sample?.magnesium ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.manganese = Double(sample?.manganese ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.niacin = Double(sample?.niacin ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.phosphorus = Double(sample?.phosphorus ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.riboflavin = Double(sample?.riboflavin ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.selenium = Double(sample?.selenium ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.thiamin = Double(sample?.thiamin ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminA = Double(sample?.vitaminA ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminC = Double(sample?.vitaminC ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminB6 = Double(sample?.vitaminB6 ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminB12 = Double(sample?.vitaminB12 ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminD = Double(sample?.vitaminD ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminE = Double(sample?.vitaminE ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.vitaminK = Double(sample?.vitaminK ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.zinc = Double(sample?.zinc ?? 0)/numberOfServings * (Double(text) ?? 0)
        sample?.numberOfServings = (Double(text) ?? 0)
        sample?.uuid = UUID().uuidString
        sample?.date = oldDate ?? Date.now
    }
    
    
}

struct EditingResultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditingResultsView(fastingManager: FastingManager(), isShowing: .constant(true), sample: HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()))
        }
    }
}
