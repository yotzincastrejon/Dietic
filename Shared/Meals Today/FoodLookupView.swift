//
//  FoodLookupView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/9/22.
//

import SwiftUI
import CoreData

struct FoodLookupView: View {
    @Binding var isShowing: Bool
    @Binding var rootIsActive: Bool
    @ObservedObject var fastingManager: FastingManager
    let lookup: FoodLookup
    let mealPeriod: EatingTime
    @State private var food: SavedFood?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let food {
                FoodServingView(fastingManager: fastingManager, isShowing: $isShowing,
                                rootIsActive: $rootIsActive, selection: mealPeriod, food: food)
            } else if let errorMessage {
                VStack(spacing: 16) {
                    Text(errorMessage)
                    Button("Back") { isShowing = false }
                }
            } else {
                ProgressView("Looking up food…")
            }
        }
        .task(id: lookup) {
            food = nil
            errorMessage = nil
            do {
                let result = try await FoodDataCentral().product(for: lookup)
                try Task.checkCancellation()
                food = result
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }
}

struct FoodServingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var fastingManager: FastingManager
    @Binding var isShowing: Bool
    @Binding var rootIsActive: Bool
    @State var selection: EatingTime
    let food: SavedFood
    var historyItem: SearchedFoods?
    @State private var servingTypeSelection = ServingType.serving
    @State private var text = "1"
    @State private var saving = false
    @State private var logged = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var quantity: Double? {
        guard let value = try? Double(text, format: .number), value.isFinite, value > 0 else { return nil }
        return value
    }

    private var multiplier: Double? {
        guard let quantity else { return nil }
        if servingTypeSelection == .serving { return quantity }
        guard let grams = food.servingGrams, grams > 0 else { return nil }
        return quantity / grams
    }

    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                ForEach(EatingTime.allCases, id: \.self) { value in
                    Text(value.description)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()




            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    HStack {
                        Text(food.name)
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }

                    HStack {
                        Text("Serving size: \(food.servingQuantity.formatted()) \(food.servingUnit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if (food.servingGrams ?? 0) > 0 {
                    HStack {
                        Text("Serving weight in grams: \((food.servingGrams ?? 0).formatted())g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    }
                }

                if (food.servingGrams ?? 0) > 0 {
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
                        Text("\(displayNutrient(208)) kcal")
                            .font(.callout).bold()

                    }

                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(displayNutrient(205))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(displayNutrient(203))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)


                            Text("\(displayNutrient(204))g")
                                .font(.callout)

                        }
                        Spacer()
                    }
                }
                .padding(.top, 24)

                HStack(spacing: 15) {
                    Button(action: {
                        isShowing = false

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
                        guard !saving, !logged else { return }
                        saving = true
                        Task { await logMeal() }
                    }){
                        Text("Add")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color("B10"),Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                    .disabled(multiplier == nil || saving || logged)
                    }


                }
                .padding(.top, 33)

            }
            .padding(.horizontal)
            Spacer()


        }

        .disabled(saving)
        .alert("Meal log", isPresented: $showError) {
            Button("OK") { if logged { finish() } }
        } message: { Text(errorMessage) }
        .navigationTitle("Adding Food")
        .navigationBarTitleDisplayMode(.inline)
    }


    private func displayNutrient(_ id: Int) -> String {
        let total = (food.nutrients[id] ?? 0) * (multiplier ?? 0)
        return total.formatted(.number.precision(.fractionLength(0...1)))
    }

    @MainActor private func logMeal() async {
        defer { saving = false }
        guard let quantity, let multiplier else { return }
        do {
            let encoded = try JSONEncoder().encode(food)
            let sample = food.sample(multiplier: multiplier, quantity: quantity, unit: servingTypeSelection,
                                     meal: selection, date: fastingManager.mealTimestamp)
            try await fastingManager.saveMeal(sample)
            logged = true
            let item = historyItem ?? SearchedFoods(context: viewContext)
            item.timestamp = Date()
            item.name = food.name
            item.brandName = food.brand
            item.calories = food.nutrients[208] ?? 0
            item.jsonData = encoded
            try viewContext.save()
            finish()
        } catch {
            errorMessage = logged ? "The meal was logged, but food history could not be saved." : error.localizedDescription
            showError = true
        }
    }

    private func finish() {
        isShowing = false
        rootIsActive = false
    }
}
