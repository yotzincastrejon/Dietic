//
//  JsonResponseView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/9/22.
//

import SwiftUI
import CoreData

struct JsonResponseView: View {
    @Binding var isShowing: Bool
    @ObservedObject var fastingManager: FastingManager
    var sample: HKSampleWithDescription
    var body: some View {
        NavigationView {
           
            if fastingManager.currentScannedItem != nil {
                AddingFromJSONResultView(fastingManager: fastingManager, isShowing: $isShowing, sample: sample)
            } else {
                ProgressView()
                    .alert(isPresented: $fastingManager.itemIsMissingBool) {
                        Alert(title: Text("Error"), message: Text("The item that you've scanned doesn't exist in our database, sorry!🥺 "), dismissButton: .default(Text("Got it!"), action: {
                            isShowing = false
                            print("Cancelled")
                        }))
                        
                    }
            }
        }
        
    }
}

struct JsonResponseView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            JsonResponseView(isShowing: Binding.constant(true), fastingManager: FastingManager())
            NavigationView {
                AddingFromJSONResultView(fastingManager: FastingManager(), isShowing: Binding.constant(true), sample: HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()))
            }
            NavigationView {
                AddingFromJSONResultView(fastingManager: FastingManager(), isShowing: Binding.constant(true), sample: HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()))
                    .preferredColorScheme(.dark)
            }

//            JsonResponseView(isShowing: Binding.constant(true), fastingManager: FastingManager())
//                .preferredColorScheme(.dark)
        }
    }
}



struct AddingFromJSONResultView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var selection = EatingTime.breakfast
    @State var servingTypeSelection = ServingType.serving
    @ObservedObject var fastingManager: FastingManager
    @Binding var isShowing: Bool
    @State var text = "1"
    @State var numberOfServings = 1
    var sample: HKSampleWithDescription
    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                ForEach(EatingTime.allCases, id: \.self) { value in
                    Text(value.description)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
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
                        Text("Serving size: \(Int(fastingManager.currentScannedItem?.servingQuantity ?? 0)) \(fastingManager.currentScannedItem?.servingUnit ?? "g")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if fastingManager.currentScannedItem?.servingWeightGrams != 0 {
                    HStack {
                        Text("Serving weight in grams: \(Int(fastingManager.currentScannedItem?.servingWeightGrams ?? 0))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    }
                }
                
                if fastingManager.currentScannedItem?.servingWeightGrams != 0 {
                Picker("", selection: $servingTypeSelection) {
                    ForEach(ServingType.allCases, id: \.self) { value in
                        Text(value.description)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.top)
                }
                
                HStack(spacing: 15) {
                    if servingTypeSelection == .serving {
                    Text("Number of Servings")
                    } else {
                        Text("Number of grams")
                    }
                    TextField("Text", text: $text)
                        .padding(.leading)
                        .frame(width: 105, height: 44)
                        .background(Capsule().stroke())
                        .keyboardType(.decimalPad)
                    Spacer()
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
                        Text("\(nutrientCalculation(mainNumber:fastingManager.currentScannedItem?.calories ?? 0)) kcal")
                            .font(.callout).bold()
                        
                    }
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:fastingManager.currentScannedItem?.totalCarbohydrate ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:fastingManager.currentScannedItem?.protein ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
//                            Text("\(Int(Double(fastingManager.currentScannedItem?.totalFat ?? 0) * (Double(text) ?? 0)))g")
//                                .font(.callout)
                            Text("\(nutrientCalculation(mainNumber:fastingManager.currentScannedItem?.totalFat ?? 0))g")
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
                        isShowing = false
                        fastingManager.currentScannedItem = nil
                        fastingManager.currentScannedItemJSON = nil
                    }){
                        Text("Cancel")
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
                        addItemToCoreData()
                        saveNewValue()
                        fastingManager.saveCorrelation(sample: fastingManager.currentScannedItem!, editing: false)
                        
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                        isShowing = false
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
        
        .navigationTitle("Adding Food")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func nutrientCalculation(mainNumber: Double) -> String {
        if servingTypeSelection == .serving {
            return String(Int(Double(mainNumber) * Double(Double(text) ?? 0)))
        } else {
            return String(Int(Double(mainNumber)/(fastingManager.currentScannedItem?.servingWeightGrams ?? 1) * Double(Double(text) ?? 0)))
        }
    }
    
    func saveNewValue() {
        if servingTypeSelection == .serving {
        fastingManager.currentScannedItem?.calories = Double(fastingManager.currentScannedItem?.calories ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.sugars = (fastingManager.currentScannedItem?.sugars ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.totalFat = Double(fastingManager.currentScannedItem?.totalFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.saturatedFat = (fastingManager.currentScannedItem?.saturatedFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.cholesterol = Double(fastingManager.currentScannedItem?.cholesterol ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.sodium = Double(fastingManager.currentScannedItem?.sodium ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.totalCarbohydrate = Double(fastingManager.currentScannedItem?.totalCarbohydrate ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.dietaryFiber = Double(fastingManager.currentScannedItem?.dietaryFiber ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.protein = Double(fastingManager.currentScannedItem?.protein ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.potassium = Double(fastingManager.currentScannedItem?.potassium ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.calcium = Double(fastingManager.currentScannedItem?.calcium ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.iron = Double(fastingManager.currentScannedItem?.iron ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.monounsaturatedFat = Double(fastingManager.currentScannedItem?.monounsaturatedFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.polyunsaturatedFat = Double(fastingManager.currentScannedItem?.polyunsaturatedFat ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.caffeine = Double(fastingManager.currentScannedItem?.caffeine ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.copper = Double(fastingManager.currentScannedItem?.copper ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.folate = Double(fastingManager.currentScannedItem?.folate ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.magnesium = Double(fastingManager.currentScannedItem?.magnesium ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.manganese = Double(fastingManager.currentScannedItem?.manganese ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.niacin = Double(fastingManager.currentScannedItem?.niacin ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.phosphorus = Double(fastingManager.currentScannedItem?.phosphorus ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.riboflavin = Double(fastingManager.currentScannedItem?.riboflavin ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.selenium = Double(fastingManager.currentScannedItem?.selenium ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.thiamin = Double(fastingManager.currentScannedItem?.thiamin ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminA = Double(fastingManager.currentScannedItem?.vitaminA ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminC = Double(fastingManager.currentScannedItem?.vitaminC ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminB6 = Double(fastingManager.currentScannedItem?.vitaminB6 ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminB12 = Double(fastingManager.currentScannedItem?.vitaminB12 ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminD = Double(fastingManager.currentScannedItem?.vitaminD ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminE = Double(fastingManager.currentScannedItem?.vitaminE ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.vitaminK = Double(fastingManager.currentScannedItem?.vitaminK ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.zinc = Double(fastingManager.currentScannedItem?.zinc ?? 0) * (Double(text) ?? 0)
        fastingManager.currentScannedItem?.numberOfServings = (Double(text) ?? 0)
        fastingManager.currentScannedItem?.servingSelection = servingTypeSelection.description
        fastingManager.currentScannedItem?.mealPeriod = selection.description
        } else {
            let servingWeightGrams = fastingManager.currentScannedItem?.servingWeightGrams
            fastingManager.currentScannedItem?.calories = Double(fastingManager.currentScannedItem?.calories ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.sugars = (fastingManager.currentScannedItem?.sugars ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.totalFat = Double(fastingManager.currentScannedItem?.totalFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.saturatedFat = (fastingManager.currentScannedItem?.saturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.cholesterol = Double(fastingManager.currentScannedItem?.cholesterol ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.sodium = Double(fastingManager.currentScannedItem?.sodium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.totalCarbohydrate = Double(fastingManager.currentScannedItem?.totalCarbohydrate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.dietaryFiber = Double(fastingManager.currentScannedItem?.dietaryFiber ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.protein = Double(fastingManager.currentScannedItem?.protein ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.potassium = Double(fastingManager.currentScannedItem?.potassium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.calcium = Double(fastingManager.currentScannedItem?.calcium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.iron = Double(fastingManager.currentScannedItem?.iron ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.monounsaturatedFat = Double(fastingManager.currentScannedItem?.monounsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.polyunsaturatedFat = Double(fastingManager.currentScannedItem?.polyunsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.caffeine = Double(fastingManager.currentScannedItem?.caffeine ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.copper = Double(fastingManager.currentScannedItem?.copper ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.folate = Double(fastingManager.currentScannedItem?.folate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.magnesium = Double(fastingManager.currentScannedItem?.magnesium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.manganese = Double(fastingManager.currentScannedItem?.manganese ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.niacin = Double(fastingManager.currentScannedItem?.niacin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.phosphorus = Double(fastingManager.currentScannedItem?.phosphorus ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.riboflavin = Double(fastingManager.currentScannedItem?.riboflavin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.selenium = Double(fastingManager.currentScannedItem?.selenium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.thiamin = Double(fastingManager.currentScannedItem?.thiamin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminA = Double(fastingManager.currentScannedItem?.vitaminA ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminC = Double(fastingManager.currentScannedItem?.vitaminC ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminB6 = Double(fastingManager.currentScannedItem?.vitaminB6 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminB12 = Double(fastingManager.currentScannedItem?.vitaminB12 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminD = Double(fastingManager.currentScannedItem?.vitaminD ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminE = Double(fastingManager.currentScannedItem?.vitaminE ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.vitaminK = Double(fastingManager.currentScannedItem?.vitaminK ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.zinc = Double(fastingManager.currentScannedItem?.zinc ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            fastingManager.currentScannedItem?.numberOfServings = (Double(text) ?? 0)
            fastingManager.currentScannedItem?.servingSelection = servingTypeSelection.description
            fastingManager.currentScannedItem?.mealPeriod = selection.description
        }
    }
    private func addItemToCoreData() {
        withAnimation {
            let newItem = SearchedFoods(context: viewContext)
            newItem.timestamp = Date()
            newItem.name = fastingManager.currentScannedItem?.foodName
            newItem.brandName = fastingManager.currentScannedItem?.brandName
            newItem.calories = fastingManager.currentScannedItem?.calories ?? 0
            newItem.jsonData = fastingManager.currentScannedItemJSON
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
