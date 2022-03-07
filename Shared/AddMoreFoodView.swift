//
//  AddMoreFoodView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/4/22.
//

import SwiftUI

struct AddMoreFoodView: View {
    @ObservedObject var fastingManager: FastingManager
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SearchedFoods.timestamp, ascending: false)],
                  animation: .default)
    private var items: FetchedResults<SearchedFoods>
    @State var mealPeriod: EatingTime
    @State var topHeaderColors: [Color]
    @Binding var rootIsActive: Bool
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            VStack {
                RoundedCorners(color: topHeaderColors, tl: 0, tr: 0, bl: 64, br: 0, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 180)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack {
                // MARK: - History
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: AddingFromCoreData(fastingManager: fastingManager, sample: fastingManager.decodeJsonFromCoreData(data: item.jsonData!), shouldPopToRootView: $rootIsActive)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(item.name ?? "No Name")")
                                    .font(.subheadline)
                                .fontWeight(.semibold)
                                Text("\(item.brandName ??  "No brand")")
                                    .font(.caption2)
                                    .foregroundColor(Color(uiColor: .secondaryLabel))
                            }
                            Spacer()
                            Text("\(Int(item.calories)) kcal")
                                .font(.subheadline)
                                .foregroundColor(Color("B10"))

                        }
                        }
                        .isDetailLink(false)
                                            }
                    .onDelete(perform: deleteItems)

                }
                .padding(.top, 200)
            }
            .navigationTitle(mealPeriod.description)
        .navigationBarTitleDisplayMode(.inline)
        }
    }

    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
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

struct AddMoreFoodView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
        NavigationView {
            AddMoreFoodView(fastingManager: FastingManager(), mealPeriod: .breakfast, topHeaderColors: [Color("B10"), Color("B00")], rootIsActive: Binding.constant(false))
            
        }
        NavigationView{
            AddingFromCoreData(fastingManager: FastingManager(), sample: HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()), shouldPopToRootView: Binding.constant(false))
        }
        }
        
    }
}


struct AddingFromCoreData: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State var selection = EatingTime.breakfast
    @State var servingTypeSelection = ServingType.serving
    @ObservedObject var fastingManager: FastingManager
    @State var text = "1"
    @State var numberOfServings = 1
    @State var sample: HKSampleWithDescription?
    @Binding var shouldPopToRootView: Bool
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
                        Text("Serving size: \(Int(sample?.servingQuantity ?? 0)) \(sample?.servingUnit ?? "g")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if sample?.servingWeightGrams != 0 {
                    HStack {
                        Text("Serving weight in grams: \(Int(sample?.servingWeightGrams ?? 0))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    }
                }
                
                if sample?.servingWeightGrams != 0 {
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
                        Text("\(nutrientCalculation(mainNumber:sample?.calories ?? 0)) kcal")
                            .font(.callout).bold()
                        
                    }
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:sample?.totalCarbohydrate ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:sample?.protein ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
//                            Text("\(Int(Double(sample?.totalFat ?? 0) * (Double(text) ?? 0)))g")
//                                .font(.callout)
                            Text("\(nutrientCalculation(mainNumber:sample?.totalFat ?? 0))g")
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
                        fastingManager.currentScannedItem = nil
                        fastingManager.currentScannedItemJSON = nil
                        dismiss()
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
                        saveNewValue()
                        fastingManager.saveCorrelation(sample: sample!, editing: false)
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                        shouldPopToRootView = false
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
            return String(Int(Double(mainNumber)/(sample?.servingWeightGrams ?? 1) * Double(Double(text) ?? 0)))
        }
    }
    
    func saveNewValue() {
        if servingTypeSelection == .serving {
            sample?.calories = Double(sample?.calories ?? 0) * (Double(text) ?? 0)
        sample?.sugars = (sample?.sugars ?? 0) * (Double(text) ?? 0)
        sample?.totalFat = Double(sample?.totalFat ?? 0) * (Double(text) ?? 0)
        sample?.saturatedFat = (sample?.saturatedFat ?? 0) * (Double(text) ?? 0)
        sample?.cholesterol = Double(sample?.cholesterol ?? 0) * (Double(text) ?? 0)
        sample?.sodium = Double(sample?.sodium ?? 0) * (Double(text) ?? 0)
        sample?.totalCarbohydrate = Double(sample?.totalCarbohydrate ?? 0) * (Double(text) ?? 0)
        sample?.dietaryFiber = Double(sample?.dietaryFiber ?? 0) * (Double(text) ?? 0)
        sample?.protein = Double(sample?.protein ?? 0) * (Double(text) ?? 0)
        sample?.potassium = Double(sample?.potassium ?? 0) * (Double(text) ?? 0)
        sample?.calcium = Double(sample?.calcium ?? 0) * (Double(text) ?? 0)
        sample?.iron = Double(sample?.iron ?? 0) * (Double(text) ?? 0)
        sample?.monounsaturatedFat = Double(sample?.monounsaturatedFat ?? 0) * (Double(text) ?? 0)
        sample?.polyunsaturatedFat = Double(sample?.polyunsaturatedFat ?? 0) * (Double(text) ?? 0)
        sample?.caffeine = Double(sample?.caffeine ?? 0) * (Double(text) ?? 0)
        sample?.copper = Double(sample?.copper ?? 0) * (Double(text) ?? 0)
        sample?.folate = Double(sample?.folate ?? 0) * (Double(text) ?? 0)
        sample?.magnesium = Double(sample?.magnesium ?? 0) * (Double(text) ?? 0)
        sample?.manganese = Double(sample?.manganese ?? 0) * (Double(text) ?? 0)
        sample?.niacin = Double(sample?.niacin ?? 0) * (Double(text) ?? 0)
        sample?.phosphorus = Double(sample?.phosphorus ?? 0) * (Double(text) ?? 0)
        sample?.riboflavin = Double(sample?.riboflavin ?? 0) * (Double(text) ?? 0)
        sample?.selenium = Double(sample?.selenium ?? 0) * (Double(text) ?? 0)
        sample?.thiamin = Double(sample?.thiamin ?? 0) * (Double(text) ?? 0)
        sample?.vitaminA = Double(sample?.vitaminA ?? 0) * (Double(text) ?? 0)
        sample?.vitaminC = Double(sample?.vitaminC ?? 0) * (Double(text) ?? 0)
        sample?.vitaminB6 = Double(sample?.vitaminB6 ?? 0) * (Double(text) ?? 0)
        sample?.vitaminB12 = Double(sample?.vitaminB12 ?? 0) * (Double(text) ?? 0)
        sample?.vitaminD = Double(sample?.vitaminD ?? 0) * (Double(text) ?? 0)
        sample?.vitaminE = Double(sample?.vitaminE ?? 0) * (Double(text) ?? 0)
        sample?.vitaminK = Double(sample?.vitaminK ?? 0) * (Double(text) ?? 0)
        sample?.zinc = Double(sample?.zinc ?? 0) * (Double(text) ?? 0)
        sample?.numberOfServings = (Double(text) ?? 0)
        sample?.servingSelection = servingTypeSelection.description
        sample?.mealPeriod = selection.description
        } else {
            let servingWeightGrams = sample?.servingWeightGrams
            sample?.calories = Double(sample?.calories ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.sugars = (sample?.sugars ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.totalFat = Double(sample?.totalFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.saturatedFat = (sample?.saturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.cholesterol = Double(sample?.cholesterol ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.sodium = Double(sample?.sodium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.totalCarbohydrate = Double(sample?.totalCarbohydrate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.dietaryFiber = Double(sample?.dietaryFiber ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.protein = Double(sample?.protein ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.potassium = Double(sample?.potassium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.calcium = Double(sample?.calcium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.iron = Double(sample?.iron ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.monounsaturatedFat = Double(sample?.monounsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.polyunsaturatedFat = Double(sample?.polyunsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.caffeine = Double(sample?.caffeine ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.copper = Double(sample?.copper ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.folate = Double(sample?.folate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.magnesium = Double(sample?.magnesium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.manganese = Double(sample?.manganese ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.niacin = Double(sample?.niacin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.phosphorus = Double(sample?.phosphorus ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.riboflavin = Double(sample?.riboflavin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.selenium = Double(sample?.selenium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.thiamin = Double(sample?.thiamin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminA = Double(sample?.vitaminA ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminC = Double(sample?.vitaminC ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminB6 = Double(sample?.vitaminB6 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminB12 = Double(sample?.vitaminB12 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminD = Double(sample?.vitaminD ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminE = Double(sample?.vitaminE ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminK = Double(sample?.vitaminK ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.zinc = Double(sample?.zinc ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.numberOfServings = (Double(text) ?? 0)
            sample?.servingSelection = servingTypeSelection.description
            sample?.mealPeriod = selection.description
        }
    }

}

